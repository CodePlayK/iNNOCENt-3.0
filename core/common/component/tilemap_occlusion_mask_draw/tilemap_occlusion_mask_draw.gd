extends Node2D
class_name TileMapOcclusionMaskDraw
## 在 SubViewport 内根据 TileMapLayer 碰撞多边形绘制白色遮挡剪影


@export var source_layer: TileMapLayer
## TileSet 物理层下标
@export var physics_layer: int = 0
## true：碰撞多边形；false：整格矩形
@export var use_collision_polygons: bool = true
@export var inflate: float = 0.0


func _draw() -> void:
	if source_layer == null or source_layer.tile_set == null:
		return

	var tile_set: TileSet = source_layer.tile_set
	var tile_size: Vector2 = Vector2(tile_set.tile_size)

	for cell: Vector2i in source_layer.get_used_cells():
		var td: TileData = source_layer.get_cell_tile_data(cell)
		if td == null:
			continue

		var cell_local: Vector2 = source_layer.map_to_local(cell)
		var cell_global: Vector2 = source_layer.to_global(cell_local)

		if use_collision_polygons:
			var poly_count: int = td.get_collision_polygons_count(physics_layer)
			if poly_count <= 0:
				continue
			for pi in poly_count:
				var pts: PackedVector2Array = td.get_collision_polygon_points(physics_layer, pi)
				if pts.is_empty():
					continue
				var world_pts := PackedVector2Array()
				for p in pts:
					var gp: Vector2 = source_layer.to_global(cell_local + p)
					world_pts.append(to_local(gp))
				if inflate != 0.0:
					world_pts = _inflate_polygon(world_pts, inflate)
				draw_colored_polygon(world_pts, Color.WHITE)
		else:
			var center: Vector2 = to_local(cell_global)
			var rect := Rect2(center - tile_size * 0.5, tile_size)
			if inflate != 0.0:
				rect = rect.grow(inflate)
			draw_rect(rect, Color.WHITE, true)


func rebuild() -> void:
	queue_redraw()


func _inflate_polygon(pts: PackedVector2Array, amount: float) -> PackedVector2Array:
	if pts.size() < 3 or is_zero_approx(amount):
		return pts
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var out := PackedVector2Array()
	for p in pts:
		var dir: Vector2 = p - c
		if dir.length_squared() > 0.0001:
			out.append(p + dir.normalized() * amount)
		else:
			out.append(p)
	return out
