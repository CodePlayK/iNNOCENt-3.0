extends VisibleOnScreenNotifier2D
@onready var showing_timer: Timer = $ShowingTimer
@onready var hidden_timer: Timer = $HiddenTimer
@onready var create_character_box: Component = %CreateCharacterBox


func _on_screen_entered() -> void:
	showing_timer.start()
	hidden_timer.stop()

func _on_screen_exited() -> void:
	showing_timer.stop()
	hidden_timer.start()

func _on_showing_timer_timeout() -> void:
	create_character_box._on_timer_timeout()
	pass # Replace with function body.

func _on_hidden_timer_timeout() -> void:
	create_character_box.remove_character_box
	pass # Replace with function body.
