extends NpcsCombatState
@export_category("巡逻配置")
@export var move_mode:MoveMode
##巡逻的范围,以左边为起点计算
@export var patrol_speed:float=150
##巡逻范围的随机系数
@export var patrol_speed_rand:Vector2=Vector2(.8,1.2)
##巡逻的范围,以左边为起点计算
@export var patrol_distance:float=150
##巡逻范围的随机系数
@export var patrol_distance_rand:Vector2=Vector2(.8,1.2)
##跑完一次巡逻距离的时间,以即单趟
@export var patrol_time:float=3
##巡逻时间的随机系数
@export var patrol_time_rand:Vector2=Vector2(.8,1.2)
##巡逻单趟后原地停止的时间
@export var wait_time:float=3
##巡逻单趟后原地停止时间的随机系数
@export var wait_time_rand:Vector2=Vector2(.8,1.2)

@onready var patrol_timer: Timer = $PatrolTimer
enum  MoveMode {
	BY_TIME,
	BY_SPEED
}
var patrol_distance_t:float
var patrol_time_t:float
var patrol_speed_t:float
var wait_time_t:float
var base_position:float = 0
var tween:Tween
var speed_map_2_animation
var face_direction: FaceDirection
var face_flag:bool
var real_target:Vector2


func init_var():
	speed_map_2_animation = npc.speed_map_2_animation
	face_direction = npc.face_direction
	
func enter():
	super.enter()
	npc.current_bot_y = npc.global_position.y
	var patrol_config = get_node_in_patrol_area(npc.patrol_area.patrol_list,npc)
	npc.current_patrol_right = patrol_config.patrol_right
	npc.current_patrol_left = patrol_config.patrol_left
	npc.current_bot_y = patrol_config.bot_y
	if !base_position:base_position=npc.get_position().x
	move2vector2()
	patrol_timer.start(patrol_time_t+wait_time_t)
	return
func debug():
	Debug.dprintwarn(DebugCT.dp("[%s]->[%s]" %[npc.global_position,real_target],self))

func rand():
	patrol_distance_t=patrol_distance*randf_range(patrol_distance_rand.x,patrol_distance_rand.y)
	patrol_time_t=patrol_time*randf_range(patrol_time_rand.x,patrol_time_rand.y)
	patrol_speed_t=patrol_time*randf_range(patrol_time_rand.x,patrol_time_rand.y)
	wait_time_t=wait_time*randf_range(wait_time_rand.x,wait_time_rand.y)
	
func get_real_target():
	var npc_pos_x = npc.global_position.x
	var rtx = clamp(randf_range(base_position -.5*patrol_distance_t,base_position +.5*patrol_distance_t),npc.current_patrol_left.global_position.x+.5*patrol_distance_t,npc.current_patrol_right.global_position.x-.5*patrol_distance_t)
	if npc_pos_x > rtx:
		face_flag = true
	else :
		face_flag = false
	real_target = Vector2(rtx,npc.global_position.y)
	
func physics_process(delta: float):
	if npc.player_detection.has_overlapping_bodies():
		return chase_state
	return await npc.patrol_weight_machine.process(self)
	
func exit(state:NpcsBaseState):
	patrol_timer.stop()
	npc.move_2_vec2.stop()
	npc.patrol_weight_machine.exit()
	speed_map_2_animation.set_enabel(self,false)
	if tween:
		tween.kill()

func _on_patrol_timer_timeout() -> void:
	if state_manager.current_state!=self:return
	move2vector2()
	
func move2vector2():
	rand()
	get_real_target()
	if move_mode == MoveMode.BY_SPEED:
		patrol_time_t = abs(real_target.x - npc.global_position.x) / patrol_speed
	speed_map_2_animation.set_enabel(self,true)	
	await npc.move_2_vec2.move_2_vec2(real_target,patrol_time_t)
	speed_map_2_animation.set_enabel(self,false)	

func get_node_in_patrol_area(patrol_list:Array[PatrolConfig],node):
	var fin_pc:PatrolConfig
	for patrol_config in patrol_list:
		if npc.global_position.x > patrol_config.patrol_left.global_position.x :
			if npc.global_position.x < patrol_config.patrol_right.global_position.x :
				if npc.current_bot_y<=patrol_config.bot_y and npc.current_bot_y>patrol_config.bot_y-50:		
					patrol_config.patrol_left.color = Color.ORANGE
					patrol_config.patrol_right.color = Color.ORANGE
					fin_pc = patrol_config
		else :
			patrol_config.patrol_left.color = Color.WHITE
			patrol_config.patrol_right.color = Color.WHITE
	return fin_pc
