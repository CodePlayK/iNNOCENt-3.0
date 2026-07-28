extends Component
##[必须挂载于Player根节点] Player专有灯光亮度控制
class_name LightScale
@onready var area: Area2D = $"."
var last_state:bool=false
var last_bright:float=0

func _process(delta: float) -> void:
	if area.has_overlapping_areas() and (!last_state or area.get_overlapping_areas()[0].bright!=last_bright):
		last_bright=area.get_overlapping_areas()[0].bright
		last_state=true
		EventBus._change_player_light(last_bright)
		Debug.dprintinfo(DebugCT.dp("「Player」灯光亮度变化："+str(last_bright),self))
	elif !area.has_overlapping_areas() and last_state:
		EventBus._change_player_light(0.0)	
		Debug.dprintinfo(DebugCT.dp("「Player」灯光亮度变化：0.0",self))
		last_state=false	
		
func _on_area_entered(area: Area2D) -> void:
	return
	EventBus._change_player_light(area.bright)

func _on_area_exited(area: Area2D) -> void:
	return
	EventBus._change_player_light(0.0)
