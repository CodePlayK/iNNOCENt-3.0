@icon("res://core/common/resource/icon/npc.svg")
##可以与玩家接触交互的对象
class_name Npcs extends CharacterBody2D
const clazz_name = "Npcs"
##npc的状态机管理器
@onready var state_manager: NpcStateManager = $NpcStateManager
##主sprite
@onready var animations: Animations = $Animations
@onready var base: Sprite2D = $Animations/Anime/base
@onready var base_fx: Sprite2D = $Animations/Anime/baseFX
@onready var aniplayer: AnimationPlayer = $Animations/Anime/aniplayer
@onready var test_can: CanvasLayer = $UIs/Test/TestCan
@onready var interaction: Area2D = $Components/Areas/Interaction
@onready var ui: Node2D = $UIs
@onready var hurt_fx: Node2D = $Animations/FXs/HurtFX
@onready var astar_marker: Marker = $Config/Marker/AstarMarker
@onready var player_detection: Area2D = $Components/Areas/PlayerDetection
@onready var hit_box: HitBox = $Components/HitBox
@onready var hurt_box: HurtBox = $Components/HurtBox
@onready var face_direction: FaceDirection = $Components/FaceDirection
@onready var attack_range: Area2D = $Components/HitBox/AttackRange
@onready var light: Area2D = $Components/Light
@onready var time_2_last_attack_timer: Timer = $Timer/time2LastAttackTimer
@onready var damage_num: Node2D = $UIs/HurtFX/DamageNum
@onready var health_bar: UIbar = $UIs/HealthBar
@onready var patrol_weight_machine: WeightMachine = $WeightMachines/PatrolWeightMachine
@onready var chase_weight_machine: WeightMachine = $WeightMachines/ChaseWeightMachine
@onready var anime: Anime = $Animations/Anime
@onready var health: Health = $Config/Health
@onready var obj_2_player_side: Obj2PlayerSide = $Config/Obj2PlayerSide
@onready var sound_effect: SoundEffect = $Components/SoundEffect
@onready var launche_fx: Node2D = $Animations/FXs/LauncheFX
@onready var chase_range: Area2D = $Components/Areas/ChaseRange
@onready var astar_move: Node2D = $Components/AStarMove
@onready var move_2_vec_2: Node = $Components/Move2Vec2
@onready var blood_surface: Area2D = $Components/Areas/BloodSurface
@onready var follwing_idel_range: Area2D = $Components/Areas/FollwingIdelRange

##当前Astar执行的模式,会影响其他状态执行选择
enum ASTAR_MODE {
	CHASE,##追赶,会持续执行,不启用偏移设定
	FOLLOW,##伴随,持续,启用偏移
	MOVE,##一次性,不启用偏移
}

var astar_mode:ASTAR_MODE = ASTAR_MODE.CHASE

var current_patrol_left:Marker
var current_patrol_right:Marker
var current_bot_y:float
@export_group("基础配置")
@export var npc_name:String:
	set(nn):
		npc_name=nn
var talker_name:Array[String]
@export var data:NpcsDataResource
@export var dialogue_config:DialogueConfig:
	set(r):
		if r:
			dialogue_config=r
			talker_name=dialogue_config.talkers

@export var save_data_config:SaveDataConfig
@export var character_box_config:CharacterBoxConfig:
	set(cb):
		character_box_config=cb
		if !cb.character_names:character_box_config.character_names.append(obj_name)
@export_group("状态机配置")
##初始化时进入的首个节点(并不会运行)
@export var starting_state:String
##运行时进入的状态
@export var starting1_state:String
@export var running_state:String
var on_ready=false
##巡逻范围右边界
var patrol_right:Marker2D
##巡逻范围左边界
var patrol_left:Marker2D
@onready var speed_map_2_animation: SpeedMap2Animation = $Components/SpeedMap2Animation
@export_group("AStar配置")
## A* 寻路地图（提供路径 direction / is_edge，以及 get_next_edge_cell）
@export var astar: AStarMap

## 追逐时目标格相对玩家的偏移（格坐标，交给 AStarMap.target_offset_cell_vec2i）
@export var following_offset_vec2i: Vector2i

