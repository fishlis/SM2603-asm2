extends Control

const ITEM_DATA = {
	"C": {"category": "coffee", "name": "Coffee", "icon": preload("res://assets/coffee_icons/espresso_cup.png")},
	"W": {"category": "water",  "name": "Water", "icon": preload("res://assets/coffee_icons/americano_cup.png")},
	"M": {"category": "water",  "name": "Milk",   "icon": preload("res://assets/coffee_icons/caramel_latte_cup.png")},
	"V": {"category": "syrup",  "name": "Vanilla Syrup",  "icon": preload("res://assets/coffee_icons/vanilla_latte_cup.png")},
	"K": {"category": "syrup",  "name": "Caramel Syrup",  "icon": preload("res://assets/coffee_icons/caramel_latte_cup.png")},
	"H": {"category": "syrup",  "name": "Hazelnut Syrup", "icon": preload("res://assets/coffee_icons/hazelnut_latte_cup.png")},
	"X": {"category": "syrup",  "name": "Chocolate",      "icon": preload("res://assets/coffee_icons/mocha_cup.png")},
	"I": {"category": "ice",    "name": "Ice",    "icon": preload("res://assets/coffee_icons/ice.png")},
}

@export var component_scene: PackedScene
@export var threshold: float = 48.0
@export var samples: int = 32
@export var record_mode: bool = false
@export var record_code: String = "C"

var drawing = false
var busy = false
var points: PackedVector2Array = PackedVector2Array()
var templates: Dictionary = {} 

@onready var line: Line2D = $Line2D
@onready var spawn_point: Control = $ComponentSpawnPoint
@onready var submit_btn: Button = $SubmitButton

func _ready() -> void:
	load_templates()
	submit_btn.pressed.connect(_on_submit_pressed)

func _gui_input(event: InputEvent) -> void:
	if busy:
		return
#only allow to draw once at the same time
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drawing = true
			points.clear()
			line.clear_points()
			add_pt(event.position)
		else:
			drawing = false
#only checking the similarities when submit btn is pressed
	elif event is InputEventMouseMotion and drawing:
		add_pt(event.position)

func add_pt(pos: Vector2) -> void:
	var p: Vector2 = line.to_local(get_global_mouse_position())
	if points.size() > 0 and points[-1].distance_to(p) < 3.0:
		return
	points.append(p)
	line.add_point(p)

func _on_submit_pressed() -> void:
	if busy or points.size() < 5:
		clear_draw()
		return

	var norm: PackedVector2Array = normalize(resample(points, samples))

 #record the sample of the alphabet
	if record_mode:
		var code: String = record_code.strip_edges().to_upper()
		if code in ITEM_DATA:
			if not templates.has(code):
				templates[code] = []
			templates[code].append(norm)
			save_templates()
			print("Saved template for ", code, " (", templates[code].size(), ")")
		clear_draw()
		return

#find the matching record sample and new data
	var matched: String = find_match(norm)
	if matched != "":
		spawn_component(matched)
		clear_draw()
	else:
		bounce_reset()

func find_match(input_pts: PackedVector2Array) -> String:
	var best_code := ""
	var best_dist: float = INF

	for code in templates.keys():
		for tpl in templates[code]:
			var d: float = avg_distance(input_pts, tpl)
			if d < best_dist:
				best_dist = d
				best_code = code

	if best_dist <= threshold:
		return best_code
	return ""

#spawning the corresponding letter code once it is recognised
func spawn_component(code: String) -> void:
	if component_scene == null:
		print("Got: ", code, " - ", ITEM_DATA.get(code, ""))
		return

	var item = component_scene.instantiate()
	spawn_point.add_child(item)
	item.position = Vector2.ZERO
	item.scale = Vector2(0.5, 0.5)

	var tw = create_tween()
	tw.tween_property(item, "scale", Vector2.ONE, 0.15)

#referencing the componentName.gd function
	if item.has_method("setup_component"):
		var info: Dictionary = ITEM_DATA.get(code, {})
		var ingredient_name: String = str(info.get("name", code))
		item.setup_component(code, ingredient_name)

# Wrong detections of drawing will be erased and the canvas bounce for feedback
func bounce_reset() -> void:
	busy = true
	var start_x: float = position.x
	var tw = create_tween()
	tw.tween_property(self, "position:x", start_x + 10.0, 0.05)
	tw.tween_property(self, "position:x", start_x - 10.0, 0.05)
	tw.tween_property(self, "position:x", start_x, 0.05)
	await tw.finished
	clear_draw()
	busy = false

func clear_draw() -> void:
	points.clear()
	line.clear_points()

func resample(pts: PackedVector2Array, n: int) -> PackedVector2Array:
	var total: float = 0.0
	for i in range(1, pts.size()):
		total += pts[i - 1].distance_to(pts[i])
	if total <= 0.001:
		return pts

	var step: float = total / float(n - 1)
	var out = PackedVector2Array([pts[0]])
	var acc: float = 0.0
	var prev: Vector2 = pts[0]
	var i = 1

	while i < pts.size():
		var curr: Vector2 = pts[i]
		var seg: float = prev.distance_to(curr)
		if acc + seg >= step:
			var t: float = (step - acc) / seg
			var new_p: Vector2 = prev.lerp(curr, t)
			out.append(new_p)
			prev = new_p
			acc = 0.0
		else:
			acc += seg
			prev = curr
			i += 1

	while out.size() < n:
		out.append(pts[-1])
	return out

func normalize(pts: PackedVector2Array) -> PackedVector2Array:
	var min_p: Vector2 = pts[0]
	var max_p: Vector2 = pts[0]
	for p in pts:
		min_p.x = minf(min_p.x, p.x)
		min_p.y = minf(min_p.y, p.y)
		max_p.x = maxf(max_p.x, p.x)
		max_p.y = maxf(max_p.y, p.y)

	var span: Vector2 = max_p - min_p
	var s: float = minf(100.0 / maxf(span.x, 1.0), 100.0 / maxf(span.y, 1.0))
	var center: Vector2 = (min_p + max_p) * 0.5

	var out = PackedVector2Array()
	for p in pts:
		out.append((p - center) * s)
	return out

func avg_distance(a: PackedVector2Array, b: PackedVector2Array) -> float:
	var sum: float = 0.0
	var n: int = mini(a.size(), b.size())
	for i in range(n):
		sum += a[i].distance_to(b[i])
	return sum / float(maxi(n, 1))

#save the template sample into the json file, can check it with Project -> Open User Data Folder
func save_templates() -> void:
	var data = {}
	for code in templates.keys():
		var arr = []
		for tpl in templates[code]:
			var pts_list = []
			for p in tpl:
				pts_list.append([p.x, p.y])
			arr.append(pts_list)
		data[code] = arr
	var f = FileAccess.open("user://templates.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))

func load_templates() -> void:
	if not FileAccess.file_exists("user://templates.json"):
		return
	var f = FileAccess.open("user://templates.json", FileAccess.READ)
	if not f:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	templates.clear()
	for code in parsed.keys():
		var arr = []
		for pts_list in parsed[code]:
			var pv = PackedVector2Array()
			for pair in pts_list:
				pv.append(Vector2(float(pair[0]), float(pair[1])))
			arr.append(pv)
		templates[code] = arr
