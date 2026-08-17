@tool
class_name FloatingDust
extends Control
@onready var particles: GPUParticles2D = $GPUParticles2D

## 2D 浮尘效果控件（GPUParticles2D）
## 平缓随气流漂浮，无明显细碎抖动

@export_group("粒子外观")
## 粒子使用的纹理。留空则使用内置柔和圆形
@export var particle_texture: Texture2D:
	set(value):
		particle_texture = value
		_update_particles()

## 粒子基础不透明度（0~1）。值越大浮尘越明显
@export_range(0.0, 1.0, 0.01) var base_alpha: float = 0.42:
	set(value):
		base_alpha = value
		_update_particles()

## 粒子基础颜色（会与闪烁曲线混合）
@export var particle_color: Color = Color(0.9, 0.92, 1.0, 1.0):
	set(value):
		particle_color = value
		_update_particles()

## 闪烁强度（0~1）。越高粒子亮度变化越明显
@export_range(0.0, 1.0, 0.01) var flicker_intensity: float = 0.55:
	set(value):
		flicker_intensity = value
		_update_particles()

## 色相随机偏移范围。让不同粒子带轻微冷暖色差
@export_range(0.0, 0.3, 0.01) var hue_variation: float = 0.06:
	set(value):
		hue_variation = value
		_update_particles()
@export_group("亮度与混合")
## 是否使用加法混合。开启后浮尘会明显比周围物体更亮、带发光感（强烈推荐）
@export var use_additive_blend: bool = true:
	set(value):
		use_additive_blend = value
		_update_blend_mode()

## 整体亮度倍率（1.0 为正常，>1 会更亮）。加法混合时建议 1.2~2.5
@export_range(0.5, 10.0, 0.05) var brightness: float = 10:
	set(value):
		brightness = value
		_update_particles()
@export_group("粒子数量与生命周期")
## 同时存在的粒子数量。越大密度越高
@export_range(10, 3000, 1) var amount: int = 160:
	set(value):
		amount = value
		_update_particles()

## 单个粒子存活时间（秒）。时间越长漂浮轨迹越长
@export_range(1.0, 30.0, 0.1) var lifetime: float = 8.5:
	set(value):
		lifetime = value
		_update_particles()

## 生命周期与速度的随机程度（0~1）
@export_range(0.0, 1.0, 0.01) var randomness: float = 0.7:
	set(value):
		randomness = value
		_update_particles()

@export_group("气流漂浮参数（平缓）")
## 粒子初始最小速度。保持较低可让运动更柔和
@export_range(0.0, 60.0, 0.1) var initial_velocity_min: float = 4.0:
	set(value):
		initial_velocity_min = value
		_update_particles()

## 粒子初始最大速度
@export_range(0.0, 80.0, 0.1) var initial_velocity_max: float = 14.0:
	set(value):
		initial_velocity_max = value
		_update_particles()

## 速度方向扩散角度（度）。较小值会让气流方向更统一
@export_range(0.0, 180.0, 1.0) var spread: float = 110.0:
	set(value):
		spread = value
		_update_particles()

## 气流主方向（X 水平，Y 垂直）。例如 Vector2(0.6, -0.25) 表示向右上方缓缓流动
@export var wind_direction: Vector2 = Vector2(0.55, -0.3):
	set(value):
		wind_direction = value
		_update_particles()

## 垂直重力（正值向下）。很小的值可模拟轻微下沉
@export_range(-20.0, 20.0, 0.1) var gravity_y: float = 2.8:
	set(value):
		gravity_y = value
		_update_particles()

## 速度阻尼。值适中可让粒子保持平缓惯性，不会突然停住
@export_range(0.0, 15.0, 0.1) var damping: float = 0.7:
	set(value):
		damping = value
		_update_particles()

## 大尺度湍流强度。保持较低可避免细碎抖动，只产生缓慢弯曲
@export_range(0.0, 3.0, 0.05) var turbulence_strength: float = 0.7:
	set(value):
		turbulence_strength = value
		_update_particles()

## 湍流噪声缩放。数值越大，弯曲越平缓、范围越大（推荐 8~15）
@export_range(1.0, 30.0, 0.1) var turbulence_scale: float = 12.0:
	set(value):
		turbulence_scale = value
		_update_particles()

## 湍流影响最小值（建议保持较低）
@export_range(0.0, 0.8, 0.01) var turbulence_influence_min: float = 0.04:
	set(value):
		turbulence_influence_min = value
		_update_particles()

## 湍流影响最大值（建议不超过 0.25，避免细碎运动）
@export_range(0.0, 0.8, 0.01) var turbulence_influence_max: float = 0.18:
	set(value):
		turbulence_influence_max = value
		_update_particles()

## 粒子旋转角速度范围（度/秒）。较低可减少干扰，保持平稳
@export_range(0.0, 60.0, 1.0) var angular_velocity: float = 8.0:
	set(value):
		angular_velocity = value
		_update_particles()

@export_group("大小")
## 粒子最小缩放倍率
@export_range(0.2, 8.0, 0.05) var scale_min: float = 0.55:
	set(value):
		scale_min = value
		_update_particles()

