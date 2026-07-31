##全局单例
extends Node
const marker = preload("res://core/common/component/marker/marker.tscn")

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
