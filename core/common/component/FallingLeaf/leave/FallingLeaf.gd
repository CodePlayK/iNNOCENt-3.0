class_name FallingLeaf
extends Node2D

signal finished
signal landed  # 落地时通知：空中数量 -1

@export var gravity := 45.0
@export var max_speed_y := 55.0
@export var sway := 16.0
@export var rest_time := 2.5
@export var fade_time := 1.2
var enable_collision:bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var ray: RayCast2D = $FloorRay

var vel := Vector2.ZERO
var phase := 0  # 0空中 1停 2淡
var timer := 0.0
var seed := 0.0
var spin := 0.0
var bounds := Rect2()

func launch(pos: Vector2, ec:bool,area_bounds: Rect2 = Rect2(),) -> void:
	enable_collision = ec
	if !enable_collision:
		ray.enabled = false
	position = pos
	bounds = area_bounds
	phase = 0
	timer = 0.0
	seed = randf() * TAU
	spin = randf_range(-1.2, 1.2)
	vel = Vector2(randf_range(-12, 12), randf_range(8, 20))
	sprite.modulate.a = 1.0
	sprite.play()
	rotation = randf_range(-0.3, 0.3)
	visible = true
	set_process(true)

func _process(dt: float) -> void:
	if bounds.has_area() and not bounds.has_point(position):
		_kill(false)
		return

	match phase:
		0:
			vel.y = minf(vel.y + gravity * dt, max_speed_y)
			var wind_x := sin(Time.get_ticks_msec() * 0.004 + seed) * sway
			position += Vector2(vel.x + wind_x, vel.y) * dt
			rotation += spin * dt
			if enable_collision:
				ray.force_raycast_update()
				if ray.is_colliding():
					position = get_parent().to_local(ray.get_collision_point())
					sprite.pause()  # 落地暂停动画
					phase = 1
					timer = rest_time
					landed.emit()
		1:
			timer -= dt
			if timer <= 0.0:
				phase = 2
				timer = fade_time
		2:
			timer -= dt
			sprite.modulate.a = clampf(timer / fade_time, 0.0, 1.0)
			if timer <= 0.0:
				_kill(true)

func _kill(from_land: bool) -> void:
	# from_land=true：已发过 landed，只回收
	# from_land=false：还在空中越界，要当空中数减少
	if phase == 0:
		landed.emit()
	visible = false
	set_process(false)
	finished.emit()