## 粒子最大缩放倍率
@export_range(0.2, 12.0, 0.05) var scale_max: float = 2.4:
	set(value):
		scale_max = value
		_update_particles()

@export_group("运行控制")
## 是否正在发射粒子
@export var emitting: bool = true:
	set(value):
		emitting = value
		if particles:
			particles.emitting = value

## 是否只发射一轮后停止
@export var one_shot: bool = false:
	set(value):
		one_shot = value
		if particles:
			particles.one_shot = value

var process_material: ParticleProcessMaterial


func _ready() -> void:
	_setup_particles()
	_update_particles()
	_update_blend_mode()
	if Engine.is_editor_hint():
		particles.emitting = true

func _update_blend_mode() -> void:
	if not particles:
		return
	
	var mat := particles.material as CanvasItemMaterial
	if mat == null:
		mat = CanvasItemMaterial.new()
		particles.material = mat
	
	if use_additive_blend:
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	else:
		mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX


func _get_final_color() -> Color:
	# 把亮度倍率应用到颜色上
	return Color(
		particle_color.r * brightness,
		particle_color.g * brightness,
		particle_color.b * brightness,
		1.0
	)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_emission_shape()


func _setup_particles() -> void:
	particles.name = "DustParticles"
	add_child(particles)
	move_child(particles, 0)

	process_material = ParticleProcessMaterial.new()
	particles.process_material = process_material
	particles.local_coords = true
	particles.visibility_rect = Rect2(-10000, -10000, 20000, 20000)

	if particle_texture == null:
		particle_texture = _create_default_texture()


func _create_default_texture() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(8, 8)
	for y in 16:
		for x in 16:
			var dist := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - dist / 7.5, 0.0, 1.0)
			alpha = alpha * alpha
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _update_particles() -> void:
	if not particles:
		return

	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = one_shot
	particles.emitting = emitting
	particles.texture = particle_texture
	particles.randomness = randomness

	process_material.particle_flag_disable_z = true
	process_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	_update_emission_shape()

	# ---------- 最终颜色（应用亮度倍率） ----------
	var final_col := Color(
		particle_color.r * brightness,
		particle_color.g * brightness,
		particle_color.b * brightness,
		1.0
	)

	# ---------- 闪烁颜色曲线 ----------
	var bright_a = base_alpha
	var dim_a = base_alpha * (1.0 - flicker_intensity * 0.7)
	var mid_a = base_alpha * (1.0 - flicker_intensity * 0.3)

	var gradient := Gradient.new()
	gradient.colors = [
		Color(final_col.r, final_col.g, final_col.b, 0.0),
		Color(final_col.r, final_col.g, final_col.b, bright_a),
		Color(final_col.r, final_col.g, final_col.b, dim_a),
		Color(final_col.r, final_col.g, final_col.b, mid_a),
		Color(final_col.r, final_col.g, final_col.b, dim_a * 0.65),
		Color(final_col.r, final_col.g, final_col.b, 0.0)
	]
	gradient.offsets = [0.0, 0.12, 0.35, 0.58, 0.8, 1.0]

	var color_ramp := GradientTexture1D.new()
	color_ramp.gradient = gradient
	process_material.color_ramp = color_ramp

	process_material.hue_variation_min = -hue_variation
	process_material.hue_variation_max = hue_variation

	# ---------- 平缓气流运动 ----------
	process_material.initial_velocity_min = initial_velocity_min
	process_material.initial_velocity_max = initial_velocity_max

	var dir := wind_direction.normalized() if wind_direction.length() > 0.01 else Vector2(0, -1)
	process_material.direction = Vector3(dir.x, dir.y, 0)
	process_material.spread = spread

	process_material.gravity = Vector3(0, gravity_y, 0)
	process_material.damping_min = damping * 0.6
	process_material.damping_max = damping

	# 大尺度、低强度湍流（平缓弯曲，无细碎抖动）
	process_material.turbulence_enabled = true
	process_material.turbulence_noise_strength = turbulence_strength
	process_material.turbulence_noise_scale = turbulence_scale
	process_material.turbulence_influence_min = turbulence_influence_min
	process_material.turbulence_influence_max = turbulence_influence_max

	process_material.angular_velocity_min = -angular_velocity
	process_material.angular_velocity_max = angular_velocity

	process_material.scale_min = scale_min
	process_material.scale_max = scale_max

	# 缩放曲线
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.75))
	scale_curve.add_point(Vector2(0.3, 1.05))
	scale_curve.add_point(Vector2(0.7, 0.95))
	scale_curve.add_point(Vector2(1.0, 0.7))

	var scale_curve_tex := CurveTexture.new()
	scale_curve_tex.curve = scale_curve
	process_material.scale_curve = scale_curve_tex

	# 更新混合模式
	_update_blend_mode()


func _update_emission_shape() -> void:
	if not process_material:
		return
	var half_size := size * 0.5
	process_material.emission_box_extents = Vector3(half_size.x, half_size.y, 1.0)
	if particles:
		particles.position = size * 0.5


func restart() -> void:
	if particles:
		particles.restart()


func set_emitting(value: bool) -> void:
	emitting = value
