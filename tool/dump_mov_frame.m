#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AppKit/AppKit.h>
#import <CoreGraphics/CoreGraphics.h>

// Dumps one frame of a video at its full resolution with a red border, and
// reports the bounding box of the visible content.
//
// Usage: dump_mov_frame <input.mov> <out.png> [frame_index]

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            fprintf(stderr, "usage: dump_mov_frame <input.mov> <out.png> [frame_index]\n");
            return 1;
        }
        NSString *path = [NSString stringWithUTF8String:argv[1]];
        NSString *outPath = [NSString stringWithUTF8String:argv[2]];
        int frameIndex = argc > 3 ? atoi(argv[3]) : 0;

        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:path] options:nil];
        AVAssetTrack *vt = [asset tracksWithMediaType:AVMediaTypeVideo].firstObject;
        if (!vt) { fprintf(stderr, "no video track\n"); return 1; }

        double fps = vt.nominalFrameRate > 0 ? vt.nominalFrameRate : 24.0;
        CMTime t = CMTimeMakeWithSeconds(frameIndex / fps, 600);

        AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        gen.appliesPreferredTrackTransform = YES;
        gen.requestedTimeToleranceBefore = kCMTimeZero;
        gen.requestedTimeToleranceAfter = kCMTimeZero;

        NSError *err = nil;
        CGImageRef img = [gen copyCGImageAtTime:t actualTime:NULL error:&err];
        if (!img) { fprintf(stderr, "frame failed: %s\n", err.localizedDescription.UTF8String); return 1; }

        size_t w = CGImageGetWidth(img), h = CGImageGetHeight(img);
        printf("full frame: %lu x %lu\n", (unsigned long)w, (unsigned long)h);

        size_t stride = w * 4;
        unsigned char *buf = calloc(stride * h, 1);
        CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
        CGContextRef ctx = CGBitmapContextCreate(buf, w, h, 8, stride, cs,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
        CGColorSpaceRelease(cs);
        CGContextDrawImage(ctx, CGRectMake(0, 0, w, h), img);
        CGContextRelease(ctx);

        // The context rows run bottom up, so row 0 of the buffer is the bottom.
        size_t minX = w, maxX = 0, minY = h, maxY = 0;
        for (size_t y = 0; y < h; y++) {
            unsigned char *row = buf + y * stride;
            for (size_t x = 0; x < w; x++) {
                if (row[x * 4 + 3] > 5) {
                    if (x < minX) minX = x;
                    if (x > maxX) maxX = x;
                    if (y < minY) minY = y;
                    if (y > maxY) maxY = y;
                }
            }
        }
        printf("content bbox (bottom up): x %zu..%zu  y %zu..%zu\n", minX, maxX, minY, maxY);
        printf("content bbox (top down):  x %zu..%zu  y %zu..%zu\n",
               minX, maxX, h - 1 - maxY, h - 1 - minY);
        printf("touching left edge: %s   right edge: %s   top: %s   bottom: %s\n",
               minX == 0 ? "YES" : "no",
               maxX == w - 1 ? "YES" : "no",
               maxY == h - 1 ? "YES" : "no",
               minY == 0 ? "YES" : "no");

        CGContextRef octx = CGBitmapContextCreate(NULL, w, h, 8, 0, cs,
                                                  kCGImageAlphaPremultipliedLast);
        CGContextDrawImage(octx, CGRectMake(0, 0, w, h), img);
        CGContextSetRGBStrokeColor(octx, 1, 0, 0, 1);
        CGContextSetLineWidth(octx, 10);
        CGContextStrokeRect(octx, CGRectMake(5, 5, w - 10, h - 10));
        CGImageRef outImg = CGBitmapContextCreateImage(octx);
        NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:outImg];
        NSData *png = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
        [png writeToFile:outPath atomically:YES];
        printf("wrote %s\n", outPath.UTF8String);
        free(buf);
    }
    return 0;
}
