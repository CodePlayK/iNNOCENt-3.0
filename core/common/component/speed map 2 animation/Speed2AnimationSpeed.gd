extends Component
##[必须挂载于obj根节点]将obj的速度映射到sprite的播放速度上
class_name SpeedMap2Animation
	
## 将角色速度映射到动画播放速度
## 速度 → 播放速率 的比例（检查器里可拖）
@export_range(0.0, 5.0, 0.01, "or_greater") var speed_scale: float = 1.0
## 速度为 0 时的播放速度
@export var idle_speed: float = 1.0
## 播放速度上限，防止冲刺时过快
@export var max_anim_speed: float = 3.0
## 用速度模长；若为 false 则只用水平 |velocity.x|
@export var use_full_velocity: bool = false
## 参考速度：达到该速度时，播放速度 ≈ idle_speed + speed_scale
@export var reference_speed: float = 200.0
var obj
var is_enable:bool = false:
	set(f):
		is_enable = f
		if !f:obj.anime.set_speed_scale(1)
			
func on_master_ready(master):
	obj = master.obj
	
func _process(_dt: float) -> void:
	if obj == null or !is_enable:
		return
	var v: float
	if use_full_velocity:
		v = obj.velocity.length()
	else:
		v = absf(obj.velocity.x)

	var t := 0.0
	if reference_speed > 0.0:
		t = v / reference_speed

	var rate := idle_speed + t * speed_scale
	obj.anime.set_speed_scale(clampf(rate, 0.0, max_anim_speed))		
