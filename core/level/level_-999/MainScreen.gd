@icon("res://addons/at-icons/node2d/wave.svg")
## 关卡的根节点.
##
## 每一关的基础场景,负责统一的环境与每关的变量初始化;
extends Levels
class_name MainScreen
@export var player_born_pos:Marker2D
@onready var player_pos_2_mouse:  PlayerPos2Mouse = $Components/PlayerPos2Mouse

func _ready():
	super._ready()
	player_pos_2_mouse.enable = true
	CutsceneState.change_player_state("mainscreen")
	Global.camera_controller.enable = false
	Global.camera_controller.set_drag_horizontal_offset(0)

func after_transition():
	pass

func  pause():
	super.pause()
	Global.camera_controller.enable = true
	
