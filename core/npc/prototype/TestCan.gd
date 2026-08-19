extends CanvasLayer
var current_level:LevelState.LEVELS
@onready var test_label: Label = %TestLabel

func _init() -> void:
	EventBus.test_layer_visiable.connect(test_layer_visiable)


func on_master_ready(master:Master):
	test_label.text = master.obj.name
	current_level=LevelState.current_level

func test_layer_visiable(flag):
	if LevelState.current_level==current_level:
		visible=flag
