extends Node2D
@onready var aniplayer: AnimationPlayer = $aniplayer

var obj

func on_master_ready(master):
	obj = master.obj
	hide()

func play_fx(fx_name:String):
	if !aniplayer.has_animation(fx_name):return
	show()
	#base.scale.x = -obj.obj_2_player_side.get_on_player_left_normalized()*abs(base.scale.x)*obj.face_left_normalized
	#base.frame = 0
	aniplayer.get_animation(fx_name).loop_mode=Animation.LOOP_NONE
	aniplayer.play(fx_name)


func _on_aniplayer_animation_finished(anim_name: StringName) -> void:
	hide()
