extends Node2D
@onready var test_label: Label = %TestLabel
@onready var running_time: Label = %RunningTime
@onready var timer: Timer = $RunningTime/Timer

func _on_timer_timeout() -> void:
	running_time.text=str(int(running_time.text)+1)


func _on_aniplayer_animation_started(anim_name: StringName) -> void:
	if anim_name== "idle":
		pass
	pass # Replace with function body.


func _on_aniplayer_animation_finished(anim_name: StringName) -> void:
	if anim_name== "attack2":
		pass
	pass # Replace with function body.
