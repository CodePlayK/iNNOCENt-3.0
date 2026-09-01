extends Node
class_name CameraController
@onready var camera: Camera2D = $".."
@export var trans_time:float = 1
@export var base_drag_horizontal_offset:float = .5
@export var enable:bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.player_face_changed.connect(_on_player_face_changed)
	Global.camera_controller = self

func set_drag_horizontal_offset(v:float):
	camera.drag_horizontal_offset = v

func _on_player_face_changed():
	if !enable:
		return
	var tween = camera.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(camera,"drag_horizontal_offset",abs(base_drag_horizontal_offset)*-PlayerState.face_left_normalize,trans_time)
	await tween.finished
	tween.kill()
