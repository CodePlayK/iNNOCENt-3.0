extends Node2D
@onready var hit_box: HitBox = $HitBox
@onready var aniplayer: AnimationPlayer = $HitBox/aniplayer
@onready var master: Master = %Master
func playAFX():
	aniplayer.play("bloodgif")
	var obj = hit_box.duplicate()
	LevelState.current_main_layer.add_child(obj)
	obj.on_master_ready(master)
	obj.global_position = self.global_position
	obj.set_enable(true)
	obj.show()
	obj.get_node("aniplayer").play("bloodgif")
	await obj.get_node("aniplayer").animation_finished
	obj.hide()
	obj.disable_shape()
	obj.queue_free()
