extends Component
##攻击盒
##
##可以被HurtBox检测到
class_name HitBox
##当前伤害盒是否启用
@export var signal_node_list:Array[Node]
##伤害值
@export var damage:float = 1
@export_group("体力条配置")
var strength:float
@export var stamina_effect_value:float = 100
@export var hitting_stamina_effect_type:HITTING_STAMINA_EFFECT_TYPE
@export var densing_stamina_effect_type:DENSING_STAMINA_EFFECT_TYPE
##伤害范围
var shape_list:Array[CollisionShape2D]
##接触后调用所有Node的.on_hurt()方法
var real_node_list:Array
@export_group("格挡配置")
@export var blockable:bool = true
@export var damage_when_blocked:bool = true
var obj

enum HITTING_STAMINA_EFFECT_TYPE {
	DAMAGE,
	RECOVER,
}
enum DENSING_STAMINA_EFFECT_TYPE {
	RECOVER,
	DAMAGE,
}

func on_master_ready(master) -> void:
	obj = master.obj
	for node in get_children():
		if node is CollisionShape2D:
			shape_list.append(node)
	disable_shape(-1)
	if owner is Player:
		#real_node_list = signal_node_list
		return
	if signal_node_list.is_empty():return
	for node in signal_node_list:
		NpcState.add_to_export_node_cache(owner,self,node)
	for node in signal_node_list:
		real_node_list.append(NpcState.get_export_node_cache(owner,self,node))	
	
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
		if i == index:
			shape_list[i].set_deferred("disabled" , false)
