extends Node2D
@onready var aniplayer: AnimationPlayer = $aniplayer

var obj

func on_master_ready(master):
	obj = master.obj
	hide()

func play_fx(fx_name:String):
	show()
	#base.scale.x = -obj.obj_2_player_side.get_on_player_left_normalized()*abs(base.scale.x)*obj.face_left_normalozed
	#base.frame = 0
	aniplayer.play(fx_name)


func _on_aniplayer_animation_finished(anim_name: StringName) -> void:
	hide()
