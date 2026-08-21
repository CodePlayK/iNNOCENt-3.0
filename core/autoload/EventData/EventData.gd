
extends Node
@export var event_data_dic:Dictionary = {}
@export var 祈祷次数:int = 0
enum EVENT_KEY {
	玩家交互次数DIC =0,
	祈祷次数 =1,
	玩家攻击次数=2, 
}

func get_key_name(event_key:EVENT_KEY):
	return EVENT_KEY.find_key(event_key)
	

func set_event(event_key:EVENT_KEY,value,source:Node):
	var t 
	if event_data_dic.has(get_key_name(event_key)):t=event_data_dic[get_key_name(event_key)]
	event_data_dic[get_key_name(event_key)] = value
	Debug.dprintinfo(DebugCT.dp("设置[普通]事件: [%s]:[%s] -> [%s]" %[get_key_name(event_key),t,value],source))

func set_event_by_int(event_key:EVENT_KEY,value:int,source:Node,adding:bool=true,):
	if !event_data_dic.has(get_key_name(event_key)):
		event_data_dic[get_key_name(event_key)] = 0
	var t = event_data_dic[get_key_name(event_key)]
	if adding:
		event_data_dic[get_key_name(event_key)] += value
	else :
		event_data_dic[get_key_name(event_key)] = value	
	Debug.dprintinfo(DebugCT.dp("设置[int][是否自增模式:%s]事件: [%s]:[%s] -> [%s]" %[adding,get_key_name(event_key),t,event_data_dic[get_key_name(event_key)]],source))

func set_event_by_dic(event_key:EVENT_KEY,key,value:int,adding:bool=true,source:Node =self):
	if !event_data_dic.has(get_key_name(event_key)):
		event_data_dic[get_key_name(event_key)] = {}
	if !event_data_dic[get_key_name(event_key)].has(key):
		event_data_dic[get_key_name(event_key)][key] = 0
	var t = event_data_dic[get_key_name(event_key)][key]
	if adding:
		event_data_dic[get_key_name(event_key)][key] += value
	else :
		event_data_dic[get_key_name(event_key)][key]= value		
	Debug.dprintinfo(DebugCT.dp("设置[dic]事件: [%s][%s]:[%s] -> [%s]" %[get_key_name(event_key),key,t,event_data_dic[get_key_name(event_key)][key]],source))
