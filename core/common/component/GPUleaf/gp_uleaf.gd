@icon("res://addons/at-icons/node3d/mountains.svg")
class_name LeafParticles
extends GPUParticles2D

@export var leaf_sheet: Texture2D
@export var h_frames := 4
@export var v_frames := 1
@export var amount_count := 80
@export var fall_speed := Vector2(20, 45)
@export var gravity_y := 40.0
@export var enabled := true:
	set(v):
		enabled = v
		emitting = v

@onready var area_shape: CollisionShape2D = $SpawnArea

func _ready() -> void:
	_build()
	emitting = enabled

func _build() -> void:
	var rect := _get_rect_local()
	var half := rect.size * 0.5

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(half.x, 2.0, 0.0)
	mat.emission_shape_offset = Vector3(
		area_shape.position.x,
		area_shape.position.y - half.y,
		0.0
	)

	mat.direction = Vector3(0, 1, 0)
	mat.spread = 28.0
	mat.initial_velocity_min = fall_speed.x
	mat.initial_velocity_max = fall_speed.y
	mat.gravity = Vector3(0, gravity_y, 0)

	mat.angular_velocity_min = -50.0
	mat.angular_velocity_max = 50.0
	mat.linear_accel_min = -10.0
	mat.linear_accel_max = 10.0
	mat.damping_min = 1.0
	mat.damping_max = 5.0
	mat.scale_min = 0.55
	mat.scale_max = 1.15

	# 随机序列帧播放速度 + 随机起始帧
	mat.anim_speed_min = 3
	mat.anim_speed_max = 7
	mat.anim_offset_min = 0.0
	mat.anim_offset_max = 1.0

	# 不要 color_ramp，不渐变
	mat.color = Color.WHITE

	# 按高度估寿命，到边界附近粒子直接结束（无淡出）
	var speed := (fall_speed.x + fall_speed.y) * 0.5
	var fall_time := rect.size.y / maxf(speed + gravity_y * 0.15, 1.0)
	lifetime = clampf(fall_time, 0.8, 12.0)
	preprocess = 0.0
	amount = amount_count
	explosiveness = 0.0
	randomness = 0.65
	local_coords = true

	# 出 shape 直接不显示（视觉上“到边界就没”）
	visibility_rect = Rect2(rect.position, rect.size)

	process_material = mat
	texture = leaf_sheet

	var canvas_mat := CanvasItemMaterial.new()
	canvas_mat.particles_animation = true
	canvas_mat.particles_anim_h_frames = h_frames
	canvas_mat.particles_anim_v_frames = v_frames
	canvas_mat.particles_anim_loop = true
	material = canvas_mat

func _get_rect_local() -> Rect2:
	var shape := area_shape.shape
	var pos := area_shape.position
	if shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		return Rect2(pos - size * 0.5, size)
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		return Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0)
	return Rect2(-100, -100, 200, 200)

func start_emit() -> void:
	enabled = true

func stop_emit() -> void:
	enabled = false

## 改 shape 大小后可手动刷新
func rebuild() -> void:
	var was := emitting
	emitting = false
	_build()
	emitting = was and enabled
