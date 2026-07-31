extends Component
class_name FallenFromTop
@export var right_border:Marker
@export var left_border:Marker
@onready var parrallax_move_data=preload(DataState.parallax_move_data_source_path)
@export var color_far:Color
@export var color_close:Color

func init_var():
	clazz_name="FallenFromTop"
	FATHER_CLASS_NAME=""
	
func connect_signal():
	EventBus.fallen_from_top.connect(_fallen_from_top)

func _fallen_from_top(obj:String,obj_count):
	var obj1=load(obj)
	for i in obj_count:
		var fallen_position_x:float=random_fallen_position()
		var obj2=obj1.instantiate()
		var j =randi_range(0,parrallax_move_data.dic_all_layer.size()-1)
		var layer=parrallax_move_data.dic_all_layer[j]
		if !layer:continue
		var scale=lerpf(.2,1,+(j+1.0)/parrallax_move_data.dic_all_layer.size())
		var color=color_far.lerp(color_close,float(j+1)/parrallax_move_data.dic_all_layer.size())
		color.a = 255
		obj2._play(scale,color)
		layer.add_child(obj2)
		obj2.global_position=Vector2(fallen_position_x,left_border.global_position.y)

func random_fallen_position()->float:
	return randf_range(left_border.global_position.x,right_border.global_position.x)
