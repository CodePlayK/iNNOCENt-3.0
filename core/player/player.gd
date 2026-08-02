##玩家控制对象
class_name Player extends CharacterBody2D
var obj_name:String = "player"
@export_category("配置")
@export_group("基础")
@export var talker_name:Array[String]
@export var dialogue_config:DialogueConfig
@export var character_box_config:CharacterBoxConfig:
	set(cb):
		character_box_config=cb
		if !cb.character_names:character_box_config.append(obj_name)
@export var create_character_box: bool=true

@export_group("运动")
@export var dead_switch: bool=true
##重力
@export_group("运动")
@export var gravity: int=800
##最大y速度
@export var max_velocity_y: int=800
##run加速度
@export var acceleration_run: int=400
@export var acceleration_dash: int=700
@export var max_speed_dash: int=700
##摩擦力
@export var friction: int=800
##最大run速度
@export var max_speed_run: int=200
##最大fastrun速度
@export var max_speed_fast_run: int=300
##最大walk速度
@export var max_speed_walk: int=100
##jump速度
@export var jump_speed: int=220
@export var climb_speed: int=120
@export var climb_speed_x: int=80
@export var click_jump_force_limit:=5
##最低跳跃速度
@export var min_jump_fource:=70
@export_group("AStar配置")
@export var astar:AStarMap
@export var max_chase_speed:float = 600
@export var accelerate:float = 2000
@export var fric2acc_scale:float = 10
@export var air_accelerate:float = 2000
@export var air_fric2acc_scale:float = 10
##
@export var jump_force_max_y:float  = 1000
@export var jump_force_max_cell_y:int = 8
@export var jump_force_min_y:float = 700
@export var jump_force_min_cell_y:int = 4
@export var jump_force_max_mid:float  = 1000
@export var jump_force_max_cell_x:int = 8
@export var jump_force_min_mid:float = 700
@export var jump_force_min_cell_x:int = 4
@export_group("战斗")
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

#endregion

func _ready() -> void:
	EventBus.get_player_position.connect(_on_get_player_position)
	EventBus.change_player_position.connect(_on_change_player_position)
	EventBus.change_player_visible.connect(_on_change_player_visible)
	EventBus.player_face_left.connect(_on_player_face_left)
	position=PlayerState.current_player_born_position
	start_position=get_position()
	state_manager.init(self)
	on_ready=true
	PlayerState.on_player_ready(self)
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
