extends StackingState

func enter():
	#Debug.dprintwarn(DebugCT.dp("[staminaerror]耐力条不足",self))
	EventBus._play_SE("stamina_error",1,-10,self.name)
	return
