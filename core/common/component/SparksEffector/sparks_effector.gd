@tool
class_name SparksContainer
extends Control
@onready var timer: Timer = $Timer

## === 核心配置 ===
@export_group("Sparks Settings")
@export var sparks_amount: int = 800:
	set(v): sparks_amount = v; _update_component()
@export var initial_velocity: float = 150.0:
	set(v): initial_velocity = v; _update_component()
@export var gravity_y: float = 980.0:
	set(v): gravity_y = v; _update_component()
@export_range(0.0, 1.0) var launch_randomness: float = 0.5:
	set(v): launch_randomness = v; _update_component()
@export_group("高潮配置")
@export_range(0,1) var max_amount_ratio = 0.8
@export_range(0,1) var nomal_amount_ratio = 0.1
## === 扩散度专属控制 ===
@export_group("Spread Control")
## 粒子下落阶段的扩散角度 (单位：度)。
## 即使设为 0（绝对笔直向下），由于落地扩散因子的重构，落地时也能够完美向两侧炸开！
@export_range(0.0, 90.0) var fall_spread_deg: float = 0.0:
	set(v): fall_spread_deg = v; _update_component()

## === 视觉与外观控制 ===
@export_group("Visual Settings")
@export var spark_texture: Texture2D:
	set(v): spark_texture = v; _update_component()
@export var spark_scale_range: Vector2 = Vector2(1.0, 3.0):
	set(v): spark_scale_range = v; _update_component()
@export var color_gradient: Gradient:
	set(v):
		color_gradient = v
		if color_gradient and not color_gradient.changed.is_connected(_update_component):
			color_gradient.changed.connect(_update_component)
		_update_component()

var _particles: GPUParticles2D

func _ready() -> void:
	item_rect_changed.connect(_on_size_changed)
	if color_gradient == null:
		color_gradient = Gradient.new()
		color_gradient.set_color(0, Color(2.5, 2.5, 2.5, 1.0))
		color_gradient.add_point(0.15, Color(1.0, 0.85, 0.2, 1.0))
		color_gradient.add_point(0.7, Color(0.9, 0.3, 0.05, 1.0))
		color_gradient.add_point(1.0, Color(0.2, 0.0, 0.0, 0.0))
		color_gradient.changed.connect(_update_component)
	_setup_container()
	
func _setup_container() -> void:
	if not _particles:
		_particles = get_node_or_null("InternalSparks") as GPUParticles2D
		if not _particles:
			_particles = GPUParticles2D.new()
			_particles.name = "InternalSparks"
			add_child(_particles)
	
	var height: float = size.y if size.y > 10.0 else 200.0
	var v0: float = initial_velocity
	var g: float = gravity_y
	
	var calc_lifetime: float = 1.0
	if g > 0.0:
		calc_lifetime = (-v0 + sqrt(v0 * v0 + 2.0 * g * height)) / g
	else:
		calc_lifetime = height / v0 if v0 > 0.0 else 1.0
	
	calc_lifetime = max(0.05, calc_lifetime + 0.3)
	
	_particles.amount = sparks_amount
	_particles.lifetime = calc_lifetime
	_particles.preprocess = 0.0 
	_particles.randomness = launch_randomness
	_particles.amount_ratio = nomal_amount_ratio
	
	var p_material = _particles.process_material
	p_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	var width: float = size.x if size.x > 10.0 else 300.0
	p_material.emission_box_extents = Vector3(width / 2.0, 0.0, 0.0)
	
	_particles.position = Vector2(width / 2.0, 0.0)
	
	# 下落阶段扩散：垂直向下
	p_material.direction = Vector3(0, 1, 0)
	p_material.spread = fall_spread_deg
	
	p_material.initial_velocity_min = v0 * 0.8
	p_material.initial_velocity_max = v0 * 1.2
	p_material.gravity = Vector3(0, g, 0)
	p_material.scale_min = spark_scale_range.x
	p_material.scale_max = spark_scale_range.y
	
		
	if color_gradient:
		var grad_txt = GradientTexture1D.new()
		grad_txt.gradient = color_gradient
		p_material.color_ramp = grad_txt
	
	_particles.process_material = p_material

	var canvas_mat = CanvasItemMaterial.new()
	canvas_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_particles.material = canvas_mat
	
	if spark_texture != null:
		_particles.texture = spark_texture
	else:
		_particles.texture = _generate_default_dot_texture()

func _on_size_changed() -> void:
	if is_inside_tree():
		_setup_container()

func _update_component() -> void:
	if is_node_ready():
		_setup_container()

func _generate_default_dot_texture() -> Texture2D:
	var radius: int = 4
	var tex_size: int = radius * 2
	var img = Image.create(tex_size, tex_size, false, Image.FORMAT_RGBA8)
	for y in range(tex_size):
		for x in range(tex_size):
			var dist = Vector2(x - radius, y - radius).length()
			if dist <= radius:
				var alpha = 1.0 - (dist / radius)
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	return ImageTexture.create_from_image(img)

## === 外部控制 API ===
func start_sparks() -> void:
	if _particles:
		_particles.emitting = true

func stop_sparks() -> void:
	if _particles: _particles.emitting = false

func explode_sparks(duration: float = 0.5) -> void:
	start_sparks()
	_particles.amount_ratio = max_amount_ratio
	await get_tree().create_timer(duration).timeout
	_particles.amount_ratio = nomal_amount_ratio
