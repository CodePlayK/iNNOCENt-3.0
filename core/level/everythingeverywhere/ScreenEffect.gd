extends CanvasLayer
@onready var eyes: TextureRect = $Eyes
@onready var front_color: ColorRect = $FrontColor


func _ready() -> void:
	show()
	front_color.hide()
	eyes.hide()
	EventBus.play_screen_effect.connect(on_play_screen_effect)


func on_play_screen_effect(e_name:String,args:Array) -> void:
	match e_name:
		"黑屏":
			front_color.color = Color.BLACK
			front_color.show()
		"眼睛":
			eyes.play(args)
			
