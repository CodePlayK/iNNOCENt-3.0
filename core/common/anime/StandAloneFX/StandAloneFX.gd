extends Node2D
class_name StandAloneFX
@export var hit_box: HitBox = $HitBox
@export var aniplayer: AnimationPlayer = $HitBox/aniplayer
@onready var master: Master = %Master
@export var fx_name:String = "bloodgif"
func playAFX(anime:Anime):
	position= Vector2.ZERO
	#aniplayer.play(fx_name)
	aniplayer.advance(0)
	var obj = hit_box.duplicate()
	LevelState.current_main_layer.add_child(obj)
	obj.on_master_ready(master)
	obj.global_position = self.global_position
	obj.set_enable(true)
	obj.show()
	obj.get_node("aniplayer").speed_scale = anime.aniplayer.speed_scale
	obj.get_node("aniplayer").play(fx_name)
	await obj.get_node("aniplayer").animation_finished
	obj.hide()
	obj.disable_shape()
	obj.queue_free()
