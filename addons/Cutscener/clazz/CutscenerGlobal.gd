@tool
extends Node
##运行节点改变
signal running_node_changed(node_name:String)
##节点删除
signal node_delete(node_name:String)
##日志更新
signal log_change(log:String)
##清除节点所有连线
signal clear_node_connection
##Cutscener运行通知
signal cutscener_started
##Cutscener运行通知
signal cutscener_ended
##聚合节点运行结束
signal run_combine_finished(node_name)
##聚合节点分解
signal discombine_node(node_name)
##载入全局脚本
signal load_global
##过场执行器通知运行
signal cutscener_run(cutscener_name)
##载入指定全局脚本通知
signal load_all_method_state_from_global
##刷新设置中的autoload配置列表
signal refresh_setting_autoload_config
##文件历史刷新
signal file_history_changed
##文本框编辑事件
signal param_modify
##文本框选中
signal param_focus_enter
##文本框离开
signal param_focus_exit
##当前正在运行的节点名
var current_combine_node_name="NA"
##region Node实例基础配置
##生成节点名(节点名,节点的系统object id)
func get_nid(node_name,obj_id):
	var iname = str(node_name).get_slice("_",0)
	return iname+ "_" + str(obj_id)
##真节点槽的颜色
const slot_true_color:Color = Color("1dff92dd")
##假节点槽的颜色
const slot_false_color:Color = Color("ff4a50dd")
##默认节点槽的颜色
const slot_default_color:Color = Color("ffffffe2")
const protect_node_theme:Resource = preload("res://addons/Cutscener/resource/protect_node_theme.tres")
const protect_node_theme_selected:Resource = preload("res://addons/Cutscener/resource/protect_node_theme_selected.tres")
##节点类型字典
##{类型:实例,名称}
var NODE_TYPE:Dictionary={
	NODES.START_NODE:[],
	NODES.SIGNAL_NODE:[],
	NODES.SET_NODE:[],
	NODES.CONDITION_NODE:[],
	NODES.END_NODE:[],
	NODES.COMBINE_NODE:[],
	NODES.STATETREE_NODE:[],
}
##节点类型
enum NODES{
	START_NODE = 0,#起始节点
	SIGNAL_NODE = 1,#信号节点
	SET_NODE = 2,#set节点
	CONDITION_NODE = 3,#条件节点
	END_NODE = 4,#结束节点
	STATETREE_NODE = 5,#结束节点
	COMBINE_NODE = 101,#聚合节点
}
##另存为时的节点名映射
var CONNECTION_LIST_MAP:Array
##节点实例缓存
var NODE_INST:Dictionary
##选中的节点名
var NODE_INST_SELECTED:Array
##当前节点
var current_node:String = "StartNode":
	set(n):
		current_node=n
		running_node_changed.emit(n)
##上一个节点
var last_node:String
##endregion

