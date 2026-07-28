extends Node
var obj
@export var target_state:NpcsBaseState
@export var p_behithard:bool = false
func on_master_ready(master):
	obj = master.obj

func _ready() -> void:
	EventBus.npc_behithard.connect(on_npc_behithard)

func on_npc_behithard(obj1):
	if obj1 == obj:
		if p_behithard:Debug.dprinterr(DebugCT.dp("收到弹反信号",self))
		obj.state_manager.string2state(target_state.name,self)
	
