@tool
extends Node
@export var event_data_dic:Dictionary = {
	
}
enum EVENT_TYPR {
	PLAYER = 0,
	NPC = 1,
	OBJ = 2,
	VAR = 3,
}


func add_event(ec:EventConfig):
	if !ec or null==ec.event_key:return
	#if event_data_dic.has(ec.event_key):
		#Debug.dprinterr(DebugCT.dp("[%s]事件key不唯一!,当前value为:\n%s" %[ec.event_key,event_data_dic[ec.event_key]],self))
	#event_data_dic[ec.event_key] = ec

func get_event(k):
	var v = event_data_dic[k]
	return event_data_dic[k]

enum EVENTS_CONFIG{
	PLAYER_ATTACK_TIME_EVENT = 0,
	BLOODKING_ATTACK_TIME = 1,
	PLAYER_DENSE_SUC_TIME_EVENT = 2,
	FLASHLIGHT_COUNT_EVENT = 3,
}

var events_dic:Dictionary = {
	EVENTS_CONFIG.PLAYER_ATTACK_TIME_EVENT : [ResourceLoader.load("res://core/events/player_attack_time_event.tres")],
	EVENTS_CONFIG.BLOODKING_ATTACK_TIME : [ ResourceLoader.load("res://core/events/BloodkingAttackTime.tres")],
	EVENTS_CONFIG.PLAYER_DENSE_SUC_TIME_EVENT : [ResourceLoader.load("res://core/events/PlayerDenseSucTimeEvent.tres")],
	EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT : [ResourceLoader.load("res://core/events/FlashlightCountEvent.tres")]
}
func get_event_config(ec:EVENTS_CONFIG):
	return events_dic[ec][0]
