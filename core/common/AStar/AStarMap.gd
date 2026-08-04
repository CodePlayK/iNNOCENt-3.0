@icon("res://core/common/AStar/astar.svg")
extends Node2D
class_name AStarMap
@onready var updata_timer: Timer = $UpdataTimer
@onready var prop: Node2D = $Prop
@onready var end_mark: Node2D = $EndMark
@export var astar_range: CollisionShape2D
@export_group("是否启用UI")
##寻路基于的tilemap,需要在customer data中配置block字段表示障碍物
@export var enabel_ui:bool = true:
	set(f):
		enabel_ui = f
		update_ui_visible()
@export_group("基础配置")
@export var enable:bool = false:
	set(f):
		if !f:
			for p in path_array:
				set_cell_data(p,DIRECTION,Vector2i(0,0))
		enable = f		
@export var only_update_on_floor:bool = false
@export var base_tile:TileMap
##寻路对象
@export var npc:CharacterBody2D
##寻路跟随目标
@export var target:Node2D
@export var target_offset_cell_vec2i:Vector2i
##当cell不在地面上时,额外的cost
@export_range(0,10) var air_cost:float = 1
var base_air_cost:float
##跳跃未达到目标高度的次数达到x时,修改取消air_cost修正,并在次数达到y时重新启用修正,同时重置跳跃次数
@export var jump_try_time_range:Vector2i = Vector2i(1,4)
@export_group("UI颜色配置")
##边界颜色
@export var frontier_color:Color = Color.GREEN
##路径颜色
@export var path_color:Color = Color.YELLOW
##平台边缘cell的颜色
@export var edge_color:Color = Color.DEEP_PINK
##npc所在的cell的颜色
@export var npc_on_cell_color:Color =Color.AQUA
##目标所在的颜色
@export var target_on_cell_color:Color =Color.AQUA
##cell_prop_pos_dic
var cell_prop_pos_dic:Dictionary
##prop_dic_vec2i
var cell_prop_vec2i_dic:Dictionary
##cell数据
var cell_data_pos_dic:Dictionary
##cell数据
var cell_data_vec2i_dic:Dictionary
##将prop初始化到网格
var base_cell_vec2i_set:Dictionary
var npc_current_cell:Vector2i
var npc_current_cell_pos:Vector2
var last_npc_current_cell:Vector2i
var last_npc_current_cell_pos:Vector2
var target_current_cell:Vector2i
var target_current_cell_pos:Vector2
var last_target_current_cell:Vector2i
var last_target_current_cell_pos:Vector2
var check_ok:bool = false
##算法
##记录路径的dictionary,{当前cell,上一个cell}
var came_from:Dictionary
##每一个cell当前的cost
var cost_so_far:Dictionary
##边疆list
var frontier:Array
##记录path的array
var path_array:Array
##npc试图跳跃到当前目标y高度的次数
var jump_try_times:int
##当前跳跃的目标
var current_jump_target:Vector2i
var left_x 
var right_x
var bot_y 
var top_y 
var target_is_vec2:bool = false
var target_vec2:Vector2
const IS_EDGE = "is_edge"
const BLOACKED = "blocked"
const DIRECTION = "direction"

func _ready() -> void:
	position = Vector2.ZERO
	get_astar_range()
	get_cell_prop(get_cell_vec2i_by_pos(astar_range.global_position))
	base_air_cost = air_cost
	updata_timer.start()
	check()

func start_astar(target_node:Node2D = target):
	enable = true

##更新事件
func on_update():
	if !enable or !check_ok:return
	target_pos_update(target.global_position)
	npc_pos_update(npc.astar_marker.global_position)
	run(npc_current_cell,target_current_cell)
	
##执行寻路
func run(start_cell:Vector2i,end_cell:Vector2i):
	if last_npc_current_cell==start_cell and last_target_current_cell == end_cell:
		return
	if !cell_data_vec2i_dic.has(start_cell) or !cell_data_vec2i_dic.has(end_cell):
		return
	reset()
	frontier.push_back([start_cell,0])
	while !frontier.is_empty():
		var current = frontier.pop_back()[0]
		if current == end_cell:
			break
		process(current,end_cell)
	draw_path(start_cell,end_cell)
	update_arror()
	color_start_end(start_cell,end_cell)
	
