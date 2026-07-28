extends Node2D
@onready var dash_partical: GPUParticles2D = $DashPartical
@onready var dash_trail_partical: GPUParticles2D = $DashTrailPartical
const DASH_FRAME_O = preload("res://core/player/animation/dash-frame-o.png")
const DASH_FRAME_FLIPO = preload("res://core/player/animation/dash-frame-flipo.png")
func playAFX():
	if PlayerState.face_left:
		scale.x=abs(scale.x)
		dash_trail_partical.texture = DASH_FRAME_FLIPO
	else :
		scale.x=-abs(scale.x)
		dash_trail_partical.texture = DASH_FRAME_O
	dash_partical.restart()
	#dash_partical.emitting = true
	dash_trail_partical.restart()
	#dash_trail_partical.emitting = true
