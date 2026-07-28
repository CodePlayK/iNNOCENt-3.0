@icon("res://core/common/resource/icon/wmm.svg")
extends Node
##权重随机机器
##
##根据权重之和计算跳转的目标状态
class_name WeightMachine
##当前总权重
var total_weight:float
##目标归类总权重字典{目标1:权重合,目标2:权重合}
var weight_sum_dic:Dictionary 
var weight_state:Dictionary
##每一个目标state下的权重字典{目标1:[权重0,权重1],目标2:[权重0,权重1]}
var weight_dic:Dictionary 
##是否打印debug
@export var print_debug:bool = true
@onready var timer: Timer = $_Timer
##是否自动启用
@export var auto_run:bool = true:
	set(f):
		auto_run = f
		if !timer:return
		if f:
			timer.start(1)
		else:
			timer.stop()
##总权重上限
@export var total_weight_max:float = 100
##总权重下限
@export var total_weight_min:float = 10
var debug_dic:Dictionary
var obj
##目标UI
@export var weight_machine_ui: Node2D

##初始化
func on_master_ready(master) -> void:
	obj = master.obj
	for node in get_children():
		if node.name.begins_with("_") or !node.enable:continue
		weight_dic[node.name] = []
		weight_state[node.name] = node
		weight_sum_dic[node.name] = 0
		for w_node in node.get_children():
			if w_node is Weight:
				weight_dic[node.name].append(w_node) 
		debug_dic[node.name]= 0
	if weight_machine_ui:weight_machine_ui.init_weightmachine(self)
	
##获取各目标的总权重
func get_target_node_weight_sum():
	total_weight = 0
	for k in weight_dic.keys():
		weight_sum_dic[k] = 0
		if !weight_state[k].enable:continue
		for w in weight_dic[k]:
			w.process(obj)
			weight_sum_dic[k] = weight_sum_dic[k]+w.weight
	for k in weight_sum_dic.keys():
		total_weight+=max(weight_sum_dic[k],0)
		
##计算随机权重结果		
func process(state):
	var fin_k:String
	if weight_sum_dic.is_empty():return
	for k in weight_state.keys():
		if weight_state[k].confirm:
			if weight_machine_ui:weight_machine_ui.update(self,k)
			if state == obj.state_manager.current_state:
				return obj.state_manager.get_state_by_name(k)
	get_target_node_weight_sum()
	randomize()
	var weight_sum:float
	if total_weight <= 0:return null
	total_weight = clampf(total_weight,total_weight_min,total_weight_max)
	var target = randf()*total_weight
	for k in weight_sum_dic.keys():
		var v = max(weight_sum_dic[k],0)
		weight_sum+=v
		if target<weight_sum:
			fin_k = k
			break
	if fin_k:
		debug_dic[fin_k]+=1
	if weight_machine_ui:weight_machine_ui.update(self,fin_k)
	if print_debug:
		Debug.dprintinfo(DebugCT.dp("[%s][%s][%s|%s]\n%s\n%s" %[total_weight,obj.name,self.name,fin_k,debug_dic,weight_sum_dic],self))
	for k in weight_dic.keys():
		for w in weight_dic[k]:
			w.after_process(obj)
	if state == obj.state_manager.current_state:
		return obj.state_manager.get_state_by_name(fin_k)

func exit():
	for k in weight_dic.keys():
		for w in weight_dic[k]:
			w.exit(obj)

func _on_timer_timeout() -> void:
	process(obj.state_manager.current_state)
