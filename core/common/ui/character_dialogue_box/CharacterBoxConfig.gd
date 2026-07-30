extends Resource
class_name CharacterBoxConfig
@export var character_names:Array[String]
@export var image:Texture2D
@export var unselect_modulate:Color = Color("727272")
@export var selected_modulate:Color = Color("ffffff")
@export var img_box_top_marg_hide:float = 13.7
@export var img_box_top_marg_show:float = 0
@export var wide_marg_show:float = 2.75
@export var wide_marg_hide:float = 1.82
@export var animation_time:float = .2
@export var drag_time:float = .5
@export var is_player:bool = false
@export var on_screen_left:bool = true
@export var health_config:HealthConfig
