extends Component
##[必须挂载于Player根节点] Player专有灯光亮度控制
@export_range(1.0,50) var max_bright = 7.0
@export_range(0.0,5) var min_bright = 0.0
@export_range(0,5.0) var trans_time = .2 
@onready var light: Area2D = $"."
var obj
var last_state:bool=false
var last_bright:float=1.0
@export_range(1.0,5.0) var vfx_bright:float:
	set(f):
		vfx_bright = f
		if !obj:return
		obj.vfx.material.set_shader_parameter("mix_modulate_strength",vfx_bright)
var bright:float:
	set(f):
		bright = f
		if !obj:return
		obj.base.material.set_shader_parameter("mix_modulate_strength",f*max_bright)
@export var vfx_color:Color:
	set(c):
		vfx_color = c
		if !obj:return
		obj.vfx.material.set_shader_parameter("color",vfx_color)		
@export var vfx_colored:bool:
	set(f):
		vfx_colored = f
		if !obj:return
		obj.vfx.material.set_shader_parameter("colored",f)		
func on_master_ready(master) -> void:
	obj= master.obj
	bright = min_bright

func _process(delta: float) -> void:
	if light.has_overlapping_areas() and (!last_state or light.get_overlapping_areas()[0].bright!=last_bright):
		last_bright=light.get_overlapping_areas()[0].bright
		last_state=true
		change_bright(last_bright)
	elif !light.has_overlapping_areas() and last_state:
		change_bright(min_bright)	
		last_state=false	

func change_bright(bright1:float):
	var tween = obj.base.create_tween()
	tween.tween_property(self,"bright",bright1,trans_time)
	await tween.finished
	tween.kill()

func change_vfx_bright(bright,trans_time_vfx):
	var tween = obj.vfx.create_tween()
	tween.tween_property(self,"vfx_bright",bright,trans_time_vfx)
	await tween.finished
	tween.kill()
