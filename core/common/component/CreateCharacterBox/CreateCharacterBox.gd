extends Component
var obj
@onready var timer: Timer = $Timer
#生成角色box的延迟随机范围
@export var time_rand_range:Vector2 = Vector2(1,3)
@export var create_on_load:bool = false
var exist_level:LevelState.LEVELS

func on_master_ready(master:Master):
	EventBus.remove_all_character_box.connect(remove_all_character_box)
	obj = master.obj
	exist_level = LevelState.current_level
	#if create_on_load:
		#create_character_box()
		
func _on_timer_timeout() -> void:
	EventBus._create_character_box(obj.character_box_config)
	
func create_character_box():
	timer.start(randf_range(time_rand_range.x,time_rand_range.y))

func remove_character_box():
	if !obj:return
	EventBus._remove_character_box(obj.character_box_config,exist_level)
func remove_all_character_box():
	if !obj:return
	if exist_level == LevelState.current_level:
		return
	EventBus._remove_character_box(obj.character_box_config,exist_level)
