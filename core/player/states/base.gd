@icon("res://core/common/resource/icon/FSMState.svg")
extends Node
##Player状态机的base状态
class_name BaseState

@export_category("基础配置")
@export_group("状态配置")
##是否为普通状态（普通状态会进入状态历史）
@export var is_normal_state:bool = true
##状态名（用于动画等）
@export var state_name:String
@export_group("体力配置")
@export var need_stamina:bool = false
@export var stamina_cost:float = 0.0
@export_group("Debug")
@export var debug_print:bool = false

@onready var state_manager: StateManager = get_parent()
@onready var player: Player = state_manager.player
@onready var anime: Anime = state_manager.anime
@onready var stamina_config: StaminaConfig = PlayerState.player_stamina_config

##运动输入
var move:int = 0

##子状态引用（在 StateManager 中统一赋值）
var idle_state:BaseState
var walk_state:BaseState
var run_state:BaseState
var fastrun_state:BaseState
var jump_state:BaseState
var lift_state:BaseState
var fall_state:BaseState
var dash_state:BaseState
var dense_state:BaseState
var light_state:BaseState
var attack0_state:BaseState
var attack1_state:BaseState
var attack2_state:BaseState
var attack3_state:BaseState
var behit_state:BaseState
var behitDamaged_state:BaseState
var behitDenseSafed_state:BaseState
var behitbati_state:BaseState
var lock_state:BaseState
var staminaerror_state:BaseState
var combat_state:BaseState

func _ready() -> void:
	if not state_name:
		state_name = name

func get_anime_config():
	return null

func common_pre_enter() -> bool:
	return true

func pre_enter() -> bool:
	return true

func common_enter() -> void:
	pass

func enter() -> BaseState:
	play_animation()
	return null

func common_exit() -> void:
	pass

func exit(state:BaseState) -> void:
	pass

func input(event: InputEvent) -> BaseState:
	return null

func physics_process(delta: float) -> BaseState:
	return null

func after_physics_process(delta: float) -> BaseState:
	return null

func player_faced(move_dir:int) -> void:
	if move_dir == 0:
		return
	if move_dir > 0:
		PlayerState.face_left = false
	else:
		PlayerState.face_left = true

func apply_gravity(delta: float) -> void:
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

func apply_friction(delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)

func apply_acceleration_walk(move_dir:int, delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, move_dir * player.walk_speed, player.acceleration * delta)

func apply_acceleration_run(move_dir:int, delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, move_dir * player.run_speed, player.acceleration * delta)

func apply_acceleration_fastrun(move_dir:int, delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, move_dir * player.fastrun_speed, player.acceleration * delta)

func apply_acceleration_custom(move_dir:int, scale:float, delta: float) -> void:
	player.velocity.x = move_toward(player.velocity.x, move_dir * player.walk_speed * scale, player.acceleration * delta)

func min_jump_force(velocity:Vector2,delta)->Vector2:
	if velocity.y<-player.min_jump_fource and velocity.y<0 and Input.is_action_just_released("jump"):
		velocity.y=-player.jump_speed/player.click_jump_force_limit
	return velocity
	
func get_movement_input_x() -> int:
	# 全局禁止玩法输入时，移动轴恒为 0（仍可在状态里处理交互）
	if not PlayerState.can_use_gameplay_input():
		return 0
	var a = Input.get_axis("move_left", "move_right")
	if a == 0:
		return 0
	elif a > 0:
		return 1
	else:
		return -1
		
func is_player_change_moving_direction()->bool:
	if Input.is_action_pressed("move_left") and player.velocity.x>0:
		return true
	if Input.is_action_pressed("move_right") and player.velocity.x<0:
		return true
	return false
	
func get_palyer_move_direction_x()->int:
		if  player.velocity.x>0:
			return 1
		elif player.velocity.x==0:
			return 0
		else :
			return -1
		
func is_player_blocked()->bool:
	if player.block_checker_right.is_colliding() or player.block_checker_right.is_colliding():
		return true
	return false
	
func play_animation():
	if !self is StackingState:
		player.anime.play_anime(anime_config.state_name)
