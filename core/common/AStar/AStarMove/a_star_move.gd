@icon("res://core/common/AStar/AStarMove/astar_move.svg")
extends Node2D
var obj
var move = Vector2.ZERO
var on_ready:bool = false
var running:bool = false:
	set(f):
		running = f
		set_astar(f)
@export var target_offset_cell_vec2i:Vector2i
func on_master_ready(master):
	obj = master.obj
	on_ready = true

func set_astar(f):
	if obj.astar:
		obj.astar.enable = f
	
func  _physics_process(delta: float) -> void:
	if null==obj.current_cell or !on_ready or !running:
		return
	move = get_cell_move()
	if null!=move and move.x == 0 and obj.velocity.x == 0:
		if obj.astar.get_cell_data(obj.current_cell,"direction") in [Vector2i(0,1)]:
			Debug.dprintwarn(DebugCT.dp("[%s][%s]进行边缘移动补偿" %[obj.current_cell,obj.astar.cell_data_vec2i_dic[obj.current_cell]],self))
			move.x = -obj.face_left_normalized
	apply_gravity(delta)
	if move:
		if is_changing_direction(move):
			if obj.is_on_floor():
				apply_friction(move,delta)
			else :
				apply_friction_air(move,delta)
		else :
			if obj.is_on_floor():
				apply_acc(move,delta)
			else :
				apply_acc_air(move,delta)
		jump(delta)
	obj.set_up_direction(Vector2.UP)
	obj.move_and_slide()
	
func get_cell_move():
	return obj.astar.get_cell_data(obj.current_cell,"direction")
##重力		
func apply_gravity(delta):
	obj.velocity.y+=obj.gravity*delta
	obj.velocity.y=min(obj.velocity.y,obj.max_velocity_y)
func apply_acc(move,delta):
	obj.velocity.x+=obj.accelerate*delta*move.x
	obj.velocity.x=clampf(obj.velocity.x,-obj.max_chase_speed,obj.max_chase_speed)
func apply_acc_air(move,delta):
	obj.velocity.x+=obj.air_accelerate*delta*move.x
func apply_friction(move,delta):
	obj.velocity.x+=obj.fric2acc_scale*obj.accelerate*delta*move.x
	obj.velocity.x=min(obj.velocity.x,obj.max_chase_speed)
func apply_friction_air(move,delta):
	obj.velocity.x+=obj.air_fric2acc_scale*obj.air_accelerate*delta*move.x
	
func jump(delta):
	var d:bool = false
	if obj.current_cell == Vector2i(40,4):
		d= false
	if obj.is_on_floor():obj.velocity.y = 0
	var edge_jump_flag = obj.astar.get_cell_data(obj.current_cell,"is_edge") and obj.astar.get_cell_data(obj.current_cell,"direction")!=Vector2i(0,1) and obj.astar.is_blocked(obj.last_cell + Vector2i(0,1))
	if d:
		Debug.dprintinfo(DebugCT.dp("edge_jump_flag="+str(edge_jump_flag),self))
	var next_edge_cell
	if obj.is_on_floor() and obj.astar.get_cell_data(obj.current_cell,"direction") == Vector2i(0,-1) or edge_jump_flag :
		if d:
			Debug.dprintinfo(DebugCT.dp("起跳"+str(edge_jump_flag),self))
		next_edge_cell = obj.astar.get_next_edge_cell()
		if !next_edge_cell:return
		var c = obj.astar.get_cell_vec2i_by_node(self)
		var f = get_jump_force(c,next_edge_cell)
		obj.velocity.y-=f*delta
		obj.velocity.y=min(obj.velocity.y,-f)
		obj.astar.jump_try_times+=1
	if edge_jump_flag:
		if !next_edge_cell:return
		var c = obj.astar.get_cell_vec2i_by_node(self)
		var f = get_edge_jump_force(c,next_edge_cell)
		if d:
			Debug.dprintinfo(DebugCT.dp("前跳[%s]" %str(f),self))
		obj.velocity.x=f*move.x

func is_changing_direction(move):
	return move.x*obj.velocity.x<0
		
func get_jump_force(current_cell,next_edge_cell):
	var dis
	if  next_edge_cell.y > current_cell.y:
		dis = 0
	else :
		dis = abs(next_edge_cell.y-current_cell.y)
	return remap(dis,obj.jump_force_min_cell_y,obj.jump_force_max_cell_y,obj.jump_force_min_y,obj.jump_force_max_y)
		
func get_edge_jump_force(current_cell,next_edge_cell):
	var dis = abs(next_edge_cell.x-current_cell.x)
	return remap(dis,obj.jump_force_min_cell_x,obj.jump_force_max_cell_x,obj.jump_force_min_mid,obj.jump_force_max_mid)