## 地面追逐水平速度上限
@export var max_chase_speed: float = 300.0

## 地面水平加速度（沿路径 direction.x）
@export var accelerate: float = 500.0

## 地面转向时摩擦相对加速度的倍率（越大刹得越快）
@export var fric2acc_scale: float = 10.0

## 空中水平加速度
@export var air_accelerate: float = 500.0

## 空中转向时摩擦相对空中加速度的倍率
@export var air_fric2acc_scale: float = 7.0

## 重力加速度（每秒叠加到 velocity.y）
@export var gravity: float = 900.0

## 下落速度上限（防止重力无限加速）
@export var max_velocity_y: float = 1000.0

#region 竖直起跳力（按与目标边缘格的高度差 remap）
## 高度差达到 [member jump_force_max_cell_y] 格时的起跳力
@export var jump_force_max_y: float = 800.0

## 竖直 remap 的最大高度差（格）；与 [member jump_force_max_y] 对应
@export var jump_force_max_cell_y: int = 6

## 高度差为 [member jump_force_min_cell_y] 格时的起跳力
@export var jump_force_min_y: float = 550.0

## 竖直 remap 的最小高度差（格）；与 [member jump_force_min_y] 对应
@export var jump_force_min_cell_y: int = 3
#endregion

#region 边缘水平冲量（按与目标边缘格的水平距离 remap）
## 水平距离达到 [member jump_force_max_cell_x] 格时的边缘前跳水平速度
@export var jump_force_max_mid: float = 100.0

## 水平 remap 的最大格距；与 [member jump_force_max_mid] 对应
@export var jump_force_max_cell_x: int = 5

## 水平距离为 [member jump_force_min_cell_x] 格时的边缘前跳水平速度
@export var jump_force_min_mid: float = 200.0

## 水平 remap 的最小格距；与 [member jump_force_min_mid] 对应
@export var jump_force_min_cell_x: int = 2
#endregion

## 巡逻区域；不在追逐时在此 Area 内活动（与 A* 追逐互斥由状态机切换）
@export var patrol_area: Area2D
@export_group("DEBUG配置")
@export var dialogue_debug:bool = false


var last_cell
var current_cell:
	set(cc):
		last_cell=current_cell
		current_cell=cc
var current_state
var screen_position:Vector2
var being_hit:bool = false
var on_combat:bool=false
var on_following:bool=false
var on_moving:bool=false
var dodgeable:bool = true
var attacking:bool = false	
var on_fighting:bool=false:
	set(f):
		on_fighting = f
		if self.name.is_empty():return
		if f:
			if !PlayerState.player_on_fighting.has(self.name):
				PlayerState.player_on_fighting[self.name] = self
				health_bar.show()
		else :
			health_bar.hide()
			PlayerState.player_on_fighting.erase(self.name)
var face_left:bool:
	set(f):
		face_left = f
		if f:
			face_left_normalized = -1
		else :
			face_left_normalized = 1
var face_left_normalized:int
@onready var dialogue_position: Marker = $UIs/DialoguePosition
var obj_name:String:
	set(s):
		obj_name=str(s.replace("_","")).to_lower()
var on_talk:bool
func _enter_tree() -> void:
	obj_name=npc_name

func _init() -> void:
	set_meta("clazz_name",clazz_name)
	
func _ready() -> void:
	self.tree_exiting.connect(_tree_exiting)
	#state_manager.init(self)
	on_ready=true

func _unhandled_input(event: InputEvent) -> void:
	if !on_ready or CutsceneState.cutscene_playing:
		return 
	state_manager.input(event)

func _physics_process(delta: float) -> void:
	if !on_ready or CutsceneState.cutscene_playing:
		return 
	state_manager.physics_process(delta)

func _process(delta: float) -> void:
	if !on_ready or CutsceneState.cutscene_playing:
		return 
	state_manager.process(delta)

func _tree_exiting():
	PlayerState.player_lock_interact_obj.erase(self.name)
	reset_npc()
	
func reset_npc():
	pass

func init_config(config:NpcInitConfig):
	patrol_left = config.patrol_left
	patrol_right = config.patrol_right
