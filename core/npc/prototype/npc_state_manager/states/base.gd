@icon("res://core/common/resource/icon/FSMState.svg")
extends Node
##Player状态机的base状态
class_name NpcsBaseState
#region import node
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
#endregion

@export_category("当前State配置")
@export_group("静态变量配置")
##当前state是否为普通state,即能够在hit或者dense等临时状态后切回
@export var is_normal_state:bool=true
##当前state是否为战斗状态
@export var is_combat_state:bool=false
@export_group("动态变量配置")
##当前state是否属于战斗状态(玩家不可与me交互)
@export var on_combat:bool = false
@export var on_fighting:bool = false
##当前state启用npc的对player检测,比如寻敌
@export var enable_player_detection:bool
##当前state启用npc自身的检测
@export var enable_self:bool
##当前state是否能与玩家交互		
@export var interact2player:bool = false
##当前state是否锁定player与可交互obj的交互		
@export var player_interact_lock:bool
@export_group("动画")
##当前状态是否要转换sprite
@export var change_animation:bool=true
##当前状态是否要颜色覆盖sprite
@export var change_sprite_color:bool=false
@export var pause_on_change_sprite_color:bool=true
##要覆盖sprite的颜色
@export var sprite_color:Color
##0 = 不叠，1 = 完全按 overlay 方式混合
@export_range(0,1,0.1) var overlay_strength:float = 0.1
enum OVERLAYER_MODES{MULTIPLY = 0,MIX= 1 ,SOFT = 2}
##0 multiply  1 mix插值  2 soft 偏亮叠加
@export var overlay_mode:OVERLAYER_MODES = OVERLAYER_MODES.SOFT
##混合原modulate
@export var mix_modulate:bool = true;
@export_range(0,1,0.1) var mix_modulate_strength:float = 0.5


@export_group("战斗")
@export var stamina_cost:int
@export var need_stamina:bool = false
@export_category("Anime")
@export var anime_config:AnimeConfig

##将要赋予的角色
var npc: Npcs
var move:int
var state_manager:NpcStateManager
var anime:Anime

##初始化事件
func init(all_states) -> void:
	var property_list:Array[Dictionary] = self.get_script().get_script_property_list()
	for state in all_states:
		for p in property_list:
			if p.name==(state.name+"_state"):
				set(p.name,state)
				
##进入该状态的方法，每次进入都会执行，在pre_physics_process之前进行
func pre_enter() -> bool:
	return true
func common_pre_enter() -> bool:
	return true
	#return need_stamina and PlayerState.stamina>0
	
##在init之后执行的方法,只会在初始化时执行一次,适用于state的静态标记变量	
func init_var():
	pass
##在pre_enter之后在enter之前的方法,每次进入都会重新赋值,适用于state切换时的动态标记变量
func load_var():
	pass
	
##进入该状态的方法，每次进入都会执行，在pre_physics_process之前进行
func enter() -> NpcsBaseState:
	return null
	
func common_enter():
	return
	PlayerState.damage_stamina(stamina_cost)
	
#退出该状态的方法，每次进入都会执行，在physics_process之后进行
func exit(state:NpcsBaseState):
	pass
	
##通用退出方法,在exit()在之后
func common_exit():
	if anime_config:
		for c in anime_config.sound_config:
			if c.stop_on_exit_state:#将所有需要在退出状态时停止的音效停止
				state_manager.anime.stop_sound(c)
		for hb in anime_config.hitbox_config:#将所有hitbox在退出状态时失效
				npc.hit_box.disable_shape()

#有输入事件的方法,不确定与物理帧方法的顺序。慎用
func input(event: InputEvent) -> NpcsBaseState:
	return null

#游戏实际帧数的处理方法，godot默认物理帧FPS为60
#当游戏运行帧数大于物理帧FPS时：可通过传递delta获得与物理帧数同样效果
#而运行帧数小于物理帧数时，即使传递delta也可能导致问题
#运行顺序不确定
func process(delta: float) -> NpcsBaseState:
	return null
	
##物理帧方法，当变量涉及+=或者-+等随时间累计情况时，需要*delta
func physics_process(delta: float) -> NpcsBaseState:
	return
	
##物理帧中先执行的方法
func pre_physics_process(delta: float)->NpcsBaseState:
	return null
	
##物理帧中后执行的方法	
func after_physics_process(delta: float)->NpcsBaseState:
	return null
	
func get_npc_move_direction_x()->int:
		if  npc.velocity.x>0:
			return 1
		elif npc.velocity.x==0:
			return 0
		else :
			return -1
##获取npc当前面朝方向
func get_npc_faced_direction():
	if npc.base.scale.x <0:
		return -1
	else:
		return 1
				
func is_npc_blocked()->bool:
	if npc.block_checker_right.is_colliding() or npc.block_checker_right.is_colliding():
		return true
	return false
	
func play_animation():
	if !self is NpcsStackingState:
		state_manager.anime.play_anime(anime_config.state_name)

func change_animation_color(flag:bool=false,pause_on_change_sprite_color:bool = true):
	npc.base.material.set_shader_parameter("overlay_color",sprite_color)
	npc.base.material.set_shader_parameter("overlay_strength",overlay_strength)
	npc.base.material.set_shader_parameter("overlay_mode",overlay_mode)
	npc.base.material.set_shader_parameter("mix_modulate",mix_modulate)
	npc.base.material.set_shader_parameter("mix_modulate_strength",mix_modulate_strength)
	npc.base.material.set_shader_parameter("overlay_enable",flag)
	if flag and pause_on_change_sprite_color:
		npc.anime.stop_anime()
		
func is_animation_play()-> bool:
	return change_animation
	
##组装每一个state的anime配置
func get_anime_config():
	if anime_config:
		if anime_config.animation_name=="NA":
			anime_config.animation_name = self.name
		anime_config.has_animation = is_animation_play()
		anime_config.state_name = self.name
		for se in anime_config.sound_config:
			se.sound_obj_prefix = se.sound_obj_prefix+str(get_instance_id())
		return anime_config
	if self is NpcsStackingState:return
	var anime = AnimeConfig.new()
	anime.animation_name = self.name
	anime.state_name = self.name
	anime.has_animation = is_animation_play()
	anime_config = anime
	return anime
	
##判断玩家与当前npc的相对左右位置,右=1,左=-1	
func get_relative_position_x_2_player()->int:
	if PlayerState.player_global_position.x>=npc.global_position.x:
		return 1
	else:
		return -1

##重力		
func apply_gravity(delta):
	npc.velocity.y+=npc.gravity*delta
	npc.velocity.y=min(npc.velocity.y,npc.max_velocity_y)
func apply_acc(move,delta):
	npc.velocity.x+=npc.accelerate*delta*move.x
	npc.velocity.x=clampf(npc.velocity.x,-npc.max_chase_speed,npc.max_chase_speed)
func apply_acc_air(move,delta):
	npc.velocity.x+=npc.air_accelerate*delta*move.x
func apply_friction(move,delta):
	npc.velocity.x+=npc.fric2acc_scale*npc.accelerate*delta*move.x
	npc.velocity.x=min(npc.velocity.x,npc.max_chase_speed)
func apply_friction_air(move,delta):
	npc.velocity.x+=npc.air_fric2acc_scale*npc.air_accelerate*delta*move.x

func get_cell_move():
	return npc.astar.get_cell_data(npc.current_cell,"direction")

func is_changing_direction(move):
	return move.x*npc.velocity.x<0
