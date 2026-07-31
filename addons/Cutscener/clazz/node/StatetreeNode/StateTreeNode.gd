@tool
extends BaseGraphNode
signal drag_off
@onready var title_list: OptionButton = %TitleList
@onready var param_prototype: HBoxContainer = %ParamPrototype
@onready var condition_prototype: HBoxContainer = %ConditionPrototype
@onready var event_prototype: HBoxContainer = $MarginContainer/VBoxContainer/EventPrototype
@onready var title_prototype: HBoxContainer = $MarginContainer/VBoxContainer/TitlePrototype

@onready var dialogues: RichTextLabel = %Dialogues
@onready var res_file: LineEdit = %ResFile
@onready var em: MarginContainer = $EditMenu
@onready var state_boxs: VBoxContainer = $StateBoxs
@onready var event_param: OptionButton = $MarginContainer/VBoxContainer/EventPrototype/Param
@onready var current_value: Button = %CurrentValue
var dialogue_resource:DialogueResource
const STATE_BOX = preload("res://addons/Cutscener/clazz/node/StatetreeNode/state_box.tscn")
var drag_on:bool = false
var drag_list:Array = [false,null]
var current_key_ct:int = 0
var current_dialogue_resource_path:String
enum ARGS_INDEX {
	MinIndex = 0,
	MaxIndex = 1,
	ExportIndex = 2,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX {
	LabelIndex = 0,
	MinIndex = 1,
	MaxIndex = 3,
	ExportIndex = 6,
}
enum ARGS_INDEX1 {
	ConditionLinkTypeIndex = 0,
	TypeIndexx = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	ExportIndex = 6,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX2 {
	ConditionLinkTypeIndex = 0,
	LabelIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	DeleteParamIndex = 6,
	ChooseFileIndex = 7,
	ChooseVec2Index = 8,
	ExportIndex = 9,
}
enum ARGS_INDEX2 {
	ConditionLinkTypeIndex = 0,
	TypeIndexx = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	ExportIndex = 6,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX3 {
	ConditionLinkTypeIndex = 0,
	LabelIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	DeleteParamIndex = 6,
	ChooseFileIndex = 7,
	ChooseVec2Index = 8,
	ExportIndex = 9,
}

##当前参数个数
var prop_ct:int = 1:
	set(i):
		updata_props()
		prop_ct=props.size()
		on_update_ct()
##存档数据		
var props:Array
func ready() -> void:
	updata_props()
	update_type(condition_prototype.get_child(CONTROL_INDEX2.ParamTypeIndex),condition_prototype.get_child(CONTROL_INDEX2.ConditionTypeIndex),condition_prototype.get_child(CONTROL_INDEX2.ConditionLinkTypeIndex))
	size.x = Vector2.ZERO.x
func update_type(param_type,condition_type,condition_link_type):
	param_type.clear()
	for type in CutscenerGlobal.VAR_TYPE.values():
		param_type.add_item(CutscenerGlobal.VAR_TYPE_DIC[type][0],type)
		param_type.set_item_disabled(get_index_by_id(param_type,type),true)
	condition_type.clear()
	for c_type in CutscenerGlobal.CONDITION_TYPE.values():
		condition_type.add_item(CutscenerGlobal.CONDITION_TYPE_DIC[c_type][0],c_type)
	condition_link_type.clear()
	for cl_type in CutscenerGlobal.CONDITION_LINK_TYPE.values():
		condition_link_type.add_item(CutscenerGlobal.CONDITION_LINK_TYPE_DIC[cl_type][0],cl_type)
	event_param.clear()
	for ec in EventData.EVENTS_CONFIG.values():
		event_param.add_item(str(ec)+"."+EventData.events_dic[ec][0].event_key_txt,ec)

func init_var():
	node_type=CutscenerGlobal.NODES.STATETREE_NODE
	CutscenerGlobal.NODE_TYPE[node_type] = ["StateTreeNode",self.title]
##获取存档数据	
func get_save(is_saving_other:bool=false):
	var params:Array
	for param:Control in state_boxs.get_children():
		params.append(param.get_save())
	node_save_data["props"] = params
	node_save_data["res_file"] = res_file.text
	node_save_data["title_name"] = title_list.get_item_text(title_list.get_selected_id())
	return node_save_data
	
##载入存档		
func load_save(combine_node_name:String = "NA",dic_raw:Dictionary = {}):
	await clean_all_param()
	var params:Array
	res_file.text = node_save_data["res_file"]
	update_res()
	for i in title_list.get_item_count():
		if title_list.get_item_text(i)==node_save_data["title_name"]:
			title_list.select(i)
			break
	var props:Array = node_save_data["props"]
	if !combine_node_name=="NA" and node_save_data.has(combine_node_name+"_props"):
		props = node_save_data[combine_node_name+"_props"]
		CutscenerGlobal.ACTION_LOG = "[%s]载入聚合node数据覆盖!" %self.name
	new_param(props)
	
##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]	
func new_param(p_list):
	for p in p_list:
		var b = STATE_BOX.instantiate()
		state_boxs.add_child(b)
		drag_off.connect(b.on_drag_off)
		b.load_save(p)
	
##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]
func _on_add_param_pressed() -> void:
	new_param([[[-1,-1]]])
	
func on_selected():
	pass
		
func updata_props():
	self.size.y=0
	props.clear()
	for n in get_children():
		if n.name.begins_with("Param") and n.visible:
			props.append(n)	
			
func on_update_ct():
	var c = get_child_count()
	
					
func clean_all_param():
	for n in get_children():
		if n.name.begins_with("Param"):
			n.queue_free()
			await n.tree_exite
			
func on_remove_param():
	prop_ct = 1

func _on_update_pressed() -> void:
	update_res()
##更新资源	
func update_res():
	title_list.clear()
	var res:DialogueConfig = ResourceLoader.load(res_file.text)
	if !res:return
	var dialogue_res:DialogueResource = res.dialogue_res
	dialogue_resource = dialogue_res
	current_dialogue_resource_path = res_file.text
	for t in dialogue_res.titles.keys():
		title_list.add_item(t)
	get_dialogues_txt(title_list.get_item_text(title_list.selected))
##获取对话资源中的内容	
func get_dialogues_txt(start_title:String):
	var index = dialogue_resource.lines.keys()
	var result:String
	dialogues.text = ""
	for i in index.size():
		index[i] = int(index[i])
	index.sort()
	for i in index:
		var line = dialogue_resource.lines[str(i)]
		var type = line["type"]
		match type:
			"title":
				result="[color=eb00eb]%s" %line["text"]
			"dialogue":
				result="[color=00ecfd]%s[color=ffffff]: %s" %[line["character"],line["text"]]
			"response":
				result="[color=ffffff]  --  [color=f8fc00]%s[color=ffffff]: %s" %[line["character"],line["text"]]
			"goto":
				result="[color=005711]%s" %line["next_id"]
		dialogues.text+= "%s\n" %result
func _on_child_exiting_tree(node: Node) -> void:
	return
	var i = node.get_index()-1
##全局脚本载入到CutscenerGlobal后的事件			

func on_load_global():
	var m_name
	if condition_prototype.get_child(CONTROL_INDEX2.ParamIndex).item_count > 0:
		m_name = condition_prototype.get_child(CONTROL_INDEX2.ParamIndex).get_item_text(condition_prototype.get_child(CONTROL_INDEX2.ParamIndex).selected)
	condition_prototype.get_child(CONTROL_INDEX2.ParamIndex).clear()
	for prop in CutscenerGlobal.CUTSCENE_BUS_STATE.keys():
		condition_prototype.get_child(CONTROL_INDEX2.ParamIndex).add_item(prop)
	select_by_name(condition_prototype.get_child(CONTROL_INDEX2.ParamIndex),m_name)
	
##根据下拉选项的内容选定			
func select_by_name(paratype_node,t_name):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_text(a) == t_name:
			paratype_node.select(a)
			break

##根据下拉选项的id返回对应的index			
func get_index_by_id(paratype_node,id):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_id(a) == id:
			return a

func _on_current_value_pressed() -> void:
	dialogues.visible = !dialogues.visible


func _on_title_list_item_selected(index: int) -> void:
	get_dialogues_txt(title_list.get_item_text(index))

func _on_dialogues_mouse_entered() -> void:
	return

func _on_dialogues_mouse_exited() -> void:
	dialogues.hide()
