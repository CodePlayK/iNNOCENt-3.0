extends Weight
@export var state_namager:NpcStateManager
@export var target_state:NpcsBaseState
func process(obj) -> void:
	if state_namager.npc_combat_state_history.back() == target_state:
		weight = confirmed_weight
	else :
		weight = impossible_weight
		
