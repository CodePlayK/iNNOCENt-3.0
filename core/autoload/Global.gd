##全局单例
extends Node
const parallax_move_data_source_path="res://core/common/parallax/parallax_move_data.tres"
const parallax_save_data_source_path="res://core/common/parallax/parallax_save_data.tres"
const marker = preload("res://core/common/component/marker/marker.tscn")

var playing_transition:bool=false
var room_transition:Dictionary={}
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
enum EVENT_VALUE_TYPR {
	STRING = TYPE_STRING,
	FLOAT = TYPE_FLOAT,
	INT = TYPE_INT,
	BOOL = TYPE_BOOL,
	ARRAY = TYPE_ARRAY,
	DICT = TYPE_DICTIONARY,
	RES = TYPE_OBJECT,
	V2 = TYPE_VECTOR2
}
