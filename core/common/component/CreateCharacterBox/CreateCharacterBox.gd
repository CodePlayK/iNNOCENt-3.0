extends Component
var obj
@onready var timer: Timer = $Timer
#生成角色box的延迟随机范围
@export var time_rand_range:Vector2 = Vector2(1,3)
@export var create_on_load:bool = false
var character_box_config:CharacterBoxConfig
var create_cache:bool=false

func on_master_ready(master:Master):
	EventBus.level_changed.connect(on_level_changed)
	obj = master.obj
	obj.character_box_config.obj_id = obj.obj_name
	character_box_config=obj.character_box_config
	character_box_config.level_id=LevelState.current_level
	UiState.character_box_dic[character_box_config.character_box_id]=character_box_config
	if create_on_load:
		EventBus._create_character_box(obj.character_box_config)
		return
	#if create_cache:
		#create_character_box()
		#create_cache=false
	#
func _on_timer_timeout() -> void:
	EventBus._create_character_box(obj.character_box_config)
	
func create_character_box():
	if !character_box_config:
		create_cache=true
		return 
	if !UiState.character_box_dic.has(character_box_config.character_box_id):
		UiState.character_box_dic[character_box_config.character_box_id]=character_box_config
	UiState.character_box_dic[character_box_config.character_box_id].showing=true
	timer.start(randf_range(time_rand_range.x,time_rand_range.y))

func remove_character_box():
	if !obj:return
	UiState.character_box_dic[character_box_config.character_box_id].showing=false
	EventBus._remove_character_box(character_box_config,character_box_config.level_id)
	
func remove_all_character_box():
	if !obj:return
	
func on_level_changed(fl,tl):
	timer.stop()
	if !obj:return
