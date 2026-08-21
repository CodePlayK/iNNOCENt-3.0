@icon("res://addons/at-icons/animation/eye.svg")

extends ColorRect

# ==============================================================================
# 🎯 核心追踪与触发配置
# ==============================================================================

## 想要高亮追踪的目标 Sprite2D 节点。
@export var target_sprite: Sprite2D:
	set(val):
		target_sprite = val
		set_process(target_sprite != null)

## 用于检测交互的 Area2D 节点。
@export var trigger: Area2D

## 触发交互的检测类型：[br]
## - BODY: 当有物理身体（如玩家角色）进入或离开时触发。[br]
## - MOUSE: 当鼠标悬停或离开检测区时触发。
@export_enum("BODY", "MOUSE") var trigger_type: String = "BODY"

## 自定义提示光点的局部偏移量（相对于目标 Sprite 帧中心的像素距离）。[br]
## 例如 Vector2(-50, -20) 让光点默认出现在 Sprite 左上方。
@export var dot_local_offset: Vector2 = Vector2.ZERO:
	set(val):
		dot_local_offset = val
		_update_shader_positions()

## 扩散与收缩动画的持续时间（单位：秒）。
@export var transition_duration: float = 0.35

# =================================AAAAAAAAA=============================================
# 🎨 Shader 视觉外观控制变量 (仅在变动和初始化时通知 GPU)
# ==============================================================================

@export_group("Glow Dot Settings", "dot_")
## 交互未激活时，默认呼吸提示光点的颜色与基础不透明度。
@export var dot_color: Color = Color.WHITE:
	set(val):
		dot_color = val
		_set_shader_param("glow_color", val)

## 提示光点的基础直径大小（单位：像素）。
@export var dot_size: float = 8.0:
	set(val):
		dot_size = val
		_set_shader_param("dot_size", val)

## 光点呼吸时的大小缩放变化幅度。设为 0 时光点保持静止不呼吸。
@export var dot_breathe_amplitude: float = 0.2:
	set(val):
		dot_breathe_amplitude = val
		_set_shader_param("breathe_amplitude", val)

## 光点呼吸运动的频率速度。数值越大呼吸越急促。
@export var dot_breathe_speed: float = 2.5:
	set(val):
		dot_breathe_speed = val
		_set_shader_param("breathe_speed", val)

@export_group("Border Settings", "border_")
## 交互激活后，最终形成的包裹边框的粗细大小（单位：像素）。
@export var border_thickness: float = 1.2:
	set(val):
		border_thickness = val
		_set_shader_param("border_thickness", val)

@export_group("Glitch Effects", "glitch_")
## 边框边缘随机抖动的速度。数值越大，电磁干扰的抖动频率越高。
@export var glitch_speed: float = 15.0:
	set(val):
		glitch_speed = val
		_set_shader_param("glitch_speed", val)

## 边框边缘随机抖动的最大幅度（单位：实际像素）。
@export var glitch_amplitude: float = 2.0:
	set(val):
		glitch_amplitude = val
		_set_shader_param("glitch_amplitude", val)

# ==============================================================================
# 🛠️ 内部变量与生命周期
# ==============================================================================

var _tween: Tween
var _is_active: bool = false

func _ready() -> void:
	# 确保全程开启 _process 实时追踪
	set_process(target_sprite != null)
	
	if not material is ShaderMaterial:
		material = ShaderMaterial.new()
	
	# 初始化时向 GPU 批量投递材质 Uniform 常数
	_init_shader_parameters()
	
	# 连接触发器信号
	if trigger:
		match trigger_type:
			"MOUSE":
				trigger.mouse_entered.connect(activate)
				trigger.mouse_exited.connect(deactivate)
			"BODY":
				trigger.body_entered.connect(body_activate)
				trigger.body_exited.connect(body_deactivate)
	show()


func _process(_delta: float) -> void:
	# 【全程实时计算】不论未激活（光点状态）还是已激活（方框状态），每帧彻底同步位置、大小与缩放变化
	_update_shader_positions()


# ==============================================================================
# 🧮 核心空间坐标计算矩阵（每帧执行）
# ==============================================================================

