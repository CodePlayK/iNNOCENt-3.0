extends Component
##[必须挂载于obj根节点]将obj的速度映射到sprite的播放速度上
class_name SpeedMap2Animation
var obj
##映射到的最大速度
@export var map_max:float
##映射到的最低速度
@export var map_min:float
##是否事实计算速度最大最小值
@export var get_speed_max_min:bool
@export_group("debug")
@export var print_debug:bool = false

@onready var timer: Timer = $Timer

var current_k
var target_scale
var last_pos
var is_enable:bool
var last_enable:bool
var delta1:float
var speed_max:Dictionary
var speed_min:float

func on_master_ready(master):
	obj = master.obj
	last_pos=obj.global_position.x
	is_enable=false
	is_ready=true
	timer.start()

func set_enabel(k,flag:bool):
	current_k = k
	if !speed_max.has(current_k):speed_max[k] = 0
	#if flag:
		#base_scale=obj.state_manager.animation_speed
	is_enable = flag
	

func _physics_process(delta: float) -> void:
	delta1=delta
	pass
	
func get_speed():
	if !is_ready or obj.global_position.x==last_pos:
		last_pos=obj.global_position.x
		return
	if !is_enable:
		last_enable=false
		last_pos=obj.global_position.x
		return
	if !last_enable:
		speed_min=0
	var speed=abs(obj.global_position.x-last_pos)*delta1
	if get_speed_max_min and speed_max.has(current_k):
		if speed_max[current_k]!=max(speed_max[current_k],speed):
			speed_max[current_k]=max(speed_max[current_k],speed)
			#Debug.dprint("max_speed="+str(speed_max))
		if speed_min!=min(speed_min,speed):
			speed_min=min(speed_min,speed)
	var target_scale=remap(speed,speed_min,speed_max[current_k],map_min,map_max)
	obj.anime.set_speed_scale(target_scale)
	last_enable=true
	last_pos=obj.global_position.x
	if print_debug:Debug.dprintinfo(DebugCT.dp("#speed:[%s] #speed_min:[%s] #speed_max-d%s:[%s] #+target_scale:[%s]" %[str(speed).pad_decimals(4),str(speed_min).pad_decimals(4),str(current_k.name),str(speed_max[current_k]).pad_decimals(4),str(target_scale).pad_decimals(4)],self))
	pass

func _on_timer_timeout() -> void:
	get_speed()