##计算路径
func process(current:Vector2i,end_cell:Vector2i):
	var sur_cells = base_tile.get_surrounding_cells(current)
	for next in sur_cells:
		var new_cost
		if cost_so_far.has(current):
			new_cost= cost_so_far[current]+1
			if !is_blocked(current+Vector2i(0,1)):##如果该cell的下方cell不为地面,则额外加上air_cost让路径尽量保持在地面
				new_cost= new_cost+air_cost
		else :
			new_cost=1
		if !cost_so_far.has(next) or new_cost < cost_so_far[next]:
			if is_blocked(next):##如果是障碍cell则跳过
				continue
			cost_so_far[next] = new_cost
			add_to_frontier(next,get_manhattan_cost(next,end_cell)+new_cost)
			set_data(next)
			colored_cell(next,frontier_color)
			came_from[next] = current
##配置cell的数据
func set_data(cell_vec2i:Vector2i):
	var bot_cell = cell_vec2i+Vector2i(0,1)
	var bot_cell_blocked = is_blocked(bot_cell)
	var left_cell = cell_vec2i+Vector2i(-1,1)
	var left_cell_blocked = is_blocked(left_cell)
	var right_cell = cell_vec2i+Vector2i(1,1)
	var right_cell_blocked = is_blocked(right_cell)
	if (left_cell_blocked or right_cell_blocked) and !bot_cell_blocked:
		var left_mid_cell = cell_vec2i+Vector2i(-1,0)
		var left_mid_cell_blocked = is_blocked(left_mid_cell)
		var right_mid_cell = cell_vec2i+Vector2i(1,0)
		var right_mid_cell_blocked = is_blocked(right_mid_cell)
		if (left_cell_blocked and !left_mid_cell_blocked) or (right_cell_blocked and !right_mid_cell_blocked):
			set_cell_data(cell_vec2i,IS_EDGE,true)
			colored_cell(cell_vec2i,edge_color)
			return
	set_cell_data(cell_vec2i,IS_EDGE,false)
##从终点反向从came_from中获取最终路径
func draw_path(start_cell:Vector2i,end_cell:Vector2i):
	var current_cell = end_cell
	while current_cell!=start_cell:
		path_array.push_back(current_cell)
		if !came_from.has(current_cell):break
		current_cell = came_from[current_cell]
		colored_cell(current_cell,path_color)
		if get_cell_data(current_cell,IS_EDGE):
			if enabel_ui:cell_prop_vec2i_dic[current_cell][3].color = edge_color
		else :
			if enabel_ui:cell_prop_vec2i_dic[current_cell][3].color = Color.TRANSPARENT
	path_array.push_back(start_cell)
##以	cell_vec2i为起点在屏幕上建立
func get_cell_prop(cell_vec2i:Vector2i):
	if !base_cell_vec2i_set.has(cell_vec2i):
		create_prop_by_cell_vec2i(cell_vec2i)
	base_cell_vec2i_set[cell_vec2i] = null
	var cell_list = base_tile.get_surrounding_cells(cell_vec2i)
	var next_cells:Array
	for cell in cell_list:
		if base_cell_vec2i_set.has(cell):
			continue
		var cell_pos = base_tile.to_global(base_tile.map_to_local(cell))
		if is_in_range(cell_pos):
			next_cells.append(cell)
		else :
			pass
	if next_cells:
		for cell in next_cells:
			get_cell_prop(cell)	
			
#region 通用方法
##获取节点当前所处的cell的中心Vec2		
func get_cell_center_pos_by_node(node:Node2D):
	return base_tile.to_global(base_tile.map_to_local(get_cell_vec2i_by_node(node)))
