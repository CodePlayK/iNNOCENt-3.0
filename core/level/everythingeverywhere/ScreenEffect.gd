extends CanvasLayer
@onready var eyes: TextureRect = $Eyes


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	show()
	EventBus.play_screen_effect.connect(on_play_screen_effect)
	pass # Replace with function body.


func on_play_screen_effect(e_name:String,args:Array) -> void:
	match e_name:
		"eyes":
			eyes.play(args)
