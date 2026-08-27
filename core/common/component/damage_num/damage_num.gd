extends Component

@onready var damage_num: Label = $damageNum
var damage_num_marker: Marker2D # 明确类型提升代码健壮性
@export var num_size_px:int = 13
@export var time_scale:float = 1
@export var x_scale:float = 1
@export var y_scale:float = 1
@export var num_color:Color = "ff8080"

func _ready() -> void:
	for node in get_children():
		if node is Marker2D:
			damage_num_marker = node
	damage_num.hide()

func emit_num(damage:float):
	Debug.dprintinfo(DebugCT.dp("[伤害数字emit]%s" %damage,self))
	# 安全检查：防止标记点不存在导致报错
	if not is_instance_valid(damage_num_marker): return
	
	var current_marker_pos = damage_num_marker.global_position
	
	# 1. 深度克隆 Label 节点
	var d_num = damage_num.duplicate() as Label
	
	# 【核心修复 1】：使用重度克隆 (true) 彻底切断 LabelSettings 的资源共享，防止多段伤害互相污染透明度
	if damage_num.label_settings:
		d_num.label_settings = damage_num.label_settings.duplicate(true)
	
	# 2. 基础属性初始化
	d_num.text = str(int(damage))
	d_num.label_settings.font_size = num_size_px
	d_num.label_settings.font_color = num_color
	
	# 【核心修复 2】：重置克隆出来的节点透明度为全满，防止继承了原节点可能存在的错误透明度
	d_num.modulate.a = 1.0 
	
	# 【核心修复 3】：先加入场景树，再设置 global_position，确保坐标系正确计算
	LevelState.current_main_layer.add_child(d_num)
	d_num.global_position = damage_num.global_position
	d_num.show()
	
	# 3. 动画计算
	var tween = d_num.create_tween()
	var desv = Vector2(
		current_marker_pos.x + x_scale * randf_range(-1, 1),
		current_marker_pos.y - y_scale * randf_range(0, 1)
	)
	var rand_time:float = randf_range(.5, 1.0) * time_scale
	
	# 4. 执行位移动画 (CUBIC + OUT 保持弹跳感)
	tween.parallel().tween_property(d_num, "global_position", desv, rand_time)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		
	# 【核心修复 4】：统一使用 modulate 控制整体淡出，避免 self_modulate 无法影响文字颜色的情况
	var target_color = d_num.modulate
	target_color.a = 0.0
	tween.parallel().tween_property(d_num, "modulate", target_color, rand_time)\
		.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	
	# 5. 回收清理
	await tween.finished
	# 注意：tween 播放完毕后会自动释放，不需要手动调用 tween.kill()
	d_num.queue_free()
