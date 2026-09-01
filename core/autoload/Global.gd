##全局单例
extends Node
const marker = preload("res://core/common/component/marker/marker.tscn")
var player_camera:Camera2DPlus
var back_ground_color: TextureRect
var level_lights_dic:Dictionary
func add_2_level_lights_dic(level_id:LevelState.LEVELS,bl:BaseLight):
	if !level_lights_dic.has(level_id):
		level_lights_dic[level_id] = [bl]
	else :
		level_lights_dic[level_id].append(bl)
		
var test_mark:Node2D
var camera_controller:CameraController
enum transition_type {
	RIGHT_ENTER,
	RIGHT_LEFT,
	LEFT_ENTER,
	LEFT_LEFT,
	MID_ENTER,
	MID_LEFT,
	FADE_OUT,
	FADE_IN
}
enum EVENT_VALUE_TYPE {
	STRING = TYPE_STRING,
	FLOAT = TYPE_FLOAT,
	INT = TYPE_INT,
	BOOL = TYPE_BOOL,
	ARRAY = TYPE_ARRAY,
	DICT = TYPE_DICTIONARY,
	RES = TYPE_OBJECT,
	V2 = TYPE_VECTOR2
}
