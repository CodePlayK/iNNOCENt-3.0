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
var everythingeverywhere42:Everythingeverywhere42		
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
func generate_uuid_short_id() -> String:
	# 获取微秒数（1秒 = 1,000,000微秒）
	var ticks = Time.get_ticks_usec()
	# 转换为 16 进制字符串并截取后 8 位
	var hex_str = "%x" % ticks
	return hex_str.right(8)
