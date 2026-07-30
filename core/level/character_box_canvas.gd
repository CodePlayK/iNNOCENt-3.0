extends CanvasLayer

func _init() -> void:
	EventBus.create_character_box.connect(on_player_health_healed)

func on_player_health_healed():
	return
