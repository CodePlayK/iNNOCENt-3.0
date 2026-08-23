@icon("res://addons/at-icons/mesh/human.svg")

##玩家控制对象
class_name Player extends CharacterBody2D
var obj_name:String = "player"
@export_group("基础")
### 对话中本角色使用的说话人名称列表
#@export var talker_name:Array[String]
## 本角色使用的对话资源配置
@export var dialogue_config:DialogueConfig
## 角色立绘/对话框配置；未填写角色名时会自动追加玩家名
@export var character_box_config:CharacterBoxConfig:
	set(cb):
		character_box_config=cb
		if !cb.character_names:character_box_config.append(obj_name)
## 是否在场景中创建角色对话框
@export var create_character_box: bool=true

@export_group("运动")
## 玩家死亡后是否传送回出生位置
@export var dead_switch: bool=true
## 重力加速度（每秒叠加到 velocity.y）
@export var gravity: int=800
## 下落速度上限（防止重力无限加速）
@export var max_velocity_y: int=800
## 奔跑时的水平加速度
@export var acceleration_run: int=400
## 冲刺时的水平加速度
@export var acceleration_dash: int=700
## 冲刺水平速度上限
@export var max_speed_dash: int=700
## 水平摩擦力（用于减速）
@export var friction: int=800
## 奔跑水平速度上限
@export var max_speed_run: int=200
## 疾跑水平速度上限
@export var max_speed_fast_run: int=300
## 行走水平速度上限
@export var max_speed_walk: int=100
## 跳跃初速度（向上，赋值给 -velocity.y）
@export var jump_speed: int=220
## 攀爬竖直速度
@export var climb_speed: int=120
## 攀爬水平速度
@export var climb_speed_x: int=80
## 短按跳跃时，将上升速度削减为 jump_speed / 该值
@export var click_jump_force_limit:=5
## 短按跳跃生效的最小上升速度阈值（未达此速度不削减）
@export var min_jump_fource:=70
@export_group("AStar配置")
## A* 寻路地图（提供路径 direction / is_edge，以及 get_next_edge_cell）
@export var astar:AStarMap
## 地面追逐水平速度上限
@export var max_chase_speed:float = 600
## 地面水平加速度（沿路径 direction.x）
@export var accelerate:float = 2000
## 地面转向时摩擦相对加速度的倍率（越大刹得越快）
@export var fric2acc_scale:float = 10
## 空中水平加速度
@export var air_accelerate:float = 2000
## 空中转向时摩擦相对空中加速度的倍率
@export var air_fric2acc_scale:float = 10
## 高度差达到 [member jump_force_max_cell_y] 格时的起跳力
@export var jump_force_max_y:float  = 1000
## 竖直 remap 的最大高度差（格）；与 [member jump_force_max_y] 对应
@export var jump_force_max_cell_y:int = 8
## 高度差为 [member jump_force_min_cell_y] 格时的起跳力
@export var jump_force_min_y:float = 700
## 竖直 remap 的最小高度差（格）；与 [member jump_force_min_y] 对应
@export var jump_force_min_cell_y:int = 4
## 水平距离达到 [member jump_force_max_cell_x] 格时的边缘前跳水平速度
@export var jump_force_max_mid:float  = 1000
## 水平 remap 的最大格距；与 [member jump_force_max_mid] 对应
@export var jump_force_max_cell_x:int = 8
## 水平距离为 [member jump_force_min_cell_x] 格时的边缘前跳水平速度
@export var jump_force_min_mid:float = 700
## 水平 remap 的最小格距；与 [member jump_force_min_mid] 对应
@export var jump_force_min_cell_x:int = 4
@export_group("战斗")
## 耐力自然恢复速度（每秒）
@export var stamina_recovered_speed:float = 20
var on_ready:bool=false
var face_left:bool=true:
	set(f):
		face_left = f
		PlayerState.face_left = f
