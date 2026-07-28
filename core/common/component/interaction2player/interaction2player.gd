extends Component
var shape_list:Array
@export var default_enable:bool = false
func _ready() -> void:
	for node in get_children():
		if node is CollisionShape2D:
			shape_list.append(node)
	set_enable(default_enable)
	
func set_enable(flag:bool,index:int = -1):
	enable = flag
	if flag:
		enable_shape(index)
	else :
		disable_shape(index)
		
func disable_shape(index:int=-1):
	for i in shape_list.size():
		shape_list[i].set_deferred("disabled" , true)

func enable_shape(index:int=-1):
	for i in shape_list.size():
		if i == index or index == -1:
			shape_list[i].set_deferred("disabled" , false)
