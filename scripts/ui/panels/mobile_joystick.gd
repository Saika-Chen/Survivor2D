extends Control
class_name MobileJoystick
## MobileJoystick：用于触屏和鼠标的虚拟摇杆。

const DOTween := preload("res://scripts/utils/dotween.gd")

signal joystick_changed(input_vector: Vector2)

@onready var backplate: ColorRect = $Backplate
@onready var base: Control = $Base
@onready var ring: ColorRect = $Base/Ring
@onready var stick: Control = $Base/Stick

var joystick_active := false
var joystick_pointer_id := -1
var fullscreen_joystick_enabled := true
var fullscreen_joystick_center := Vector2.ZERO
var mobile_controls_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_configure_mobile_controls()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and _is_inside(event.position):
			joystick_active = true; joystick_pointer_id = event.index
			fullscreen_joystick_center = event.position; _update(event.position)
		elif event.index == joystick_pointer_id:
			joystick_active = false; joystick_pointer_id = -1; _reset()
	elif event is InputEventScreenDrag and joystick_active and event.index == joystick_pointer_id:
		_update(event.position)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _is_inside(event.position):
				joystick_active = true; joystick_pointer_id = -2
				fullscreen_joystick_center = event.position; _update(event.position)
			elif joystick_pointer_id == -2: joystick_active = false; joystick_pointer_id = -1; _reset()
	elif event is InputEventMouseMotion and joystick_active and joystick_pointer_id == -2:
		_update(event.position)

func _is_inside(pos: Vector2) -> bool:
	if fullscreen_joystick_enabled: return mobile_controls_enabled and get_viewport().get_visible_rect().has_point(pos)
	return pos.distance_to(base.global_position + base.size * 0.5) <= _radius() * 1.35

func _update(pos: Vector2) -> void:
	var center := fullscreen_joystick_center if fullscreen_joystick_enabled else base.global_position + base.size * 0.5
	var r := _radius(); var offset := (pos - center).limit_length(r)
	DOTween.kill(self, "joystick_stick_reset")
	if not fullscreen_joystick_enabled:
		stick.position = base.size * 0.5 + offset - stick.size * 0.5; _animate_state(true)
	joystick_changed.emit(offset / r)

func _reset() -> void:
	if fullscreen_joystick_enabled: joystick_changed.emit(Vector2.ZERO); return
	var cp := base.size * 0.5 - stick.size * 0.5
	DOTween.sequence(self, "joystick_stick_reset").tween_property(stick, "position", cp, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animate_state(false); joystick_changed.emit(Vector2.ZERO)

func _animate_state(active: bool) -> void:
	var tw := DOTween.sequence(self, "joystick_visual_state"); tw.set_parallel(true)
	tw.tween_property(backplate, "modulate", Color(1,1,1,1) if active else Color(1,1,1,0.92), 0.10)
	tw.tween_property(base, "modulate", Color(1,0.52,1,0.98) if active else Color(0.96,0.48,1,0.88), 0.10)
	tw.tween_property(ring, "modulate", Color(0.95,0.98,1,0.95) if active else Color(0.88,0.94,1,0.8), 0.10)
	tw.tween_property(stick, "modulate", Color(0.92,1,0.98,1) if active else Color(0.86,1,0.94,0.98), 0.10)

func _configure_mobile_controls() -> void:
	mobile_controls_enabled = OS.has_feature("mobile") or OS.has_feature("editor") or DisplayServer.is_touchscreen_available()
	visible = mobile_controls_enabled and not fullscreen_joystick_enabled; _layout()

func _layout() -> void:
	if not mobile_controls_enabled: return
	var vs := get_viewport().get_visible_rect().size
	var js := clampf(min(vs.x, vs.y) * 0.34, 218.0, 304.0)
	var lhc := Vector2(vs.x * 0.5, vs.y * 0.75)
	offset_left = lhc.x - js * 0.5; offset_top = lhc.y - js * 0.5
	offset_right = lhc.x + js * 0.5; offset_bottom = lhc.y + js * 0.5
	backplate.position = Vector2(-14, -14); backplate.size = Vector2.ONE * (js + 28)
	base.position = Vector2.ZERO; base.size = Vector2.ONE * js
	ring.position = Vector2.ONE * 10; ring.size = Vector2.ONE * (js - 20)
	stick.size = Vector2.ONE * (js * 0.40); _reset()

func _radius() -> float: return min(base.size.x, base.size.y) * 0.34
