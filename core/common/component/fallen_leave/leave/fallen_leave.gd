extends Node2D
class_name FallenLeave
@onready var base = $base
@onready var aniplayer = $Aniplayer
@export var base_scale:float=1.0
var color:Color
func _ready():
	base.set_speed_scale(randf_range(.5,1.5))
	base.rotation=randf_range(-360,360)
	pass 
func _on_aniplayer_animation_finished(anim_name):
	aniplayer.play("leaves",-1,randf_range(.2,1))
	pass 
func _play(leave_scale:float=1.0,color1:Color="003c47"):
	await self.ready
	color=Color(color1,0)
	base.self_modulate=color1
	base.scale=Vector2(base_scale*leave_scale,base_scale*leave_scale)
	aniplayer.play("leaves",-1,randf_range(.2,1))

func _on_ray_cast_2d_body_entered(body):
	var tween=base.create_tween()
	tween.tween_property(base,"self_modulate",color,.2)
	tween.chain().tween_callback(self.queue_free)
	 
