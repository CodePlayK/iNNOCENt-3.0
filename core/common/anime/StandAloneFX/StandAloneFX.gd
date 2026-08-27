extends Node2D
class_name StandAloneFX
@export var hit_box: HitBox = $HitBox
@export var aniplayer: AnimationPlayer = $HitBox/aniplayer
@onready var master: Master = %Master
@export var fx_name:String = "bloodgif"
func playAFX(anime:Anime):
	position= Vector2.ZERO
	aniplayer.stop()
	aniplayer.advance(0)
	var obj = hit_box.duplicate()
	var col_shape = obj.get_node_or_null("CollisionShape2D") # 请根据你实际的形状节点名修改
	if col_shape and col_shape.shape:
		col_shape.shape = col_shape.shape.duplicate()
	LevelState.current_main_layer.add_child(obj)
	obj.global_position = self.global_position
	obj.on_master_ready(master)
	obj.set_enable(true)
	obj.show()
	var obj_ani = obj.get_node("aniplayer") as AnimationPlayer
	obj_ani.speed_scale = anime.aniplayer.speed_scale
	obj_ani.play(fx_name)
	obj_ani.advance(0)
	await obj.get_node("aniplayer").animation_finished
	obj.hide()
	obj.disable_shape()
	obj.queue_free()
