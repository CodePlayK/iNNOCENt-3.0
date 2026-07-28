extends Polygon2D
@onready var new_light: Node2D = $"../NewLight"
@onready var p: Polygon2D = $"."
@onready var p2: Polygon2D = $"../Dark"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var pl = Geometry2D.clip_polygons(p.polygon,p2.polygon)
	var pgs:Array
	for pg in pl:
		if not Geometry2D.is_polygon_clockwise(pg):
			pgs.append(pg)
	for np in pgs:
		var n = Polygon2D.new()
		new_light.add_child(n)
		n.polygon = np
	#p.polygon = pgs[1]
	p.hide()
