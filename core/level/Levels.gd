## 关卡的根节点.
##
## 每一关的基础场景,负责统一的环境与每关的变量初始化;
extends Node2D
class_name Levels
const clazz_name = "Levels"
signal paused
##房间唯一id,level准备完毕后配置于[method _ready]
@export var level_id:LevelState.LEVELS
##@experimental
##房间默认播放的环境音[br][code]Array["音效名",音量][/code]
var atmosphere_se_dic:Array[Array]
##房间中的[Player][Player]对象
@onready var player:Player = %Player
##@experimental
##Player在当前房间的默认[code]z index[/code][br]
##配置于[method load_player_position]
@export var player_z_index_preset:int=0 
##[Player]的相机,兼为过场动画相机
@onready var player_camera = %PlayerCamera
##当前房间当前时刻的平均颜色,详见[ScreenColor]
var level_color:Color
@export var level_background_color:Color=Color("00869c")
var waiting_2_load_save:bool=false

func _init() -> void:
	set_meta("clazz_name",clazz_name)
	init()
	
##就绪
func _ready() -> void:
	LevelState.current_level=level_id
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
	PlayerState.preset_player()
	
##播放[member atmosphere_se_dic]当前环境音	
func play_atmosphere_se():
	for se in atmosphere_se_dic:
		EventBus._play_SE_LOOP(se[0],true,1.0,se[1])
		
##房间tree exited时执行的方法	
func _tree_exited():
	EventBus._level_tree_exited()

func pause():
	PlayerState.player_control_lock = true
	hide()
	position=Vector2i(10000,10000)
	player.velocity.x=0
	player.position=PlayerState.current_player_born_position
	if !player.state_manager.current_state == player.state_manager.get_state_by_name("idle"):
		player.state_manager.change_state(player.state_manager.get_state_by_name("idle"))
		await player.state_manager.get_state_by_name("idle").into_indel_state
		Debug.dprintinfo(DebugCT.dp("收到idle信号",self))

	call_deferred("set_process_mode",Node.PROCESS_MODE_DISABLED)
	Debug.dprintinfo(DebugCT.dp("level的暂停完成信号发出",self))
	paused.emit()
	
##关卡恢复执行,判断当前关卡是否需要载入存档,需要则[signal EventBus.load_game]通知所有saver加载数据库,否则只是将关卡恢复	
func resume():
	call_deferred("set_process_mode",Node.PROCESS_MODE_INHERIT)
	if !LevelState.level_waiting_2_load_dic.has(level_id) or LevelState.is_level_waiting_to_load(level_id):
		LevelState.set_level_waiting_to_load(level_id,false)
		EventBus._load_game()
	EventBus._test_layer_visiable(true)
	position=Vector2i.ZERO
	show()
	PlayerState.player_control_lock = false
