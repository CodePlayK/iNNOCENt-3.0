@icon("res://addons/at-icons/mesh/mountains.svg")

class_name LeafFallSpawner
extends Node2D

@export var leaf_scene: PackedScene
@export var count_range := Vector2i(1, 1)  # 每波尝试补多少
@export var interval := 0.4
@export var max_alive := 10  # 空中最多几片
@export var enable_collision:bool = false
@export var enabled := true:
	set(v):
		enabled = v
		set_process(enabled)
		if enabled:
			wait = 0.0

@onready var area_shape: CollisionShape2D = $SpawnArea

var pool: Array[FallingLeaf] = []
var flying := 0  # 仅统计空中
var wait := 0.0

func _ready() -> void:
	set_process(enabled)

func _process(dt: float) -> void:
	if not enabled or flying >= max_alive:
		return
	wait -= dt
	if wait > 0.0:
		return
	wait = interval * randf_range(0.7, 1.3)
	var n := randi_range(mini(count_range.x, count_range.y), maxi(count_range.x, count_range.y))
	n = mini(n, max_alive - flying)
	for i in n:
		_spawn_one()

func start() -> void:
	enabled = true

func stop() -> void:
	enabled = false

func _spawn_one() -> void:
	var leaf := _take()
	leaf.launch(_random_point(),enable_collision, _get_bounds_local())
	flying += 1

func _on_landed() -> void:
	flying = maxi(flying - 1, 0)

func _random_point() -> Vector2:
	var shape := area_shape.shape
	var local := Vector2.ZERO
	if shape is RectangleShape2D:
		var half := (shape as RectangleShape2D).size * 0.5
		local = Vector2(randf_range(-half.x, half.x), -half.y)
	elif shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		local = Vector2(randf_range(-r, r), -r)
	return area_shape.position + area_shape.transform.basis_xform(local)

func _get_bounds_local() -> Rect2:
	var shape := area_shape.shape
	var pos := area_shape.position
	if shape is RectangleShape2D:
		var size := (shape as RectangleShape2D).size
		return Rect2(pos - size * 0.5, size)
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		return Rect2(pos - Vector2(r, r), Vector2(r, r) * 2.0)
	return Rect2()

func _take() -> FallingLeaf:
	for leaf in pool:
		if not leaf.visible:
			return leaf
	var leaf: FallingLeaf = leaf_scene.instantiate()
	add_child(leaf)
	leaf.landed.connect(_on_landed)
	leaf.finished.connect(func(): pass)  # 仅回收进池，flying 已在 landed 时扣过
	pool.append(leaf)
	return leaf
