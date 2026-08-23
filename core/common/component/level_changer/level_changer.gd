@icon("res://core/common/resource/icon/BTComposite.svg")
extends Area2D
@export_group("基础设置")
@export var enable_balloon:bool = false
@export var dialogue_config:DialogueConfig
@export_group("level设置")
@export var from_level:LevelState.LEVELS = 0
@export var target_level:LevelState.LEVELS = 0
@export_group("过场动画设置")
@export var trans_direct:LevelState.TRANS_DIRCTS
@export_group("玩家出生设置")
@export var player_facing_left:bool = false
@export var target_born_position:Vector2
@export var target_born_position_name:String
@onready var timer: Timer = $Timer
var door_enable:bool=false
var enable:bool=true
var interaction = self
func _ready() -> void:
	body_entered.connect(on_player_enter)
	timer.start()
func on_player_enter(body):
	if !door_enable or LevelState.doors_locked or LevelState.current_level!=from_level:
		return
	door_enable=false
	if enable_balloon:return
	change_level()
	
func change_level():
	PlayerState.player_exit_level_pos = PlayerState.player_player.global_position
	PlayerState.set_current_player_born_position(target_born_position,self)
	PlayerState.set_player_born_facing_left(player_facing_left,self)
	EventBus._change_level(target_level,self)
	timer.start()

func _on_timer_timeout() -> void:
	door_enable=true
	pass # Replace with function body.
