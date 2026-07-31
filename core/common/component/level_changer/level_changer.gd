@icon("res://core/common/resource/icon/BTComposite.svg")
extends Area2D
@export var target_level:LevelState.LEVELS = 0
@export_category("目标level出生位置")
@export var target_born_position:Vector2
@export var target_born_position_name:String

func _ready() -> void:
	body_entered.connect(on_player_enter)

func on_player_enter(body):
	PlayerState.current_player_born_position=target_born_position
	EventBus._change_level(target_level)
