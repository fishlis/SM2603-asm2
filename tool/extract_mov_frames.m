#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>

// Returns the bounding box of the non transparent pixels of a CIImage.
static CGRect ContentRectOfCIImage(CIContext *ctx, CIImage *image) {
    CGRect extent = image.extent;
    if (CGRectIsEmpty(extent)) {
        return CGRectNull;
    }

    size_t w = (size_t)extent.size.width;
    size_t h = (size_t)extent.size.height;
    size_t stride = w * 4;
    unsigned char *buffer = calloc(stride * h, 1);

    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    // Render the alpha channel of the image into a premultiplied BGRA buffer.
    [ctx render:image
       toBitmap:buffer
       rowBytes:(ptrdiff_t)stride
         bounds:CGRectMake(0, 0, w, h)
         format:kCIFormatRGBA8
    colorSpace:cs];
    CGColorSpaceRelease(cs);

    // The rendered rows run bottom up, so flip the row index while scanning.
    size_t minX = w, maxX = 0, minY = h, maxY = 0;
    bool any = false;
    for (size_t y = 0; y < h; y++) {
        unsigned char *row = buffer + y * stride;
        for (size_t x = 0; x < w; x++) {
            if (row[x * 4 + 3] > 5) {
                any = true;
                if (x < minX) minX = x;
                if (x > maxX) maxX = x;
                if (y < minY) minY = y;
                if (y > maxY) maxY = y;
            }
        }
    }
    free(buffer);
    if (!any) {
        return CGRectNull;
    }
    // Convert from the bottom up buffer space into the top down image space.
    CGRect rect = CGRectMake(minX, h - 1 - maxY, maxX - minX + 1, maxY - minY + 1);
    return CGRectOffset(rect, extent.origin.x, extent.origin.y);
}

// Extracts every frame of a video, crops all frames to the union bounding box
// of the visible content, scales them down, and writes transparent PNGs.
//
// Godot 4 can only import .ogv video files, not QuickTime .MOV, so a
// transparent .MOV has to be turned into a PNG sequence by hand.
//
// Usage: extract_mov_frames <input.mov> <output_dir> [max_width] [flip]

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            fprintf(stderr, "usage: extract_mov_frames <input.mov> <output_dir> [max_width] [raw|flip]\n");
            return 1;
        }
        NSString *path = [NSString stringWithUTF8String:argv[1]];
        NSString *outDir = [NSString stringWithUTF8String:argv[2]];
        double maxWidth = argc > 3 ? atof(argv[3]) : 640.0;
        // "flip" mirrors the finished frames vertically, which is needed for
        // videos whose frames are stored upside down.
        const char *mode = argc > 4 ? argv[4] : "";
        BOOL doFlip = strcmp(mode, "flip") == 0;

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        AVAssetTrack *vt = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (!vt) { fprintf(stderr, "no video track\n"); return 1; }

        double fps = vt.nominalFrameRate > 0 ? vt.nominalFrameRate : 24.0;
        double dur = CMTimeGetSeconds(asset.duration);
        int n = (int)ceil(dur * fps);
        printf("track %dx%d @ %.2f fps, %.3f s -> %d frames\n",
               (int)vt.naturalSize.width, (int)vt.naturalSize.height, fps, dur, n);

        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        gen.requestedTimeToleranceAfter = kCMTimeZero;

        CIContext *ciContext = [CIContext contextWithOptions:nil];

        // ---- Pass 1: decode all frames, find the union content bbox ----
        NSMutableArray *images = [NSMutableArray array];
        CGRect unionExtent = CGRectNull;
        for (int i = 0; i < n; i++) {
            CMTime t = CMTimeMakeWithSeconds(i / fps, 600);
            NSError *err = nil;
            CGImageRef img = [gen copyCGImageAtTime:t actualTime:NULL error:&err];
            if (!img) { printf("  frame %d failed\n", i); continue; }

            CIImage *ci = [CIImage imageWithCGImage:img];
            CGImageRelease(img);

            // Core Image hands back the CGImage pixels in a bottom up order,
            // so they come out mirrored. One flip puts them upright again.
            CIImage *topDown = ci;

            CGRect content = ContentRectOfCIImage(ciContext, topDown);
            if (!CGRectIsNull(content)) {
                unionExtent = CGRectIsNull(unionExtent) ? content : CGRectUnion(unionExtent, content);
            }
            [images addObject:topDown];
        }
        if (CGRectIsNull(unionExtent)) { fprintf(stderr, "nothing visible\n"); return 1; }

        printf("union content bbox: %.0f,%.0f  %.0f x %.0f\n",
               unionExtent.origin.x, unionExtent.origin.y,
               unionExtent.size.width, unionExtent.size.height);

        // ---- Pass 2: crop and scale, write PNGs ----
        double scale = unionExtent.size.width > maxWidth ? maxWidth / unionExtent.size.width : 1.0;
        size_t outW = (size_t)round(unionExtent.size.width * scale);
        size_t outH = (size_t)round(unionExtent.size.height * scale);
        printf("output frame: %zu x %zu (scale %.4f)\n", outW, outH, scale);

        [[NSFileManager defaultManager] createDirectoryAtPath:outDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:NULL];

        int idx = 0;
        for (CIImage *img in images) {
            CIImage *cropped = [img imageByCroppingToRect:unionExtent];
            CIImage *scaled = [cropped imageByApplyingTransform:
                               CGAffineTransformMakeScale(scale, scale)];
            if (doFlip) {
                scaled = [[scaled imageByApplyingTransform:
                           CGAffineTransformMakeScale(1, -1)] imageByApplyingTransform:
                           CGAffineTransformMakeTranslation(0, scaled.extent.size.height)];
            }
            CGImageRef cg = [ciContext createCGImage:scaled fromRect:scaled.extent];
            if (!cg) { continue; }
            NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cg];
            NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
            NSString *name = [NSString stringWithFormat:@"%@/frame_%03d.png", outDir, idx];
            [png writeToFile:name atomically:YES];
            CGImageRelease(cg);
            idx++;
        }
        printf("wrote %d frames to %s\n", idx, outDir.UTF8String);
    }
    return 0;
}
