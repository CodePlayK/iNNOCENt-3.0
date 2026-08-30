@icon("res://core/common/resource/icon/FSMState.svg")
extends Node
## Player 状态机叶子/分组状态的基类。
## `*_state` 由 PlayerStateManager.states 在 init 时注入。
class_name BaseState

@onready var jump_state: BaseState
@onready var walk_state: BaseState
@onready var run_state: BaseState
@onready var dash_state: BaseState
@onready var climb_state: BaseState
@onready var fall_state: BaseState
@onready var lift_state: BaseState
@onready var idle_state: BaseState
@onready var lock_state: BaseState
@onready var double_jump_state: BaseState
@onready var landing_state: BaseState
@onready var ground_state: BaseState
@onready var air_state: BaseState
@onready var interactive_state: BaseState
@onready var dense_state: BaseState
@onready var combat_state: BaseState
@onready var behit_state: BaseState
@onready var behitDenseSafed_state: BaseState
@onready var behitDamaged_state: BaseState
@onready var light_state: BaseState
@onready var talk_state: BaseState
@onready var fastrun_state: BaseState
@onready var attack0_state: BaseState
@onready var attack1_state: BaseState
@onready var attack2_state: BaseState
@onready var attack3_state: BaseState
@onready var toptrans_state: BaseState
@onready var behitbati_state: BaseState
@onready var staminaerror_state: BaseState
@onready var wake_state: BaseState
@onready var onfloor_state: BaseState

## 普通状态：临时状态（攻击/受击等）结束后可以切回
@export var is_normal_state: bool = true
## 分组节点（base/combat/air/_attack/stack），不能被 change_state 进入
@export var is_group: bool = false

@export_group("动画")
## 进入本状态时是否切换动画
@export var change_animation: bool = true
## 进入本状态时是否给 sprite 叠加着色
@export var change_sprite_color: bool = false
## 叠加着色时是否暂停当前动画
@export var pause_on_change_sprite_color: bool = true
## 叠加到 sprite 上的颜色
@export var sprite_color: Color
## shader overlay 颜色强度（0~1）
@export_range(0, 1, 0.1) var overlay_strength: float = 0.1
enum OVERLAYER_MODES { MULTIPLY = 0, MIX = 1, SOFT = 2 }
## overlay 与原图的混合模式
@export var overlay_mode: OVERLAYER_MODES = OVERLAYER_MODES.SOFT
## 是否把 sprite 的 modulate 混入 overlay
@export var mix_modulate: bool = true
## modulate 混入 overlay 的强度（0~1）
@export_range(0, 1, 0.1) var mix_modulate_strength: float = 1.0

@export_group("战斗")
var health_config: HealthConfig
var stamina_config: StaminaConfig
## 进入本状态消耗的耐力
@export var stamina_cost: int
## 耐力不足时是否阻止进入/连段
@export var need_stamina: bool = false

@export_category("Anime")
## 本状态的动画配置（动画名、音效、HitBox 帧等）
@export var anime_config: AnimeConfig

var player: Player
var move: int
var state_manager: PlayerStateManager
var anime: Anime


func init(_all_states) -> void:
	if state_manager == null:
		return
	for key in state_manager.states:
		var prop := "%s_state" % key
		if prop in self:
			set(prop, state_manager.states[key])


func pre_enter() -> bool:
	return true

func pre_animation() -> BaseState:
	return null
	
func common_pre_enter() -> bool:
	return true


func init_var() -> void:
	pass


func load_var() -> void:
	pass


func enter() -> BaseState:
	return null


func common_enter() -> void:
	player.stamina.damage_stamina(stamina_cost)
	if change_sprite_color and pause_on_change_sprite_color:
		player.anime.pause_anime()


func exit(_state: BaseState) -> void:
	pass


func common_exit() -> void:
	if anime_config:
		for c in anime_config.sound_config:
			if c.stop_on_exit_state:
				state_manager.anime.stop_sound(c)
		for hb in anime_config.hitbox_config:
			player.hit_box.disable_shape()


func input(_event: InputEvent) -> BaseState:
	return null


func process(_delta: float) -> BaseState:
	return null


func physics_process(_delta: float) -> BaseState:
	return null


func pre_physics_process(_delta: float) -> BaseState:
	return null


func after_physics_process(_delta: float) -> BaseState:
	return null


