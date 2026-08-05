extends BaseEvents
const DIALOGUE_INTERECT_TIME_BLOODKING_EC = preload("res://core/npc/blood_king/events/dialogue_interect_time_bloodking_ec.tres")
var npc:Npcs

func on_master_ready(m):
	npc = m.obj
	init()
	import()
	
func init() -> void:
	var res = DIALOGUE_INTERECT_TIME_BLOODKING_EC.duplicate()
	res.event_key ="DIALOGUE-%s" %npc.obj_name
	res.event_key_txt ="NPC对话次数"
	events.append(res)


