@icon("res://addons/at-icons/node3d/at.svg")

class_name CombatState
extends BaseState


## 战斗分组的公共基类。挂在 combat 节点上时应勾选 is_group。
func get_airborne_state() -> BaseState:
	if player.is_on_floor():
		return null
	return combatlift_state if player.velocity.y <= 0 else combatfall_state
