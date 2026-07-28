extends Node2D
@onready var dense_safe: AnimatedSprite2D = $denseSafe

func emit_fx():
	var d_safe:AnimatedSprite2D = dense_safe.duplicate()
	d_safe.frame = 0
	LevelState.current_main_layer.add_child(d_safe)
	d_safe.global_position = dense_safe.global_position
	d_safe.show()
	d_safe.play("denseSafe")
	await d_safe.animation_finished
	d_safe.hide()
	d_safe.queue_free()