func _update_shader_positions() -> void:
	if 	CutsceneState.cutscener_playing:
		deactivate()
	if not target_sprite or not is_inside_tree(): return
	
	var mat := material as ShaderMaterial
	if not mat: return

	# 1. 传递窗口/视口物理尺寸
	var viewport_size := get_viewport_rect().size
	mat.set_shader_parameter("view_size", viewport_size)

	# 2. 获取目标 Sprite 当前单帧的原始纹理像素大小（每帧捕捉 AnimationPlayer 的帧切换）
	var raw_frame_size := Vector2.ZERO
	if target_sprite.texture:
		var tex_size = target_sprite.texture.get_size()
		raw_frame_size = Vector2(
			tex_size.x / target_sprite.hframes,
			tex_size.y / target_sprite.vframes
		)
	
	# 3. 依据 Sprite 中心对齐模式，建立局部中心
	var local_center := Vector2.ZERO
	if not target_sprite.centered:
		local_center = raw_frame_size * 0.5

	# 4. 获取 Canvas 屏幕变换矩阵（每帧捕获移动、旋转、相机位移）
	var sprite_to_canvas_xform: Transform2D = target_sprite.get_global_transform_with_canvas()

	# 5. 精确提取矩阵绝对全局缩放比例，解算屏幕空间尺寸
	var global_scale_x: float = sprite_to_canvas_xform.get_scale().x
	var global_scale_y: float = sprite_to_canvas_xform.get_scale().y
	var sprite_size_screen := Vector2(raw_frame_size.x * global_scale_x, raw_frame_size.y * global_scale_y)
	
	var sprite_center_screen: Vector2 = sprite_to_canvas_xform * local_center
	
	mat.set_shader_parameter("sprite_center_screen", sprite_center_screen)
	mat.set_shader_parameter("sprite_size_screen", sprite_size_screen)

	# 6. 精确计算自定义提示光点的屏幕空间位置
	var dot_local_pos: Vector2 = local_center + dot_local_offset
	var dot_center_screen: Vector2 = sprite_to_canvas_xform * dot_local_pos
	mat.set_shader_parameter("dot_center_screen", dot_center_screen)


## 初始化向 GPU 批量投递材质 Uniform 常数
func _init_shader_parameters() -> void:
	_set_shader_param("glow_color", dot_color)
	_set_shader_param("dot_size", dot_size)
	_set_shader_param("breathe_amplitude", dot_breathe_amplitude)
	_set_shader_param("breathe_speed", dot_breathe_speed)
	_set_shader_param("border_thickness", border_thickness)
	_set_shader_param("glitch_speed", glitch_speed)
	_set_shader_param("glitch_amplitude", glitch_amplitude)


## 安全的 Shader 参数提交接口
func _set_shader_param(param_name: String, value: Variant) -> void:
	if is_inside_tree() and material is ShaderMaterial:
		(material as ShaderMaterial).set_shader_parameter(param_name, value)

# ==============================================================================
# 🚀 状态控制与超调动画函数
# ==============================================================================

## 激活交互：从小光点从任意位置炸开，超调回弹后实时咬紧动态方框边界
func activate() -> void:
	if PlayerState.get_player_control_lock(self):
		return
	if _is_active: return
	_is_active = true
	_animate_progress(1.0)


## 退出交互：从方框重新物理缩回自定义起点光点位置
func deactivate() -> void:
	if PlayerState.get_player_control_lock(self):
		return
	if not _is_active: return
	_is_active = false
	_animate_progress(0.0)


func body_activate(_body: Node2D) -> void:
	activate()


func body_deactivate(_body: Node2D) -> void:
	deactivate()


func _animate_progress(target_value: float) -> void:
	if _tween:
		_tween.kill()
	
	var mat := material as ShaderMaterial
	if not mat: return
	
	_tween = create_tween()
	if target_value > 0.5:
		# 使用 TRANS_BACK 在展开时产生向外弹出的超调回弹动画
		_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	else:
		_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
		
	_tween.tween_property(mat, "shader_parameter/progress", target_value, transition_duration)
