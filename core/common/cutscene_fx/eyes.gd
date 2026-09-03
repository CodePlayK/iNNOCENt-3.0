extends TextureRect
@onready var aniplayer: AnimationPlayer =$"../aniplayer"

func reset():
	aniplayer.advance(0)

func play(args:Array = []):
	if args[0] == "close":
		aniplayer.play("blink")
		aniplayer.advance(0)
	else :
		aniplayer.play_backwards("blink")
		aniplayer.advance(0)
	show()
	await aniplayer.animation_finished
	hide()
