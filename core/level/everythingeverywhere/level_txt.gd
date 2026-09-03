##关卡名显示
extends VBoxContainer
@onready var level_transation: LevelTransation = %LevelTransation
@onready var txt_box: VBoxContainer = $HBoxContainer/TxtBox
@onready var txt: Label = $HBoxContainer/TxtBox/Txt

func _ready() -> void:
	level_transation.level_transition_finished.connect(on_level_transition_finished)
	EventBus.level_changed.connect(on_level_changed)
	show_txt()
func on_level_changed(fl, tl):
	txt.text = LevelState.current_level_node.level_txt
	show_txt()
	
func on_level_transition_finished():
	hide_txt()

func hide_txt():
	txt_box.offset_transform_position_ratio.x = 1.5

func show_txt():
	var tw = create_tween()
	tw.set_ease(Tween.EASE_OUT)
	tw.set_trans(Tween.TRANS_SPRING)
	tw.tween_property(txt_box,"offset_transform_position_ratio",Vector2.ZERO,1)
	
