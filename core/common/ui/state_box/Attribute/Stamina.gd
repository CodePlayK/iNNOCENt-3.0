extends UIAttribute
@export var stamina_config:StaminaConfig

func on_ready() -> void:
	state_name.text = "能量:"
	if stamina_config:
		EventBus.player_stamina_update.connect(on_update)
		on_update()

func on_update():
	if UiState.state_box and !UiState.state_box.showing:return
	ui_bar.max_value = stamina_config.max_stamina
	ui_bar.value = stamina_config.current_stamina
	current.text = str(stamina_config.current_stamina).pad_decimals(0)
	max.text = str(stamina_config.max_stamina)
	
