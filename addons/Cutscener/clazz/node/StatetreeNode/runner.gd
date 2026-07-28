@tool
extends Node
var node_type = CutscenerGlobal.NODES.STATETREE_NODE
signal finished
var condition_result_index:int = -2
var break_out:bool = false
##组件props数据Array中对应index代表意义
enum ARGS_INDEX {
	MinIndex = 0,
	MaxIndex = 1,
	ExportIndex = 2,
}
enum ARGS_INDEX1 {
	TypeIndexx = 0,
	ConditionLinkTypeIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	ExportIndex = 6,
}
##组件props数据Array中对应index代表意义
enum ARGS_INDEX_TITLE {
	TypeIndex = 0,
	ConditionLinkType = 1,
	DialoguePathIndex = 2,
	ParamIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	ExportIndex = 6,
}
func run(dic):
	condition_result_index = -2
	#必须等待.1秒否则有可能接收不到finish信号
	#await RenderingServer.frame_post_draw
	var title_name:String = dic["title_name"]
	owner.result = title_name
	var running_node_name = dic["name"]
	if owner.print_debug:CutscenerGlobal.ACTION_LOG = "------ConditionRunner [%s]正在运行!------" %title_name
	var props:Array = dic["props"]
	if dic.has(CutscenerGlobal.current_combine_node_name+"_props"):
		props = dic[CutscenerGlobal.current_combine_node_name+"_props"]
		#CutscenerGlobal.ACTION_LOG = "当前正在运行嵌套![%s]" %CutscenerGlobal.current_combine_node_name
	for i in props.size():
		if owner.print_debug:CutscenerGlobal.ACTION_LOG = "----目标Index[%s]----" %i
		var prop:Array = props[i]
		var p = prop.duplicate(true)
		var flag = handle_conditions(title_name,p)
		if flag:
			condition_result_index = i
			break
	if owner.print_debug:CutscenerGlobal.ACTION_LOG = "---------判断结果 == [%s]---------" %str(condition_result_index)
	if float(dic["timer"])>0:
		await get_tree().create_timer(float(dic["timer"])).timeout
	#CutscenerGlobal.ACTION_LOG = "------ConditionRunner [%s]运行完毕!------" %running_node_name
	return condition_result_index
	
##处理判断条件
func handle_conditions(title_name,props:Array):
	var result:bool = true
	if !Dialogue.dialogue_title_dic.has(title_name):return false
	var num_arg = props.pop_front()
	var i = Dialogue.dialogue_title_dic[title_name]
	if int(num_arg[ARGS_INDEX.MinIndex]) < 0 or int(num_arg[ARGS_INDEX.MaxIndex]) < 0:
		result = true
	elif (i>=int(num_arg[ARGS_INDEX.MinIndex]) and i<=int(num_arg[ARGS_INDEX.MaxIndex])):
		result = true
	else :
		result = false
	if owner.print_debug:CutscenerGlobal.ACTION_LOG =" - 判断对话次数: %s < [ %s ] < %s" %[num_arg[ARGS_INDEX.MinIndex],str(i),num_arg[ARGS_INDEX.MaxIndex]]
	for prop in props:
		var flag = handle_condition(prop)
		var link_type = prop[ARGS_INDEX1.ConditionLinkTypeIndex]
		if link_type == OP_OR:
			if flag:
				return true
		else:
			if !flag:result = flag
	return result	
	
func handle_condition(prop):
	var type = prop[ARGS_INDEX1.TypeIndexx]
	var bus
	var real_to_var
	if int(type) == 0: 
		bus = get_tree().get_root().get_node(prop[ARGS_INDEX1.ParamIndex].get_slice(".",0))
	var link_type = prop[ARGS_INDEX1.ConditionLinkTypeIndex]
	var from_var = prop[ARGS_INDEX1.ParamIndex].get_slice(".",1)
	var var_type = prop[ARGS_INDEX1.ParamTypeIndex]
	var condition_type = prop[ARGS_INDEX1.ConditionTypeIndex]
	var to_var = prop[ARGS_INDEX1.Param2Index]
	var real_from_var
	if int(type) == 0: 
		real_from_var = bus.get(from_var)
		real_to_var = CutscenerGlobal.get_real_arg(prop[ARGS_INDEX1.Param2Index],prop[ARGS_INDEX1.ParamTypeIndex])
	elif int(type) == 1:
		real_to_var = CutscenerGlobal.get_real_arg(prop[ARGS_INDEX1.Param2Index],prop[ARGS_INDEX1.ParamTypeIndex])
		var f = int(prop[ARGS_INDEX1.ParamIndex].get_slice(".",0))
		real_from_var = CutscenerGlobal.get_real_arg(str(EventData.event_data_dic[f].event_value),prop[ARGS_INDEX1.ParamTypeIndex])
	elif int(type) == 2:
		var f = str(prop[ARGS_INDEX_TITLE.ParamIndex])
		from_var = f
		if Dialogue.dialogue_title_dic.has(f):
			real_from_var = int(Dialogue.dialogue_title_dic[f])
		else :
			real_from_var = 0
		real_to_var = int(prop[ARGS_INDEX_TITLE.Param2Index])
	if owner.print_debug:CutscenerGlobal.ACTION_LOG =" - 判断: [%s]: [ %s ] %s %s" %[str(from_var),str(real_from_var),CutscenerGlobal.CONDITION_TYPE_DIC[int(condition_type)][0],str(real_to_var)]
	if condition_type == CutscenerGlobal.CONDITION_TYPE.EQUAL:
		return real_from_var == real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.NOT_EQUAL:
		return real_from_var != real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.LESS:
		return real_from_var < real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.LESS_EQUAL:
		return real_from_var <= real_to_var
	elif condition_type == CutscenerGlobal.CONDITION_TYPE.GREATER:
		return real_from_var > real_to_var
	elif condition_type == OP_GREATER_EQUAL:
		return real_from_var >= real_to_var
	elif condition_type == OP_IN:
		return real_from_var in real_to_var
	elif condition_type == OP_NOT:
		return real_from_var not in real_to_var
