@icon("res://core/common/resource/icon/FSMState.svg")
extends Node
## NPC 状态机叶子/分组状态的基类。`*_state` 由 NpcStateManager.states 在 init 时注入。
class_name NpcsBaseState

@onready var fall_state: NpcsBaseState
@onready var lift_state: NpcsBaseState
@onready var idle_state: NpcsBaseState
@onready var chase_state: NpcsBaseState
@onready var patrol_state: NpcsBaseState
@onready var landing_state: NpcsBaseState
@onready var ground_state: NpcsBaseState
@onready var air_state: NpcsBaseState
@onready var interactive_state: NpcsBaseState
@onready var combat_state: NpcsBaseState
@onready var behit_state: NpcsBaseState
@onready var behithard_state: NpcsBaseState
@onready var talk_state: NpcsBaseState
@onready var attack0_state: NpcsBaseState
@onready var attack1_state: NpcsBaseState
@onready var attack2_state: NpcsBaseState
@onready var attack3_state: NpcsBaseState
@onready var toptrans_state: NpcsBaseState
@onready var behitbati_state: NpcsBaseState
@onready var staminaerror_state: NpcsBaseState
@onready var death_state: NpcsBaseState
@onready var dodge_state: NpcsBaseState
@onready var lock_state: NpcsBaseState
@onready var birth_state: NpcsBaseState
@onready var jump_state: NpcsBaseState
@onready var follow_state: NpcsBaseState
@onready var move2vec2_state: NpcsBaseState

@export_category("当前State配置")
@export_group("静态变量配置")
## 普通状态：临时状态结束后可以切回
@export var is_normal_state: bool = true
## 战斗状态（计入战斗历史，用于切回战斗相关状态）
@export var is_combat_state: bool = false
## 分组节点（base/combat/air/_attack/stack），不能被 change_state 进入
@export var is_group: bool = false
@export_group("动态变量配置")
## 进入本状态后，NPC 是否处于战斗模式
@export var on_combat: bool = false
## 进入本状态后，NPC 是否处于交战中
@export var on_fighting: bool = false
## 进入本状态后是否开启玩家探测区域
@export var enable_player_detection: bool
## 进入本状态后是否启用 NPC 自身碰撞/监测
@export var enable_self: bool
## 进入本状态后是否允许玩家对本 NPC 发起交互
@export var interact2player: bool = false
## 进入本状态后是否锁定玩家交互（加入玩家交互锁列表）
@export var player_interact_lock: bool
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
@export_range(0, 1, 0.1) var mix_modulate_strength: float = 0.5

@export_group("战斗")
## 进入本状态消耗的耐力
@export var stamina_cost: int
## 耐力不足时是否阻止进入/连段
@export var need_stamina: bool = false
@export_category("Anime")
## 本状态的动画配置（动画名、音效、HitBox 帧等）
@export var anime_config: AnimeConfig

var npc: Npcs
var move: int
var state_manager: NpcStateManager
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


func common_pre_enter() -> bool:
	return true


func init_var() -> void:
	pass


func load_var() -> void:
	pass


func enter() -> NpcsBaseState:
	return null


func common_enter() -> void:
	pass


func exit(_state: NpcsBaseState) -> void:
	pass


func common_exit() -> void:
	if anime_config == null:
		return
	for c in anime_config.sound_config:
		if c.stop_on_exit_state:
			state_manager.anime.stop_sound(c)
	for _hb in anime_config.hitbox_config:
		npc.hit_box.disable_shape()


func input(_event: InputEvent) -> NpcsBaseState:
	return null


func process(_delta: float) -> NpcsBaseState:
	return null


func physics_process(_delta: float) -> NpcsBaseState:
	return null


func pre_physics_process(_delta: float) -> NpcsBaseState:
	return null


func after_physics_process(_delta: float) -> NpcsBaseState:
	return null


func get_npc_move_direction_x() -> int:
	if npc.velocity.x > 0:
		return 1
	if npc.velocity.x == 0:
		return 0
	return -1


