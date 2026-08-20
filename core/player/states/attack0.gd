extends PlayerAttackState

func pre_enter() -> bool:
	if !super.pre_enter():
		return false
	if !PlayerState.attacking:
		return true
	else:
		return false