##获取位置当前所处的cell的中心Vec2	
func get_cell_center_pos_by_pos(pos:Vector2):
	return base_tile.to_global(base_tile.map_to_local(get_cell_vec2i_by_pos(pos)))
func get_cell_center_pos_by_vec2i(vec2i:Vector2i):
	return base_tile.to_global(base_tile.map_to_local(vec2i))
##获取节点当前所处的cell的中心Vec2i
func get_cell_vec2i_by_node(node:Node2D):
	return base_tile.local_to_map(base_tile.to_local(node.global_position))
##获取位置当前所处的cell的中心Vec2i
func get_cell_vec2i_by_pos(pos:Vector2):
	return base_tile.local_to_map(base_tile.to_local(pos))
##获取节点当前所处的cell的TileData
func get_cell_data_by_node(node:Node2D,layer_index:int = 0):
	return base_tile.get_cell_tile_data(layer_index,get_cell_vec2i_by_node(node))
##获取节点当前所处的cell的customer data
func get_cell_custom_data_by_node(node:Node2D,layer_index:int,data_name:String):
	return get_cell_data_by_node(node,layer_index).get_custom_data(data_name)
#endregion

##在cell中创建prop
func create_prop_by_cell_vec2i(cell_vec2i):
	var pos = get_cell_center_pos_by_vec2i(cell_vec2i)
	cell_data_pos_dic[pos] = {}
	cell_data_vec2i_dic[cell_vec2i] = {}
	var prop = prop.duplicate()
	add_child(prop)
	prop.global_position = pos
	prop.get_node("CellVec2iLabel").text = str(cell_vec2i)
	if enabel_ui:prop.show()
	cell_prop_pos_dic[pos] = [prop,prop.get_node("CellVec2iLabel"),prop.get_node("BackPanel"),prop.get_node("EdgeMark"),prop.get_node("Arror")]		
	cell_prop_vec2i_dic[cell_vec2i] = cell_prop_pos_dic[pos]		
	
func _on_updata_timer_timeout() -> void:
	target_pos_update(target.global_position)
	if !enable:return
	on_update()
	
##运行前检查
func check():
	if !base_tile:
		var p = get_parent()
		if p is TileMap:
			base_tile = p
		else :
			push_error("base_tile配置异常!")
			check_ok = false
			return
	if !npc:
		push_error("npc配置异常!")
		check_ok = false
		return
	if !target:
		push_error("未配置目标!")
		end_mark.global_position = get_near_none_bloack_cell(get_viewport().get_camera_2d().get_target_position())
		end_mark.modulate = target_on_cell_color
		target = end_mark
	else:
		end_mark.hide()
	check_ok = true
##重置	
func reset():
	clear_color()
	came_from = {}
	cost_so_far = {}
	frontier.clear()
	path_array.clear()
##重置颜色
func clear_color():
	if !enabel_ui:return
	for k in cell_prop_pos_dic.keys():
		cell_prop_pos_dic[k][2].self_modulate = Color.WHITE
		cell_prop_pos_dic[k][3].color = Color.TRANSPARENT
		cell_prop_pos_dic[k][4].hide()
##是否为障碍物		
func is_blocked(cell_vec2i):
	var data = base_tile.get_cell_tile_data(0,cell_vec2i)
	if data:
		var block = data.get_custom_data(BLOACKED)
		return true
	return false
##获取曼哈顿距离
func get_manhattan_cost(current_cell:Vector2i,end_cell:Vector2i):
	return abs(end_cell.x - current_cell.x) + abs(end_cell.y - current_cell.y) 
##获取当前target与start间的曼哈顿距离
func get_manhattan_distance():
	target_pos_update(target.global_position)
	npc_pos_update(npc.astar_marker.global_position)
	return get_manhattan_cost(npc_current_cell,target_offset_cell_vec2i)
##加入到边疆
func add_to_frontier(cell:Vector2i,cost):
	frontier.push_back([cell,cost])
	frontier.sort_custom(sort_by_cost)
##根据cost排序	
func sort_by_cost(a,b):
	if a[1] > b[1]:
		return true
	return false
