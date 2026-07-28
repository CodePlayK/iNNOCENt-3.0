extends Node2D
@export var play_speed:float = 1.0
@export var fade_time:float = 10.0
@onready var aniplayer: AnimationPlayer = $Blood/aniplayer
@onready var timer: Timer = $Timer

func play():
	rotation_degrees = randf_range(-360,360)
	show()
	aniplayer.play("BOT2TOP",-1,play_speed)
	timer.start(fade_time)

func _on_timer_timeout() -> void:
	aniplayer.play("FADE_OUT")
	await aniplayer.animation_finished
	queue_free()
