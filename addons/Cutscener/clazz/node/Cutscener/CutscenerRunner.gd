@tool
extends Node
## Cutscener 执行器
## 执行顺序：节点自身 → 子节点按 index 升序深度优先

@onready var signal_runner := $SignalRunner
@onready var start_runner := $StartRunner
@onready var set_runner := $SetRunner
@onready var condition_runner := $ConditionRunner
@onready var end_runner := $EndRunner
@onready var combine_runner := $CombineRunner
@onready var state_tree_runner: Node = $StateTreeRunner

@export var print_debug: bool = false
var Runners: Dictionary = {}

@export_global_file("*.crd") var cutscener_data
@export var change_CutsceneState_current_cutscene: bool = true
@export var cutscener_name: String = "NA"

var running: bool = false
var _abort_requested: bool = false
var current_save_raw_data: Dictionary = {}
var result


# region 对外 API

func run(c_name: String):
	if running:
		CutscenerGlobal.ACTION_LOG = "[%s]已在运行中，请先 stop()" % cutscener_name
		return
	if c_name != cutscener_name:
		return

	_abort_requested = false
	var config_file = load_json(CutscenerGlobal.CONFIG_DATA_FILE_PATH)
	var dic: Dictionary

	if cutscener_data and FileAccess.file_exists(cutscener_data):
		CutscenerGlobal.ACTION_LOG = "[%s]开始运行, 存档:[%s]" % [cutscener_name, cutscener_data]
		if change_CutsceneState_current_cutscene:CutsceneState.current_cutscene = cutscener_name
		dic = load_json(cutscener_data)
	else:
		dic = load_json(config_file["save_file_config"])
		CutscenerGlobal.ACTION_LOG = "[%s]开始运行默认存档:[%s]" % [cutscener_name, config_file["save_file_config"]]

	CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]开始运行---------" % cutscener_name
	running = true
	current_save_raw_data = dic
	await _run_graph(dic["base"])

	if _abort_requested:
		CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]已被硬中断---------" % cutscener_name
	else:
		CutscenerGlobal.ACTION_LOG = "---------Cutscener[%s]运行结束---------" % cutscener_name
		CutscenerGlobal.ACTION_LOG = "---------返回值: %s---------" % str(result)
	return result


## 硬中断
func stop() -> void:
	if not running and not _abort_requested:
		CutscenerGlobal.ACTION_LOG = "[%s]当前未运行" % cutscener_name
		return
	_do_hard_abort()


func is_running() -> bool:
	return running


func is_abort_requested() -> bool:
	return _abort_requested

# endregion


# region 生命周期

func _ready() -> void:
	Runners[signal_runner.node_type] = signal_runner
	Runners[start_runner.node_type] = start_runner
	Runners[set_runner.node_type] = set_runner
	Runners[condition_runner.node_type] = condition_runner
	Runners[end_runner.node_type] = end_runner
	Runners[combine_runner.node_type] = combine_runner
	Runners[state_tree_runner.node_type] = state_tree_runner

	combine_runner.run_combine_node.connect(_on_run_combine)
	CutscenerGlobal.cutscener_run.connect(run)
	if CutscenerGlobal.has_signal("cutscener_stopped"):
		CutscenerGlobal.cutscener_stopped.connect(_on_global_stop)

	for k in Runners.keys():
		Runners[k].finished.connect(_on_runner_finished)


func _on_runner_finished(v) -> void:
	result = v


func _on_global_stop(c_name: String) -> void:
	if c_name == "" or c_name == cutscener_name:
		if running:
			_do_hard_abort()


func _do_hard_abort() -> void:
	if _abort_requested:
		return
	_abort_requested = true
	running = false
	CutscenerGlobal.ACTION_LOG = "[%s]执行硬中断!" % cutscener_name
	if combine_runner and combine_runner.has_method("force_abort"):
		combine_runner.force_abort()
	if CutscenerGlobal.has_signal("cutscener_stopped"):
		CutscenerGlobal.cutscener_stopped.emit(cutscener_name)
	CutscenerGlobal.cutscener_ended.emit()

# endregion


# region 核心执行（DFS）