##设置cell数据	
func set_cell_data(cell_vec2i:Vector2i,data_name:String,value):
	if cell_data_vec2i_dic.has(cell_vec2i):
		cell_data_vec2i_dic[cell_vec2i][data_name] = value
##获取cell数据
func get_cell_data(cell_vec2i:Vector2i,data_name:String):
	if !cell_data_vec2i_dic.has(cell_vec2i):return
	if cell_data_vec2i_dic[cell_vec2i].has(data_name):
		return cell_data_vec2i_dic[cell_vec2i][data_name]
##染色cell
func colored_cell(cell_vec2i:Vector2i,color):
	if !enabel_ui:return
	if cell_prop_vec2i_dic.has(cell_vec2i):
		cell_prop_vec2i_dic[cell_vec2i][2].self_modulate = color
##更新箭头
func update_arror():
	for i in path_array.size():
		if i == 0:
			set_arror_dirction(path_array[0],Vector2i(0,0))
		else :
			set_arror_dirction(path_array[i],(path_array[i-1] -path_array[i]))
##配置箭头方向
func set_arror_dirction(cell_vec2i,vec2i:Vector2i):
	if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].show()
	if vec2i == Vector2i(0,1):
		if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].rotation_degrees = 0
		set_cell_data(cell_vec2i,DIRECTION,Vector2i(0,1))
	elif vec2i == Vector2i(-1,0):
		if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].rotation_degrees = 90
		set_cell_data(cell_vec2i,DIRECTION,Vector2i(-1,0))
	elif vec2i == Vector2i(0,-1):
		if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].rotation_degrees = 180
		set_cell_data(cell_vec2i,DIRECTION,Vector2i(0,-1))
	elif vec2i == Vector2i(1,0):
		if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].rotation_degrees = 270
		set_cell_data(cell_vec2i,DIRECTION,Vector2i(1,0))
	elif vec2i == Vector2i(0,0):
		if enabel_ui:cell_prop_vec2i_dic[cell_vec2i][4].rotation_degrees = 0
		set_cell_data(cell_vec2i,DIRECTION,Vector2i(0,0))
##染色起终点	
func color_start_end(start_cell,end_cell):
	if !enabel_ui:return
	colored_cell(start_cell,npc_on_cell_color)
	colored_cell(end_cell,target_on_cell_color)
##npc位置更新
func npc_pos_update(pos:Vector2):
	var cell_pos = get_cell_center_pos_by_pos(pos)
	if last_npc_current_cell_pos == cell_pos:return
	if cell_data_pos_dic.has(cell_pos):
		last_npc_current_cell_pos = npc_current_cell_pos
		last_npc_current_cell = npc_current_cell
		var cell_vec2i = get_cell_vec2i_by_pos(pos)
		var data = base_tile.get_cell_tile_data(0,cell_vec2i)
		if data:
			var block = data.get_custom_data(BLOACKED)
			return
		if enabel_ui:cell_prop_pos_dic[cell_pos][2].self_modulate = npc_on_cell_color
		npc_current_cell = cell_vec2i
		npc_current_cell_pos = pos
		if 	npc.current_cell != npc_current_cell:
			npc.current_cell = npc_current_cell
		if jump_try_times>0 and npc_current_cell.y == current_jump_target.y:
			jump_try_times = 0
			air_cost = base_air_cost
		if cell_prop_pos_dic.has(last_npc_current_cell_pos):
			if enabel_ui:cell_prop_pos_dic[last_npc_current_cell_pos][2].self_modulate = Color.WHITE