func player_faced(moves) -> void:
	move = moves
	if moves > 0:
		player.face_direction.set_faced(false)
	elif moves < 0:
		player.face_direction.set_faced(true)


func apply_gravity(delta) -> void:
	player.velocity.y += player.gravity * delta
	player.velocity.y = min(player.velocity.y, player.max_velocity_y)


func apply_friction(delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, 0, player.friction * delta)


func apply_acceleration_run(v, delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.max_speed_run * v, player.acceleration_run * delta)


func apply_acceleration_walk(v, delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.max_speed_walk * v, player.acceleration_run * delta)


func apply_acceleration_custom(v, scale_to_walk, delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.max_speed_walk * v * scale_to_walk, player.acceleration_run * delta)


func apply_acceleration_fastrun(v, delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.max_speed_fast_run * v, player.acceleration_run * delta)


func apply_acceleration_dash(v, delta) -> void:
	player.velocity.x = move_toward(player.velocity.x, player.max_speed_dash * v, player.acceleration_dash * delta)


func apply_horizontal(delta: float, accel: Callable) -> void:
	if move == 0 or is_player_change_moving_direction():
		apply_friction(delta)
	else:
		accel.call(move, delta)


func move_player() -> bool:
	if not is_instance_valid(player) or player.get_world_2d() == null or not is_inside_tree():
		return false
	player.set_up_direction(Vector2.UP)
	player.move_and_slide()
	return true


func get_airborne_state() -> BaseState:
	if player.is_on_floor():
		return null
	return lift_state if player.velocity.y <= 0 else fall_state


func min_jump_force(velocity: Vector2, _delta) -> Vector2:
	if velocity.y < -player.min_jump_fource and velocity.y < 0 and Input.is_action_just_released("jump"):
		velocity.y = -player.jump_speed / player.click_jump_force_limit
	return velocity


func get_movement_input_x() -> int:
	var a := Input.get_axis("move_left", "move_right")
	if a == 0:
		return 0
	return 1 if a > 0 else -1


func is_player_change_moving_direction() -> bool:
	if Input.is_action_pressed("move_left") and player.velocity.x > 0:
		return true
	if Input.is_action_pressed("move_right") and player.velocity.x < 0:
		return true
	return false


func get_player_move_direction_x() -> int:
	if player.velocity.x > 0:
		return 1
	if player.velocity.x == 0:
		return 0
	return -1


func get_palyer_move_direction_x() -> int:
	return get_player_move_direction_x()


func is_player_blocked() -> bool:
	if move > 0:
		return player.block_checker_right.is_colliding()
	if move < 0:
		return player.block_checker_left.is_colliding()
	return false


func play_animation() -> void:
	if _is_stacking():
		return
	if anime_config == null:
		return
	player.anime.play_anime(self.name)


func _is_stacking() -> bool:
	var script: Script = get_script()
	while script:
		if script.get_global_name() == &"StackingState":
			return true
		script = script.get_base_script()
	return false


func change_animation_color(flag: bool = false, _pause_on_change: bool = true) -> void:
	player.base.material.set_shader_parameter("overlay_color", sprite_color)
	player.base.material.set_shader_parameter("overlay_strength", overlay_strength)
	player.base.material.set_shader_parameter("overlay_mode", overlay_mode)
	player.base.material.set_shader_parameter("mix_modulate", mix_modulate)
	player.base.material.set_shader_parameter("mix_modulate_strength", mix_modulate_strength)
	player.base.material.set_shader_parameter("overlay_enable", flag)


func is_animation_play() -> bool:
	return change_animation


func get_anime_config():
	if is_group:
		return null
	if anime_config:
		if not anime_config.resource_local_to_scene:
			anime_config = anime_config.duplicate(true)
			anime_config.resource_local_to_scene = true
		if anime_config.animation_name == "NA":
			anime_config.animation_name = self.name
		anime_config.has_animation = is_animation_play()
		anime_config.state_name = self.name
		for se in anime_config.sound_config:
			se.sound_obj_prefix = se.sound_obj_prefix + str(get_instance_id())
		return anime_config
	if _is_stacking():
		return
	var cfg := AnimeConfig.new()
	cfg.animation_name = self.name
	cfg.state_name = self.name
	if player and player.aniplayer and player.aniplayer.has_animation(self.name):
		var clip := player.aniplayer.get_animation(self.name)
		cfg.loop = clip.loop_mode != Animation.LOOP_NONE
	anime_config = cfg
	return anime_config