## 从存档图数据入口：找到 Start，开始深度优先
func _run_graph(dic: Dictionary) -> void:
	if _abort_requested:
		running = false
		return

	var start_node: String = ""
	var nodes_type: Dictionary = dic["nodes_type"]
	for k in nodes_type.keys():
		if nodes_type[k] == CutscenerGlobal.NODES.START_NODE:
			start_node = k
			break

	if start_node.is_empty():
		CutscenerGlobal.ACTION_LOG = "[%s]未找到 StartNode，中止" % cutscener_name
		running = false
		return

	var node_run_data: Dictionary = dic.get("run_data", {})
	# Start 在 run_data 里通常以「从 Start 指出的边」形式存在；
	# 先执行 Start 自身，再按它的出边走子节点。
	await _execute_node(start_node, dic, node_run_data)
	running = false


## 执行单个节点，再按 index 深度优先执行其子节点
## node_name: 当前节点名
func _execute_node(node_name: String, dic: Dictionary, node_run_data: Dictionary) -> void:
	if _abort_requested:
		return
	if not dic["nodes_type"].has(node_name):
		CutscenerGlobal.ACTION_LOG = "节点不存在于 nodes_type: %s" % node_name
		return

	var nt: int = dic["nodes_type"][node_name]
	var runner = Runners.get(nt)
	if runner == null:
		CutscenerGlobal.ACTION_LOG = "未找到类型 %s 的 Runner" % nt
		return

	# —— 1. 先执行本节点 ——
	CutscenerGlobal.last_node = CutscenerGlobal.current_node
	CutscenerGlobal.current_node = node_name

	if print_debug:
		CutscenerGlobal.ACTION_LOG = "→ 执行节点 [%s] type=%s" % [node_name, nt]

	var node_data: Dictionary = dic[str(nt)][node_name]
	if nt != CutscenerGlobal.NODES.COMBINE_NODE:
		await runner.run(node_data)
	else:
		runner.run(node_data)
		await runner.finished

	if _abort_requested:
		return

	# —— 2. 根据本节点结果决定子节点 ——
	var children: Array = _resolve_children(node_name, runner.condition_result_index, node_run_data)
	if children.is_empty():
		return

	# index 升序（稳定）
	if children.size() > 1:
		children.sort_custom(_sort_by_index)

	# —— 3. 子节点依次：自身 → 整棵子树 ——
	for child in children:
		if _abort_requested:
			return
		var child_name: String = child[0]
		await _execute_node(child_name, dic, node_run_data)


## 根据 condition_result_index 解析出边
## 返回 [[child_name, index], ...]
func _resolve_children(node_name: String, condition_result_index: int, node_run_data: Dictionary) -> Array:
	if not node_run_data.has(node_name):
		return []

	var edges: Array = node_run_data[node_name]
	if edges.is_empty():
		return []

	# -2：不继续（如 Statetree 未命中）
	if condition_result_index == -2:
		return []

	# -1：走全部子边（默认顺序后续再 sort）
	if condition_result_index == -1:
		return edges.duplicate()

	# >=0：只走对应分支
	if condition_result_index >= 0 and condition_result_index < edges.size():
		# 若存档里分支边未预先按 index 排好，先排再取更稳妥
		var sorted_edges: Array = edges.duplicate()
		if sorted_edges.size() > 1:
			sorted_edges.sort_custom(_sort_by_index)
		# 语义：condition_result_index 是「第几条出边」（0-based）
		return [sorted_edges[condition_result_index]]

	return []


func _sort_by_index(a, b) -> bool:
	return a[1] < b[1]

# endregion


# region Combine / 工具

func _on_run_combine(data_node_name, node_name) -> void:
	if _abort_requested:
		return
	CutscenerGlobal.current_combine_node_name = node_name
	await _run_graph(current_save_raw_data[data_node_name])
	if not _abort_requested:
		CutscenerGlobal.run_combine_finished.emit(node_name)


func load_json(path) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		CutscenerGlobal.ACTION_LOG = "无法打开文件: %s" % path
		return {}
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error != OK:
		CutscenerGlobal.ACTION_LOG = "执行器载入 json 失败! [%s]" % error
		return {}
	return json.data as Dictionary

# endregion
