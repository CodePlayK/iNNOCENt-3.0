extends Component
class_name Health
@export var tagets:Array[Node]
@export var max_health:float
@export var min_health:float
@export var health_regeneration:float
@export_group("debug")
@export var print_health:bool = false
var current_damage:float = 0
var current_heal:float = 0
var current_health:float:
	set(f):
		if f == current_health:return
		last_health = current_health
		current_health = f
		if print_health:Debug.dprintinfo(DebugCT.dp("[Health]%s" %current_health,self))
var last_health:float

func set_health(v):
	current_health = v	
##治疗	
func heal(v):
	current_heal = v
	current_health += v	
	on_health_healed(self)
##受伤	
func damage(v):
	current_damage = v
	current_health -= v	
	on_health_damaged(self)
##治疗事件	
func on_health_damaged(health):
	for node in tagets:
		if node.has_method("on_health_damaged"):
			node.on_health_damaged(health)
##伤害事件		
func on_health_healed(health):
	for node in tagets:
		if node.has_method("on_health_healed"):
			node.on_health_healed(health)
##master初始化事件			
func on_master_ready(m:Master) -> void:
	max_health = m.obj.data.health
	current_health = max_health
	for node in tagets:
		if node.has_method("on_health_init"):
			node.on_health_init(self)
