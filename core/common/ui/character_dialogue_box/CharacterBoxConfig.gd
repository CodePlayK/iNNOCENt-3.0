extends Resource
class_name CharacterBoxConfig
@export_group("基础配置")
@export var obj_id:String:
	set(oi):
		obj_id = oi
		character_box_id=str(level_id)+obj_id
@export var level_id:LevelState.LEVELS:
	set(oi):
		level_id = oi
		character_box_id=str(oi)+obj_id
var character_box_id:String
	
@export var character_names:Array[String]
@export var is_player:bool = false
@export var health_config:HealthConfig

@export_group("显示配置")
var showing:bool=true
@export var image:Texture2D
## 头像图片所在文件夹（默认 res:// 路径，末尾可带或不带 /）
@export var avatar_folder: String = "res://core/player/resource/headers/"
@export var current_default_expression:String = "idle"
@export var unselect_modulate:Color = Color("727272")
@export var selected_modulate:Color = Color("ffffff")
@export var img_box_top_marg_hide:float = 13.7
@export var img_box_top_marg_show:float = 0
@export var wide_marg_show:float = 2.75
@export var wide_marg_hide:float = 1.82
@export var animation_time:float = .2
@export var drag_time:float = .5
@export var on_screen_left:bool = true

func _init() -> void:
	set_local_to_scene(true)
