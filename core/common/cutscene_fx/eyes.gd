extends TextureRect
@onready var aniplayer: AnimationPlayer = $aniplayer

func play(args:Array = []):
	show()
	if args[0] == "close":
		aniplayer.play("blink")
	else :
		aniplayer.play_backwards("blink")
		await aniplayer.animation_finished
		hide()
