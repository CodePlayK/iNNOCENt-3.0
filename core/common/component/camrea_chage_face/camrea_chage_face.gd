extends Node
@onready var camera: Camera2D = $".."
@export var trans_time:float = 1
@export var base_drag_horizontal_offset:float = .5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EventBus.player_face_changed.connect(_on_player_face_changed)
	pass # Replace with function body.

func _on_player_face_changed():
	var tween = camera.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(camera,"drag_horizontal_offset",abs(base_drag_horizontal_offset)*-PlayerState.face_left_normalize,trans_time)
	await tween.finished
	tween.kill()