var face_left_normalized
var start_position
var current_cell
var last_cell
var interaction = self
##当前Astar执行的模式,会影响其他状态执行选择
enum ASTAR_MODE {
	CHASE,##追赶,会持续执行,不启用偏移设定
	FOLLOW,##伴随,持续,启用偏移
	MOVE,##一次性,不启用偏移
}
var astar_mode:ASTAR_MODE = ASTAR_MODE.CHASE
#region @onready
@onready var dialogue_position: Marker = $Config/Marks/DialoguePosition
@onready var screen_vec_2: Node2D = $Config/Marks/ScreenVec2
@onready var block_checker_right: RayCast2D = $Config/Rays/blockCheckerRight
@onready var block_checker_left: RayCast2D = $Config/Rays/blockCheckerLeft
@onready var ground_checker: RayCast2D = $Config/Rays/groundChecker
@onready var base: Sprite2D = $Animations/Anime/base
@onready var base_fx: Sprite2D = $Animations/Anime/baseFX
@onready var state_manager: PlayerStateManager = $StateManager
@onready var ui: Node2D = $UIs
@onready var hurt_box: HurtBox = $Components/HurtBox
@onready var hit_box: HitBox = $Components/HitBox
@onready var anime: Anime = $Animations/Anime
@onready var hit_fx: Node2D = $Animations/FXs/HitFx
@onready var aniplayer: AnimationPlayer = $Animations/Anime/aniplayer
@onready var health: Node2D = $Attributes/Health
@onready var stamina: Node2D = $Attributes/Stamina
@onready var astar_move: Node2D = $Components/AStarMove
@onready var face_direction: FaceDirection = $Components/FaceDirection
@onready var astar_marker: Marker = $Config/Marks/AstarMarker
@onready var animations: Animations = $Animations

#endregion

func _ready() -> void:
	EventBus.get_player_position.connect(_on_get_player_position)
	EventBus.change_player_position.connect(_on_change_player_position)
	EventBus.change_player_visible.connect(_on_change_player_visible)
	EventBus.player_face_left.connect(_on_player_face_left)
	#position=PlayerState.current_player_born_position
	start_position=get_position()
	state_manager.init(self)
	on_ready=true
	PlayerState.player_health_config = health.health_config
	PlayerState.player_stamina_config = stamina.stamina_config

func _unhandled_input(event: InputEvent) -> void:
	if !on_ready or event is InputEventMouseMotion:
		return 
	state_manager.input(event)

func _physics_process(delta: float) -> void:
	if !on_ready:
		return 
	is_player_interact_being_locked()
	is_player_on_fighting()
	state_manager.physics_process(delta)

func _process(delta: float) -> void:
	if !on_ready:
		return 
	state_manager.process(delta)

func _on_world_player_is_dead():
	player_is_dead()

func player_is_dead():
	if dead_switch:
		set_position(start_position)
	
func _on_change_player_visible()->void:
	self.hide()

func _on_change_player_position(player_position) -> void:
	self.global_position=player_position
	
func _on_get_player_position():
	return global_position
	
func _on_player_face_left(state) -> void:
	if state:
		base.scale.x = -abs(base.scale.x)
		hit_box.set_scale(Vector2(-1,1))
		PlayerState.face_left=true
	else:
		hit_box.set_scale(Vector2(1,1))
		base.scale.x = abs(base.scale.x)
		PlayerState.face_left=false

func get_dialogue_position():
	return dialogue_position.global_position

func _on_update_timer_timeout():
	PlayerState.player_global_position=global_position
	if ground_checker.is_colliding():
		PlayerState.current_height = ground_checker.get_collision_point().y - global_position.y

func is_player_interact_being_locked():
	if PlayerState.player_lock_interact_obj.is_empty():
		if PlayerState.player_interact_being_locked:
			PlayerState.enable_all_interactable()
			PlayerState.player_interact_being_locked=false
	else:
		if !PlayerState.player_interact_being_locked:	
			PlayerState.disable_all_interactable()
			PlayerState.player_interact_being_locked=true

func is_player_on_fighting():
	if PlayerState.player_on_fighting.is_empty():
		if PlayerState.is_player_on_fighting:
			PlayerState.is_player_on_fighting=false
	else:
		if !PlayerState.is_player_on_fighting:	
			PlayerState.is_player_on_fighting=true

func _on_tree_exiting() -> void:
	PlayerState.player_state_history.clear()
