extends AnimationPlayer

func _ready() -> void:
	EventBus.play_cutscene_aniplayer.connect(on_play_cutscene_aniplayer)

func on_play_cutscene_aniplayer(animation_name:String):
	play(animation_name)