##目标位置更新
func target_pos_update(pos:Vector2):
	if !PlayerState.player_player:return
	if !PlayerState.player_player.is_on_floor() and only_update_on_floor:return
	if target_is_vec2:
		pos = target_vec2
	var cell_vec2i = get_cell_vec2i_by_pos(pos)
	if last_npc_current_cell == cell_vec2i:return
	if cell_data_vec2i_dic.has(cell_vec2i):
		cell_vec2i = get_fin_cell(cell_vec2i)
		var data = base_tile.get_cell_tile_data(0,cell_vec2i)
		if data:
			var block = data.get_custom_data(BLOACKED)
			return
		var cell_pos = get_cell_center_pos_by_pos(pos)
		if enabel_ui:
			if cell_prop_pos_dic.has(cell_pos):
				cell_prop_pos_dic[cell_pos][2].self_modulate = target_on_cell_color
		target_current_cell = cell_vec2i
		target_current_cell_pos = pos
		if cell_prop_pos_dic.has(last_target_current_cell_pos):
			if enabel_ui:cell_prop_pos_dic[last_target_current_cell_pos][2].self_modulate = Color.WHITE
		last_target_current_cell_pos = cell_pos
##获取偏移后最近的可用cell
func get_fin_cell(base_cell:Vector2i):
	if target_offset_cell_vec2i == Vector2i.ZERO:return base_cell
	if !PlayerState.player.is_on_floor():
		return base_cell
	var fin_cell:Vector2i = base_cell + target_offset_cell_vec2i
	while cell_data_vec2i_dic.has(fin_cell)  and (is_blocked(fin_cell) or !is_blocked(fin_cell+Vector2i(0,1))) and abs(fin_cell.x - base_cell.x) <= abs(target_offset_cell_vec2i.x) :
		fin_cell -= Vector2i(sign(target_offset_cell_vec2i.x),0)
	return fin_cell

func _process(delta: float) -> void:
	if !check_ok or !enable:return
	target_pos_update(target.global_position)
	npc_pos_update(npc.astar_marker.global_position)
	
##从路径上获取下一个目标边缘cell
func get_next_edge_cell():
	#on_update()
	var list = path_array.duplicate(true)
	if list.size()<2:return null
	var current_cell = list.pop_back()
	current_cell = list.pop_back()
	if jump_try_times in range(jump_try_time_range.x,jump_try_time_range.y):
		air_cost = 0
	else :
		if jump_try_times > jump_try_time_range.y:
			jump_try_times = 0
		air_cost = base_air_cost
	while !list.is_empty() and list.size()!=1 and current_cell and !get_cell_data(current_cell,IS_EDGE) or (!list.is_empty() and list.size()!=1 and  current_cell and !get_cell_data(current_cell,DIRECTION) in [Vector2i(1,0),Vector2i(-1,0)] ):
		current_cell = list.pop_back()
	current_jump_target = current_cell
	colored_cell(current_cell,edge_color)
	return current_cell
	
##从附近后去一个不是障碍物的cell
func get_near_none_bloack_cell(pos:Vector2):
	var current_cell = get_cell_vec2i_by_pos(pos)
	while is_blocked(current_cell):
		current_cell = base_tile.get_surrounding_cells(current_cell).pick_random()
	return get_cell_center_pos_by_vec2i(current_cell) 
	
func update_ui_visible():
	for k in cell_prop_pos_dic.keys():
		cell_prop_pos_dic[k][0].visible = enabel_ui
		
func get_astar_range():
	left_x = base_tile.to_global(astar_range.position).x - Vector2(astar_range.shape.get_rect().size.x*.5,0).x
	right_x = base_tile.to_global(astar_range.position).x - Vector2(astar_range.shape.get_rect().size.x*.5,0).x+ Vector2(astar_range.shape.get_rect().size.x,0).x
	bot_y = base_tile.to_global(astar_range.position).y + astar_range.shape.get_rect().size.y*.5
	top_y = base_tile.to_global(astar_range.position).y - astar_range.shape.get_rect().size.y*.5

func is_in_range(pos:Vector2):
	if pos.x >= left_x and pos.x<= right_x:
		pass
		if pos.y >= top_y and pos.y <= bot_y:
			return true
	return false
	
##设置为move模式	
func set_taget_position_mode(flag:bool,target_pos1:Vector2 = Vector2.ZERO):
	if flag:
		target_is_vec2 = flag
		target_vec2 = target_pos1
		target_pos_update(target_vec2)
	target_is_vec2 = flag
	enable = flag