##主视图实例
var WORK_SPACE
##支持的数据类型
enum VAR_TYPE {
	STRING = TYPE_STRING,
	FLOAT = TYPE_FLOAT,
	INT = TYPE_INT,
	BOOL = TYPE_BOOL,
	ARRAY = TYPE_ARRAY,
	DICT = TYPE_DICTIONARY,
	RES = TYPE_OBJECT,
	V2 = TYPE_VECTOR2
}
##数据类型自定义配置
var VAR_TYPE_DIC:Dictionary= {
	0 : ["null",TYPE_NIL,[0],[0,1]],
	4 : ["String",TYPE_STRING,[0],[0,1]],
	3 : ["float",TYPE_FLOAT,[0,6,7,8,9,12],[0,1,2,3,4,5]],
	2 : ["int",TYPE_INT,[0,6,7,8,9,12],[0,1,2,3,4,5]],
	1 : ["bool",TYPE_BOOL,[0],[0,1]],
	28 : ["Array",TYPE_ARRAY,[0,6,7],[0,1]],
	27 : ["Dictionary",TYPE_DICTIONARY,[0,6,7],[0,1]],
	24 : ["Resource",TYPE_OBJECT,[0],[0,1]],
	5 : ["Vector2",TYPE_VECTOR2,[0,6,7,8,9],[0,1,2,3,4,5]],
}
##支持的判断数据类型
enum CONDITION_TYPE {
	EQUAL = 0,
	NOT_EQUAL = 1,
	LESS = 2,
	LESS_EQUAL = 3,
	GREATER = 4,
	GREATER_EQUAL = 5,
	NOT = 23,
	IN = 24,
}
##条件连接类型
enum CONDITION_LINK_TYPE{
	AND = 20,
	OR = 21,
}
##条件连接字典
var CONDITION_LINK_TYPE_DIC:Dictionary= {
	20 : ["and",OP_AND],
	21 : ["or",OP_OR],
}
##判断类型字典
var CONDITION_TYPE_DIC:Dictionary= {
	0 : ["==",OP_EQUAL],
	1 : ["!=",OP_NOT_EQUAL],
	2 : ["<",OP_LESS],
	3 : ["<=",OP_LESS_EQUAL],
	4 : [">",OP_GREATER],
	5 : [">=",OP_GREATER_EQUAL],
	23 : ["not",OP_NOT],
	24 : ["in",OP_IN],
}
##Set类型
enum SET_TYPE {
	EQUAL = 0,
	ADD = 6,
	SUBTRACT = 7,
	MULTIPLY = 8,
	DIVIDE = 9,
	MODULE = 12,
}
##set类型字典
var SET_TYPE_DIC:Dictionary= {
	0 : ["=",0],
	6 : ["+=",OP_ADD],
	7 : ["-=",OP_SUBTRACT],
	8 : ["×=",OP_MULTIPLY],
	9 : ["÷=",OP_DIVIDE],
	12 : ["%=",OP_MODULE],
}
##目标全局脚本的方法 [方法名,[{参数名1:类型},{参数名2:类型}],返回值类型]
var CUTSCENE_BUS_METHOD:Array
##指定用于储存可调用方法的全局脚本[脚本1,脚本2]
var METHOD_BUSES:Array
##目标全局脚本的变量
var CUTSCENE_BUS_STATE:Dictionary
##指定用于储存可调用变量的全局脚本
var STATE_BUSES:Array
##聚合数据缓存
var COMBINE_DATAS:Dictionary = {}

##根据类型将string转换为对应变量
func string_2_var(from_var:String,type:int=0):
	if from_var == "null":
		return null
	match type:
		TYPE_STRING:
			return str(from_var)
		TYPE_FLOAT:
			return float(from_var)
		TYPE_INT:
			return int(from_var)
		TYPE_BOOL:
			return bool(int(from_var)) or from_var.to_lower() == "true"
		TYPE_ARRAY:
			var v =  json_2_var(from_var)
			if typeof(v) == TYPE_ARRAY:
				return v
			else:
				ACTION_LOG = "转出类型错误,应为[Array],实际为:[%s]" %typeof(v)
				return null
		TYPE_DICTIONARY:
			var v =  json_2_var(from_var)
			if typeof(v) == TYPE_DICTIONARY:
				return v
			else:
				ACTION_LOG = "转出类型错误,应为[Dictionary],实际为:[%s]" %typeof(v)
				return null
		TYPE_VECTOR2:
				var v2_list = json_2_var(from_var)
				return Vector2(v2_list[0],v2_list[1])
		TYPE_OBJECT:
			if  ResourceLoader.exists(from_var):
				var res = ResourceLoader.load(from_var)
				return res	
			else :
				ACTION_LOG = "资源文件不存在![%s]" %from_var
				return null	