func get_npc_faced_direction() -> int:
	return -1 if npc.base.scale.x < 0 else 1


func apply_face_from_velocity() -> void:
	if npc.velocity.x > 0:
		npc.face_direction.set_faced(false)
	elif npc.velocity.x < 0:
		npc.face_direction.set_faced(true)


func get_airborne_state() -> NpcsBaseState:
	if npc.is_on_floor():
		return null
	if npc.velocity.y > 0:
		return fall_state
	if npc.velocity.y < 0:
		return lift_state
	return null


func get_land_state() -> NpcsBaseState:
	match npc.astar_mode:
		npc.ASTAR_MODE.FOLLOW:
			return follow_state
		npc.ASTAR_MODE.MOVE:
			return move2vec2_state
		npc.ASTAR_MODE.CHASE:
			return chase_state
	return chase_state


func is_npc_blocked() -> bool:
	var right = npc.get("block_checker_right")
	var left = npc.get("block_checker_left")
	if right and right.is_colliding():
		return true
	if left and left.is_colliding():
		return true
	return false


func play_animation() -> void:
	if is_group or _is_stacking():
		return
	if anime_config == null:
		return
	state_manager.anime.play_anime(anime_config.state_name)


func _is_stacking() -> bool:
	var script: Script = get_script()
	while script:
		if script.get_global_name() == &"NpcsStackingState":
			return true
		script = script.get_base_script()
	return false


func change_animation_color(flag: bool = false, p_pause: bool = true) -> void:
	if flag and p_pause:
		npc.anime.stop_anime()
	var mat = npc.base.material
	if mat == null:
		return
	mat.set_shader_parameter("overlay_color", sprite_color)
	mat.set_shader_parameter("overlay_strength", overlay_strength)
	mat.set_shader_parameter("overlay_mode", overlay_mode)
	mat.set_shader_parameter("mix_modulate", mix_modulate)
	mat.set_shader_parameter("mix_modulate_strength", mix_modulate_strength)
	mat.set_shader_parameter("overlay_enable", flag)


func is_animation_play() -> bool:
	return change_animation


func get_anime_config():
	if is_group:
		return null
	if anime_config:
		if anime_config.animation_name == "NA":
			anime_config.animation_name = self.name
		anime_config.has_animation = is_animation_play()
		anime_config.state_name = self.name
		for se in anime_config.sound_config:
			se.sound_obj_prefix = se.sound_obj_prefix + str(get_instance_id())
		return anime_config
	if _is_stacking():
		return null
	var cfg = AnimeConfig.new()
	cfg.animation_name = self.name
	cfg.state_name = self.name
	cfg.has_animation = is_animation_play()
	anime_config = cfg
	return cfg


func get_relative_position_x_2_player() -> int:
	return 1 if PlayerState.player_global_position.x >= npc.global_position.x else -1


func apply_gravity(delta) -> void:
	npc.velocity.y += npc.gravity * delta
	npc.velocity.y = min(npc.velocity.y, npc.max_velocity_y)


func apply_acc(p_move, delta) -> void:
	npc.velocity.x += npc.accelerate * delta * p_move.x
	npc.velocity.x = clampf(npc.velocity.x, -npc.max_chase_speed, npc.max_chase_speed)


func apply_acc_air(p_move, delta) -> void:
	npc.velocity.x += npc.air_accelerate * delta * p_move.x


func apply_friction(p_move, delta) -> void:
	npc.velocity.x += npc.fric2acc_scale * npc.accelerate * delta * p_move.x
	npc.velocity.x = min(npc.velocity.x, npc.max_chase_speed)


func apply_friction_air(p_move, delta) -> void:
	npc.velocity.x += npc.air_fric2acc_scale * npc.air_accelerate * delta * p_move.x


func get_cell_move():
	return npc.astar.get_cell_data(npc.current_cell, "direction")


func is_changing_direction(p_move) -> bool:
	return p_move.x * npc.velocity.x < 0
