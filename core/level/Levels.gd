## 关卡的根节点.
##
## 每一关的基础场景,负责统一的环境与每关的变量初始化;
extends Node2D
class_name Levels
const clazz_name = "Levels"
signal paused
##房间唯一id,level准备完毕后配置于[method _ready]
@export var level_id:LevelState.LEVELS
@export var player_layer:Node2D
##@experimental
##房间默认播放的环境音[br][code]Array["音效名",音量][/code]
var atmosphere_se_dic:Array[Array]
##@experimental
##Player在当前房间的默认[code]z index[/code][br]
##配置于[method load_player_position]
@export var player_z_index_preset:int=0 
##当前房间当前时刻的平均颜色,详见[ScreenColor]
var level_color:Color
@export var level_background_color:Color=Color("00869c"):
	set(lbc):
		level_background_color= lbc
		if base_colored_controller:base_colored_controller._on_param_changed()
var waiting_2_load_save:bool=false
@onready var leve_bound: CollisionShape2D = %LeveBound
@onready var parallax: Parallax = $Parallax
@onready var base_colored_controller: BaseColoredController = %BaseColoredController

func _init() -> void:
	set_meta("clazz_name",clazz_name)
	init()
	
##就绪
func _ready() -> void:
	load_vars()
	player_position()
	load_player_position()
	load_transitions()
	self.tree_exited.connect(_tree_exited)
	connect_signals()
	play_atmosphere_se()
	preset_player()
	
##@experimental
##初始化方法,子类重写
func init():
	pass
	
##@experimental
##初始化方法,子类重写后,配置房间ready后[Player]的出生位置
func player_position():
	pass
	
##@experimental
##初始化方法,子类重写后配置变量
func load_vars():
	pass
	
##@experimental
##初始化方法,子类重写配置信号连接
func connect_signals():
	pass	
	
##根据[member LevelState.last_level]与[member LevelState.level_transition]配置当前房间的出生播放动画
func load_transitions():
	if LevelState.last_level in LevelState.level_transition:
		LevelState.playing_transition=true
		EventBus._transition_show(LevelState.level_transition[LevelState.last_level])
		
##配置[Player]当前房间的z index		
func load_player_position():
	PlayerState.player_z_index[level_id]=player_z_index_preset
	
##初始化[Player]			
func preset_player():
	PlayerState.preset_player(self)
	
##播放[member atmosphere_se_dic]当前环境音	
func play_atmosphere_se():
	for se in atmosphere_se_dic:
		EventBus._play_SE_LOOP(se[0],true,1.0,se[1])
		
##房间tree exited时执行的方法	
func _tree_exited():
	EventBus._level_tree_exited()
	
##关卡暂停时的方法,在第一次载入时也会被调用
func pause():
	#重置玩家的X向位移
	PlayerState.player_player.velocity.x=0
	#假如当前玩家的state为lock,等待玩家进入idle的信号
	if !PlayerState.player_player.state_manager.check_current_state_by_name("lock"):
		await EventBus.player_into_lock_state
	call_deferred("set_process_mode",Node.PROCESS_MODE_DISABLED)
	#移除所有角色box
	EventBus._remove_all_character_box(self)
	Debug.dprintinfo(DebugCT.dp("level内的[pause]完成",self))
	paused.emit()
	
##关卡恢复执行,判断当前关卡是否需要载入存档,需要则[signal EventBus.load_game]通知所有saver加载数据库,否则只是将关卡恢复	
func resume():
	call_deferred("set_process_mode",Node.PROCESS_MODE_INHERIT)
	#假如当前关卡需要加载数据
	if !LevelState.level_waiting_2_load_dic.has(level_id) or LevelState.is_level_waiting_to_load(level_id):
		LevelState.set_level_waiting_to_load(level_id,false)
		PlayerState.player_player.position=PlayerState.current_player_born_position
		EventBus._load_game()
	else :
		PlayerState.player_player.position=PlayerState.current_player_born_position
		Debug.dprintinfo(DebugCT.dp("设置玩家位置为出生点位置",self))
	EventBus._create_all_character_box()
	EventBus._test_layer_visiable(true)
	Debug.dprintinfo(DebugCT.dp("level内的[resume]完成",self))
	show()

func get_level_shape_size()->Vector2:
	var shape = leve_bound.shape as RectangleShape2D
	return shape.size
	
func get_level_shape_pos()->Vector2:
	return leve_bound.position
