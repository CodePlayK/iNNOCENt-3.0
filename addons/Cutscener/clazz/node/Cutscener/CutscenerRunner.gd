@tool
extends Node
##Cutscener执行器
##信号节点执行器
@onready var signal_runner: = $SignalRunner
##起点节点执行器
@onready var start_runner: = $StartRunner
##Set节点执行器
@onready var set_runner: = $SetRunner
##条件节点执行器
@onready var condition_runner: = $ConditionRunner
##结束节点执行器
@onready var end_runner: = $EndRunner
##聚合节点执行器
@onready var combine_runner: = $CombineRunner
@onready var state_tree_runner: Node = $StateTreeRunner
##是否打印日志到控制台
@export var print_debug:bool = false
var Runners:Dictionary
@export_global_file("*.crd") var cutscener_data
@export var cutscener_name:String = "NA"
var running:bool = false
var current_save_raw_data:Dictionary
var result
##执行事件,依据cutscener_name判断是否运行的为当前过场
func run(c_name:String):
	if running:
		CutscenerGlobal.ACTION_LOG = "[%s]已经在运行中,请等待完成" %cutscener_name
		return
	if c_name!=cutscener_name:
		#CutscenerGlobal.ACTION_LOG = "[%s]非当前过场,跳过!:%s" %[cutscener_name,c_name]
		return
	var config_file = load_json(CutscenerGlobal.CONFIG_DATA_FILE_PATH)
	var dic
	if cutscener_data and FileAccess.file_exists(cutscener_data):
		CutscenerGlobal.ACTION_LOG = "[%s]开始运行,存档位置:[%s]" %[cutscener_name,cutscener_data]
		CutsceneState.current_cutscene=cutscener_name
		dic = load_json(cutscener_data)
	else:
		dic = load_json(config_file["save_file_config"])
		CutscenerGlobal.ACTION_LOG = "[%s]开始运行默认存档,存档位置:[%s]" %[cutscener_name,config_file["save_file_config"]]
	CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]开始运行---------" %cutscener_name
	running = true
	current_save_raw_data = dic
	await run_cutscene_data(dic["base"])
	CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]运行结束---------" %cutscener_name
	CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]返回值---------" %result
	return result
##聚合节点执行(聚合节点链接存档文件,聚合节点名)
func run_combine(data_node_name,node_name):
	CutscenerGlobal.current_combine_node_name = node_name
	await run_cutscene_data(current_save_raw_data[data_node_name])
	CutscenerGlobal.run_combine_finished.emit(node_name)

func _ready() -> void:
	Runners[signal_runner.node_type] = signal_runner
	Runners[start_runner.node_type] = start_runner
	Runners[set_runner.node_type] = set_runner
	Runners[condition_runner.node_type] = condition_runner
	Runners[end_runner.node_type] = end_runner
	Runners[combine_runner.node_type] = combine_runner
	Runners[state_tree_runner.node_type] = state_tree_runner
	combine_runner.run_combine_node.connect(run_combine)
	CutscenerGlobal.cutscener_run.connect(run)
	for k in Runners.keys():
		Runners[k].finished.connect(on_runner_finished)

func on_runner_finished(v):
	result = v

func load_json(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if OK!=error:
		CutscenerGlobal.ACTION_LOG = "执行器载入json数据失败![%s]" %error
	var data_received = json.data as Dictionary
	return data_received

##从startnode开始执行
func run_cutscene_data(dic):
	var start_node
	var nodes_type = dic["nodes_type"]
	for k in nodes_type.keys() :
		if nodes_type[k] == CutscenerGlobal.NODES.START_NODE:
			start_node = k
			break
	var node_run_data = dic["run_data"]
	if node_run_data:
		await run_node(node_run_data[start_node],dic,node_run_data)
		running = false


##执行 node_run_data=[[node_name1,node_index1],[node_name2,node_index2]]
func run_node(node_list,dic,node_run_data):
	var temp_list:Array=node_list.duplicate()
	var next_list:Array
	if temp_list.size()>1:
		temp_list.sort_custom(sort_by_index)#根据node配置的index进行排序
	next_list.clear()
	for n in temp_list:
		var condition_result_index = 0
		var node_name = n[0]
		var nt:int = dic["nodes_type"][node_name]
		var r = Runners[nt]#根据类型选择对应的执行器
		CutscenerGlobal.last_node=CutscenerGlobal.current_node
		CutscenerGlobal.current_node=node_name
		if nt != CutscenerGlobal.NODES.COMBINE_NODE:
			condition_result_index =  await r.run(dic[str(nt)][node_name])
		else :
			r.run(dic[str(nt)][node_name])
			await r.finished
		##CutscenerGlobal.ACTION_LOG = "------主Runner开始等待[%s]运行结束------" %node_name
		#await r.finished
		##CutscenerGlobal.ACTION_LOG = "------主Runner[%s]运行结束------" %node_name
		condition_result_index = r.condition_result_index
		if node_run_data.has(node_name):
			if condition_result_index ==-1:
				next_list.append_array(node_run_data[node_name])
			elif condition_result_index!=-2 :
				if node_run_data[node_name].size()>1:node_run_data[node_name].sort_custom(sort_by_index)
				if node_run_data[node_name].size() > condition_result_index:
					next_list.append(node_run_data[node_name][condition_result_index])
	if next_list.size()>0:#如果子node还有子node,则继续
		await run_node(next_list,dic,node_run_data)

##排序
func sort_by_index(node1,node2) -> bool:
	if node1[1] < node2[1]:
		return	true
	else :
		return	false