##json转变量				
func json_2_var(json_string):
	var json = JSON.new()
	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.data
		return data_received
	else:
		printerr("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
##配置文件目录
const CONFIG_DATA_FILE_PATH = "user://Cutscener/config.data"
##配置文件内容数据
var CONFIG_DATA_DIC:Dictionary={
	"run_type":0,
	"method_bus":[],
	"state_bus":[],
	"save_file_config":"",	
	"file_his":FILE_HISTORY,	
}
##默认存档名
const SAVE_FILE_NAME = "save.json"
##默认存档目录
const USER_PATH = "user://"
##日志
var ACTION_LOG:String:
	set(s):
		ACTION_LOG = s + "\n" + ACTION_LOG
		log_change.emit(s)
		print(s)
			
##文件配置字典		
var FILE_SYS_DIC:Dictionary = {
	"file_history":[],#文件历史
	"curren_save_name":"NA",#当前存档名
	"current_save_path":"NA",#当前存档路径
	"current_save_file_path":"NA",#当前存档目录+文件名
}
var FILE_HISTORY:Array:
	set(list):
		FILE_HISTORY = list
		CONFIG_DATA_DIC["file_his"] = list
		file_history_changed.emit()
##已分解的聚合节所链接的存档文件
var DELETE_COMBINE_NODE_SAVE_FILE_NAME:Dictionary
##主视图
var GRAPH_EDITOR:GraphEdit
##初始化
func preset():
	NODE_INST.clear()
	current_node == "StartNode"
	FILE_SYS_DIC["curren_save_name"] = "NA"
	FILE_SYS_DIC["current_save_path"] = "NA"
	FILE_SYS_DIC["current_save_file_path"] = "NA"
	NODE_INST_SELECTED.clear()
	DELETE_COMBINE_NODE_SAVE_FILE_NAME.clear()
	ACTION_LOG = ""

func popup(text,title:String = "请确认"):
	WORK_SPACE.popup_dialog.dialog_text = text
	WORK_SPACE.popup_dialog.title = title
	WORK_SPACE.popup_dialog.show()
	await WORK_SPACE.popup_dialog.finished
	return WORK_SPACE.popup_dialog.ok

## 方法/变量是否已成功载入
var methods_loaded: bool = false
## 防止并发重复扫描
var _loading_methods: bool = false

func _ready() -> void:
	_ensure_config_file()
	_load_config_into_memory()
	# 编辑器：不在此处立刻扫方法/发 refresh（监听方可能未连接）
	# 由 WorkSpace._ready / 打开面板 / Setting 确认 调用 request_reload_methods()
	if not Engine.is_editor_hint():
		request_reload_methods()


func _ensure_config_file() -> void:
	if FileAccess.file_exists(CONFIG_DATA_FILE_PATH):
		return
	DirAccess.make_dir_absolute(CONFIG_DATA_FILE_PATH.get_base_dir())
	var config := FileAccess.open(CONFIG_DATA_FILE_PATH, FileAccess.WRITE)
	config.store_line(JSON.stringify(CONFIG_DATA_DIC, "\t"))


func _load_config_into_memory() -> void:
	var dic = load_json(CONFIG_DATA_FILE_PATH)
	if not dic:
		return
	if dic.has("method_bus"):
		CONFIG_DATA_DIC["method_bus"] = dic["method_bus"]
	if dic.has("state_bus"):
		CONFIG_DATA_DIC["state_bus"] = dic["state_bus"]
	if dic.has("file_his"):
		FILE_SYS_DIC["file_history"] = dic["file_his"]
		FILE_HISTORY = dic["file_his"]
	METHOD_BUSES = CONFIG_DATA_DIC["method_bus"]
	STATE_BUSES = CONFIG_DATA_DIC["state_bus"]


## project.godot 中 autoload 名 -> 路径（带或不带 *）
var _autoload_path_cache: Dictionary = {}

## 统一入口：等就绪后扫描 Autoload 方法与变量
func request_reload_methods() -> void:
	call_deferred("_reload_methods_and_states")


func _reload_methods_and_states() -> void:
	if _loading_methods:
		return
	_loading_methods = true
	_refresh_autoload_path_cache()
	# 只短等几帧：编辑器里部分 Autoload 可能永远不在树中，不能死等
	await _wait_buses_ready(12)
	_scan_methods()
	_scan_states()
	methods_loaded = true
	_loading_methods = false
	load_global.emit()
	ACTION_LOG = "METHOD/STATE 载入完成: methods=%s states=%s" % [
		CUTSCENE_BUS_METHOD.size(), CUTSCENE_BUS_STATE.size()
	]


func _refresh_autoload_path_cache() -> void:
	_autoload_path_cache.clear()
	var project := ConfigFile.new()
	if project.load("res://project.godot") != OK:
		return
	if not project.has_section("autoload"):
		return
	for key in project.get_section_keys("autoload"):
		var path: String = str(project.get_value("autoload", key))
		# 去掉 * 前缀（表示单例）
		if path.begins_with("*"):
			path = path.substr(1)
		_autoload_path_cache[key] = path


## 短等：有节点则用节点；没有也不报「超时失败」，后面走脚本回退
func _wait_buses_ready(max_frames: int = 12) -> void:
	var buses: Array = []
	buses.append_array(METHOD_BUSES)
	buses.append_array(STATE_BUSES)
	if buses.is_empty():
		await get_tree().process_frame
		return
	var frame := 0
	while frame < max_frames:
		var all_ok := true
		for bus in buses:
			if not get_tree().get_root().has_node(str(bus)):
				all_ok = false
				break
		if all_ok:
			await get_tree().process_frame
			return
		await get_tree().process_frame
		frame += 1


## 从场景树或脚本资源解析可调用方法列表
func _collect_method_dicts(bus_name: String) -> Array:
	var result: Array = []
	# 1) 优先已在树中的实例（运行时 / 部分编辑器 Autoload）
	if get_tree() and get_tree().get_root().has_node(bus_name):
		var node: Node = get_tree().get_root().get_node(bus_name)
		for method in node.get_method_list():
			result.append(method)
		return result
	# 2) 编辑器回退：从 project.godot 路径加载脚本再扫
	var script := _resolve_autoload_script(bus_name)
	if script == null:
		ACTION_LOG = "无法解析 Autoload 脚本: %s（树中无节点且路径无效）" % bus_name
		return result
	if script.has_method("get_script_method_list"):
		for method in script.get_script_method_list():
			result.append(method)
	else:
		ACTION_LOG = "脚本不支持 get_script_method_list: %s" % bus_name
	return result


func _resolve_autoload_script(bus_name: String) -> Script:
	if not _autoload_path_cache.has(bus_name):
		_refresh_autoload_path_cache()
	if not _autoload_path_cache.has(bus_name):
		return null
	var path: String = str(_autoload_path_cache[bus_name])
	if path.is_empty():
		return null
	# uid:// 需要用 ResourceLoader
	if not ResourceLoader.exists(path) and not path.begins_with("uid://"):
		ACTION_LOG = "Autoload 路径不存在: %s -> %s" % [bus_name, path]
		return null
	var res = load(path)
	if res == null:
		ACTION_LOG = "Autoload 资源加载失败: %s -> %s" % [bus_name, path]
		return null
	if res is Script:
		return res as Script
	if res is PackedScene:
		var packed: PackedScene = res
		var inst: Node = packed.instantiate()
		var s: Script = inst.get_script()
		inst.queue_free()
		return s
	return null


func _scan_methods() -> void:
	CUTSCENE_BUS_METHOD.clear()
	if METHOD_BUSES.is_empty():
		return
	for bus in METHOD_BUSES:
		var bus_name := str(bus)
		var methods: Array = _collect_method_dicts(bus_name)
		if methods.is_empty():
			continue
		var from_tree := get_tree() and get_tree().get_root().has_node(bus_name)
		ACTION_LOG = "载入 METHOD_BUS [%s]（%s）" % [
			bus_name, "场景树" if from_tree else "脚本回退"
		]
		for method in methods:
			if not _is_callable_bus_method(method):
				continue
			var args_real: Array = []
			var args = method.get("args", [])
			for arg in args:
				args_real.append({
					"arg_name": arg.get("name", ""),
					"arg_type": arg.get("type", TYPE_NIL),
				})
			var ret_type = 0
			if method.has("return") and typeof(method["return"]) == TYPE_DICTIONARY:
				ret_type = method["return"].get("type", 0)
			CUTSCENE_BUS_METHOD.append([
				"%s.%s" % [bus_name, method.get("name", "")],
				args_real,
				ret_type,
			])


func _is_callable_bus_method(method: Dictionary) -> bool:
	var mname: String = str(method.get("name", ""))
	if mname.is_empty() or mname == "free":
		return false
	if mname.begins_with("_"):
		return false
	# 脚本 get_script_method_list 可能没有完整 flags；有则过滤引擎/编辑器
	if method.has("flags"):
		var flags: int = int(method.flags)
		if flags & METHOD_FLAG_OBJECT_CORE:
			return false
		if flags & METHOD_FLAG_EDITOR:
			return false
		# 实例 get_method_list：要求带 NORMAL；纯脚本列表往往 flags 为 1 或 0
		if flags != 0 and not (flags & METHOD_FLAG_NORMAL):
			return false
	return true


func _scan_states() -> void:
	CUTSCENE_BUS_STATE.clear()
	if STATE_BUSES.is_empty():
		return
	for bus in STATE_BUSES:
		var bus_name := str(bus)
		# 1) 树中实例
		if get_tree() and get_tree().get_root().has_node(bus_name):
			var node: Node = get_tree().get_root().get_node(bus_name)
			for prop in node.get_property_list():
				if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					CUTSCENE_BUS_STATE["%s.%s" % [bus_name, prop.name]] = prop.type
			ACTION_LOG = "载入 STATE_BUS [%s]（场景树）" % bus_name
			continue
		# 2) 脚本回退
		var script := _resolve_autoload_script(bus_name)
		if script == null:
			ACTION_LOG = "STATE_BUS 无法解析: %s" % bus_name
			continue
		if script.has_method("get_script_property_list"):
			for prop in script.get_script_property_list():
				var usage: int = int(prop.get("usage", 0))
				if usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
					CUTSCENE_BUS_STATE["%s.%s" % [bus_name, prop.get("name", "")]] = prop.get("type", TYPE_NIL)
			ACTION_LOG = "载入 STATE_BUS [%s]（脚本回退）" % bus_name
		else:
			ACTION_LOG = "STATE_BUS 脚本无属性列表: %s" % bus_name


func load_json(path):
	if not FileAccess.file_exists(path):
		return
	var file = FileAccess.open(path, FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if OK != error:
		ACTION_LOG = "执行器载入json数据失败![%s]" % error
		return
	var data_received = json.data as Dictionary
	return data_received
var REPLACEMENTS_REGEX: RegEx = RegEx.create_from_string("{{(.*?)}}")

func get_real_arg(a_name:String,a_type):
	if a_type == TYPE_STRING:
		var global_vs:Array
		global_vs = REPLACEMENTS_REGEX.search_all(a_name)
		if global_vs.is_empty():return a_name
		for global_v in global_vs:
			var o_v = global_v.strings[0]
			var v:String = str(get_property_value(global_v.strings[0]))
			a_name = a_name.replacen(o_v,v)
		return a_name
	else :
		if a_name.begins_with("{{") and a_name.ends_with("}}"):
			return get_property_value(a_name)
		else:
			return string_2_var(a_name,a_type)
			
func get_property_value(p_name:String):
	var p = p_name.replace("{","").replace("}","").replace(" ","")
	if STATE_BUSES.is_empty():return
	for node in STATE_BUSES:
		if !get_tree().get_root().has_node(node):continue
		var value = get_tree().get_root().get_node(node).get(p)
		if null==value:
			continue
		return value
	
