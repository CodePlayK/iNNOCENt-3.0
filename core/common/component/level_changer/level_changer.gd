@icon("res://core/common/resource/icon/BTComposite.svg")
extends Area2D
@export var from_level:LevelState.LEVELS = 0
@export var target_level:LevelState.LEVELS = 0
@export_category("目标level出生位置")
@export var trans_direct:LevelState.TRANS_DIRCTS
@export var target_born_position:Vector2
@export var target_born_position_name:String
@onready var timer: Timer = $Timer

var enable:bool=false
func _ready() -> void:
	body_entered.connect(on_player_enter)
	timer.start()
func on_player_enter(body):
	if !enable or LevelState.doors_locked or LevelState.current_level!=from_level:
		return
	enable=false
	PlayerState.current_player_born_position=target_born_position
	EventBus._change_level(target_level)
	timer.start()

func _on_timer_timeout() -> void:
	enable=true
	pass # Replace with function body.
