extends UIAttribute


@export var health_config:HealthConfig

func on_ready() -> void:
	state_name.text = "生命:"
	if health_config:
		EventBus.player_health_update.connect(on_update)
		on_update()

func on_update():
	if UiState.state_box and !UiState.state_box.showing:return
	ui_bar.max_value = health_config.max_health
	ui_bar.value = health_config.current_health
	current.text = str(health_config.current_health).pad_decimals(2)
	max.text = str(health_config.max_health)
	
