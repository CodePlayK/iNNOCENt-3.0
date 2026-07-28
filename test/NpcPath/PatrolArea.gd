extends Area2D
var patrol_list:Array[PatrolConfig]
@export var patrol_config:PatrolConfig
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var i = 0
	for shape in get_children():
		if shape is CollisionShape2D:
			var marker = Global.marker.instantiate()
			add_child(marker)
			marker.global_position = to_global(shape.position) - Vector2(shape.shape.get_rect().size.x*.5,0)
			var marker1 = Global.marker.instantiate()
			add_child(marker1)
			marker1.global_position = to_global(shape.position) - Vector2(shape.shape.get_rect().size.x*.5,0)+ Vector2(shape.shape.get_rect().size.x,0)
			i += 1
			var bot_y = to_global(shape.position).y + shape.shape.get_rect().size.y*.5
			patrol_list.append(PatrolConfig.new(marker,marker1,bot_y))
			#patrol_dic[i] = [marker,marker1]
