extends Polygon2D
class_name Godray
## 视差体积光（四边形）
##
## 顶点：0 左上, 1 右上, 2 右下, 3 左下
## 上边跟随 [member top_follow_layer]，下边跟随 [member bottom_follow_layer]
## 两侧均可叠加独立水平 offset。


#region Export
@export var bright: float = 0.9
@export var enable: bool = true

## 上边两点（0、1）跟随的视差层节点名
@export var top_follow_layer: String = "ParallaxLayer_3"

## 下边两点（2、3）跟随的视差层节点名
@export var bottom_follow_layer: String = "ParallaxLayer_0"

## 本节点所在视差层；主层（速度 0）可留空
@export var host_layer: String = ""

## 跟随位移缩放
@export var offset_scale: float = 1.0

## 上边额外水平错位（正右负左）
@export var top_offset_x: float = 0.0

## 下边额外水平错位（正右负左）
@export var bottom_offset_x: float = 0.0

@export_group("顶点水平微调（记录基准前施加）")
@export var point_top_left_offset: float = 0.0
@export var point_top_right_offset: float = 0.0
@export var point_bot_left_offset: float = 0.0
@export var point_bot_right_offset: float = 0.0
#endregion


#region Node
@onready var light_area: Area2D = $LightArea
@onready var collision_shape_2d: CollisionShape2D = $LightArea/CollisionShape2D
#endregion


#region Runtime
var parallax_move_data: ParallaxMoveData

var _base_top_left: Vector2 = Vector2.ZERO
var _base_top_right: Vector2 = Vector2.ZERO
var _base_bot_right: Vector2 = Vector2.ZERO
var _base_bot_left: Vector2 = Vector2.ZERO
#endregion


func _ready() -> void:
	if light_area and "bright" in light_area:
		light_area.bright = bright

	if collision_shape_2d and collision_shape_2d.shape == null:
		collision_shape_2d.shape = RectangleShape2D.new()

	if polygon.size() < 4:
		push_error("Godray: polygon 需要 4 个点 (TL, TR, BR, BL)")
		set_physics_process(false)
		return

	var poly := PackedVector2Array(polygon)
	poly[0].x += point_top_left_offset
	poly[1].x += point_top_right_offset
	poly[2].x += point_bot_right_offset
	poly[3].x += point_bot_left_offset
	polygon = poly

	_base_top_left = poly[0]
	_base_top_right = poly[1]
	_base_bot_right = poly[2]
	_base_bot_left = poly[3]

	parallax_move_data = preload(DataState.parallax_move_data_source_path)
	_update_collision_shape()


func _physics_process(_delta: float) -> void:
	if parallax_move_data == null:
		return
	if !enable:
		return
	var top_x: float = _follow_offset_x(top_follow_layer) + top_offset_x
	var bot_x: float = _follow_offset_x(bottom_follow_layer) + bottom_offset_x

	var poly := PackedVector2Array(polygon)
	poly[0] = _base_top_left + Vector2(top_x, 0.0)
	poly[1] = _base_top_right + Vector2(top_x, 0.0)
	poly[2] = _base_bot_right + Vector2(bot_x, 0.0)
	poly[3] = _base_bot_left + Vector2(bot_x, 0.0)
	polygon = poly

	_update_collision_shape()


func _follow_offset_x(follow_layer: String) -> float:
	var data: Dictionary = parallax_move_data.dic_layers_move_data
	if follow_layer.is_empty() or not data.has(follow_layer):
		return 0.0

	var follow_move: float = float(data[follow_layer])
	var host_move: float = 0.0
	if not host_layer.is_empty() and data.has(host_layer):
		host_move = float(data[host_layer])

	return (follow_move - host_move) * offset_scale


func _update_collision_shape() -> void:
	if collision_shape_2d == null or collision_shape_2d.shape == null:
		return
	if polygon.size() < 4:
		return

	var min_x := polygon[0].x
	var max_x := polygon[0].x
	var min_y := polygon[0].y
	var max_y := polygon[0].y
	for i in 4:
		var p: Vector2 = polygon[i]
		min_x = minf(min_x, p.x)
		max_x = maxf(max_x, p.x)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)

	var size := Vector2(max_x - min_x, max_y - min_y)
	collision_shape_2d.position = Vector2(min_x + size.x * 0.5, min_y + size.y * 0.5)
	if collision_shape_2d.shape is RectangleShape2D:
		(collision_shape_2d.shape as RectangleShape2D).size = size
