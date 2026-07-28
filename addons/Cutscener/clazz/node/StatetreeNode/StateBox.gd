@tool
extends MarginContainer
var drag_on = false
var on_mouse_drag:bool = false
var base_postion
var base_mouse_postion
@onready var box: VBoxContainer = $Box
@onready var back_color: ColorRect = $BackColor
@onready var num_ber: HBoxContainer = $Box/NumBer
@onready var state_tree_node: GraphNode = $"../.."

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
	TypeIndex = 0,
	ConditionLinkTypeIndex = 1,
	ParamIndex = 2,
	ParamTypeIndex = 3,
	ConditionTypeIndex = 4,
	Param2Index = 5,
	ExportIndex = 6,
}
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX1 {
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
##原型中每个组件在get_child()时的index顺序
enum CONTROL_INDEX_TITLE {
	TypeIndex = 0,
	ConditionLinkType = 1,
	DialoguePathIndex = 2,
	ChooseFileIndex = 3,
	ParamIndex = 4,
	ConditionTypeIndex = 5,
	Param2Index = 6,
	DeleteParamIndex =7,
	ChooseVec2Index = 8,
	ExportIndex = 9,
	ParamTypeIndex = 10,
}


func on_drag_off():
	if on_mouse_drag and state_tree_node.drag_list and state_tree_node.drag_list[0]:
		state_tree_node.drag_list[0] = false
		state_tree_node.state_boxs.move_child(state_tree_node.drag_list[1],get_index())
		state_tree_node.drag_list[1] = null
	box.position = Vector2.ZERO
func _process(delta: float) -> void:
	if drag_on:
		box.position=base_postion + get_viewport().get_mouse_position()-base_mouse_postion
	if state_tree_node and back_color and  state_tree_node.drag_on and Rect2(Vector2(), self.size).has_point(get_local_mouse_position()):
		back_color.show()
		on_mouse_drag = true
	elif back_color :
		back_color.hide()
		on_mouse_drag = false
		
func _on_line_edit_gui_input(event: InputEvent) -> void:
	if ! drag_on and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		base_postion = box.position
		base_mouse_postion =  get_viewport().get_mouse_position()
		drag_on = true
		state_tree_node.drag_list[0] = true
		state_tree_node.drag_list[1] = self
		state_tree_node.drag_on = true
	if drag_on and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
		drag_on = false
		state_tree_node.drag_on = false
		state_tree_node.drag_off.emit()

##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]	
func new_param(p_list):
	for p in p_list:
		var pn
		var DialoguePath
		if int(p[ARGS_INDEX1.TypeIndex]) == 0:
			pn = state_tree_node.condition_prototype.duplicate()
		elif int(p[ARGS_INDEX1.TypeIndex]) == 1:
			pn = state_tree_node.event_prototype.duplicate()
		elif int(p[ARGS_INDEX_TITLE.TypeIndex]) == 2:
			pn = state_tree_node.title_prototype.duplicate()
			DialoguePath = pn.get_node("DialoguePath")
		var Type = pn.get_node("Type")
		var ConditionLinkType = pn.get_node("ConditionLinkType")
		var ConditionType = pn.get_node("ConditionType")
		var Param = pn.get_node("Param")
		var Param2 = pn.get_node("Param2")
		var ChooseVec2 = pn.get_node("ChooseVec2")
		var ChooseFile = pn.get_node("ChooseFile")
		var ParamType = pn.get_node("ParamType")
		Type.text = str(p[ARGS_INDEX1.TypeIndex])
		var type
		if int(p[ARGS_INDEX1.TypeIndex]) == 0:
			type =  CutscenerGlobal.CUTSCENE_BUS_STATE[str(p[ARGS_INDEX1.ParamIndex])]
			pn.get_node("Param").param_selected.connect(on_param_item_selected)
			Param2.text = p[ARGS_INDEX1.Param2Index]
		elif int(p[ARGS_INDEX1.TypeIndex]) == 1:
			var res:EventConfig = EventData.events_dic[int(p[ARGS_INDEX1.ParamIndex].split(".")[0])][0]
			type = res.event_value_type
			pn.get_node("Param").param_selected.connect(on_event_param_item_selected)
			Param2.text = p[ARGS_INDEX1.Param2Index]
		elif int(p[ARGS_INDEX_TITLE.TypeIndex]) == 2:
			type = TYPE_INT
			Param2.text = str(p[ARGS_INDEX_TITLE.Param2Index])
		on_updata_type(type,ChooseVec2,ChooseFile,ConditionType)
		select_by_name(Param,str(p[ARGS_INDEX1.ParamIndex]))
		box.add_child(pn)
		if int(p[ARGS_INDEX_TITLE.TypeIndex]) == 2:
			DialoguePath.txt_update.connect(on_text_changed)
			ChooseFile.file_choosed.connect(_on_choose_file_file_choosed)
			ChooseFile.show()
			DialoguePath.text = p[ARGS_INDEX_TITLE.DialoguePathIndex]
			on_text_changed(p[ARGS_INDEX_TITLE.DialoguePathIndex],pn)
			select_by_name(Param,p[ARGS_INDEX_TITLE.ParamIndex])
		if int(p[ARGS_INDEX_TITLE.TypeIndex]) != 2:
			select_by_id(ParamType,type)
		select_by_id(ConditionType,p[ARGS_INDEX1.ConditionTypeIndex])
		select_by_id(ConditionLinkType,p[ARGS_INDEX1.ConditionLinkTypeIndex])
		pn.visible = true	
		pn.get_node("DeleteParam").remove_param.connect(on_remove_param)
		
func on_param_item_selected(i:int,param:OptionButton):
	select_by_id(param.get_parent().get_child(CONTROL_INDEX1.ParamTypeIndex),CutscenerGlobal.CUTSCENE_BUS_STATE[param.get_item_text(i)])
	var type =  CutscenerGlobal.CUTSCENE_BUS_STATE[param.get_item_text(i)]
	on_updata_type(type,param.get_parent().get_child(CONTROL_INDEX1.ChooseVec2Index),param.get_parent().get_child(CONTROL_INDEX1.ChooseFileIndex),param.get_parent().get_child(CONTROL_INDEX1.ConditionTypeIndex))
func on_event_param_item_selected(i:int,param:OptionButton):
	var type =  EventData.events_dic[int(param.text.split(".")[0])][0].event_value_type
	select_by_id(param.get_parent().get_child(CONTROL_INDEX1.ParamTypeIndex),type)
	on_updata_type(type,param.get_parent().get_child(CONTROL_INDEX1.ChooseVec2Index),param.get_parent().get_child(CONTROL_INDEX1.ChooseFileIndex),param.get_parent().get_child(CONTROL_INDEX1.ConditionTypeIndex))


func load_save(args:Array):
	var num_arg = args.pop_front()
	num_ber.get_child(CONTROL_INDEX.MinIndex).text = str(num_arg[ARGS_INDEX.MinIndex])
	num_ber.get_child(CONTROL_INDEX.MaxIndex).text = str(num_arg[ARGS_INDEX.MaxIndex])
	new_param(args)

func get_save():
	var args :Array
	for p in box.get_children():
		if p.name == "BoxBar":continue
		var pc = p.get_children()
		if p.name == "NumBer":
			args.append([
				pc[CONTROL_INDEX.MinIndex].text,
				pc[CONTROL_INDEX.MaxIndex].text,
			])
		else :
			var type = p.get_node("Type")
			if type.text == "2":
				args.append([
				pc[CONTROL_INDEX_TITLE.TypeIndex].text,#当前条件的连接条件类型
				pc[CONTROL_INDEX_TITLE.ConditionLinkType].get_selected_id(),
				pc[CONTROL_INDEX_TITLE.DialoguePathIndex].text,#变量名
				pc[CONTROL_INDEX_TITLE.ParamIndex].get_item_text(pc[CONTROL_INDEX_TITLE.ParamIndex].get_selected_id()),#变量名
				pc[CONTROL_INDEX_TITLE.ConditionTypeIndex].get_selected_id(),#条件类型
				pc[CONTROL_INDEX_TITLE.Param2Index].text,#判断目标值
				pc[CONTROL_INDEX_TITLE.ExportIndex].is_export#是否导出	
			])
			else :
				args.append([
				pc[CONTROL_INDEX1.LabelIndex].text,
				pc[CONTROL_INDEX1.ConditionLinkTypeIndex].get_selected_id(),#当前条件的连接条件类型
				pc[CONTROL_INDEX1.ParamIndex].get_item_text(pc[CONTROL_INDEX1.ParamIndex].get_selected_id()),#变量名
				pc[CONTROL_INDEX1.ParamTypeIndex].get_selected_id(),#变量类型
				pc[CONTROL_INDEX1.ConditionTypeIndex].get_selected_id(),#条件类型
				pc[CONTROL_INDEX1.Param2Index].text,#判断目标值
				pc[CONTROL_INDEX1.ExportIndex].is_export#是否导出	
			])
	return args
func on_remove_param():
	state_tree_node.size.y = 0
##根据下拉选项的id选定
func select_by_id(paratype_node,type_id):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_id(a) == int(type_id):
			paratype_node.select(a)
##根据下拉选项的内容选定			
func select_by_name(paratype_node,t_name):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_text(a) == str(t_name):
			paratype_node.select(a)
			break

##根据下拉选项的id返回对应的index			
func get_index_by_id(paratype_node,id):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_id(a) == id:
			return a
func on_updata_type(type,ChooseVec2,ChooseFile,ConditionType):
	ChooseVec2.hide()
	ChooseFile.hide()
	if type==TYPE_VECTOR2:
		ChooseVec2.show()
	elif type==TYPE_OBJECT:
		ChooseFile.show()
	if ConditionType:
		ConditionType.clear()
		for t in CutscenerGlobal.VAR_TYPE_DIC[int(type)][3]:
			ConditionType.add_item(CutscenerGlobal.CONDITION_TYPE_DIC[t][0],t)	


func _on_del_pressed() -> void:
	hide()
	queue_free()

##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]
func _on_add_param_pressed() -> void:
	new_param([[0,0,CutscenerGlobal.CUTSCENE_BUS_STATE.keys()[0],0,0,""]])

func _on_add_event_pressed() -> void:
	new_param([[1,0,"0.",0,0,""]])
##[当前条件的连接条件类型,变量名,变量类型,条件类型,判断目标值]	
func new_param_event(p_list):
	for p in p_list:
		var pn = state_tree_node.event_prototype.duplicate()
		var ConditionLinkType = pn.get_node("ConditionLinkType")
		var ConditionType = pn.get_node("ConditionType")
		var Param = pn.get_node("Param")
		var Param2 = pn.get_node("Param2")
		var ChooseVec2 = pn.get_node("ChooseVec2")
		var ChooseFile = pn.get_node("ChooseFile")
		var ParamType = pn.get_node("ParamType")
		var Type = pn.get_node("Type")
		Type.text = str(p[ARGS_INDEX1.TypeIndex])
		select_by_id(Param,int(p[ARGS_INDEX1.ParamIndex]))
		Param2.text = p[ARGS_INDEX1.Param2Index]
		var type = typeof(EventData.events_dic.keys()[p[ARGS_INDEX1.ParamIndex]])
		on_updata_type(type,ChooseVec2,ChooseFile,ConditionType)
		box.add_child(pn)
		select_by_id(ConditionType,p[ARGS_INDEX1.ConditionTypeIndex])
		select_by_id(ConditionLinkType,p[ARGS_INDEX1.ConditionLinkTypeIndex])
		pn.visible = true	
		pn.get_node("DeleteParam").remove_param.connect(on_remove_param)
		pn.get_node("Param").param_selected.connect(on_param_item_selected)

func _on_add_tree_pressed() -> void:
	new_param([[2,0,state_tree_node.current_dialogue_resource_path,"0",0,""]])
	
func on_text_changed(new_path:String,c):
	if !FileAccess.file_exists(new_path):return
	var title_list = c.get_child(CONTROL_INDEX_TITLE.ParamIndex)
	title_list.clear()
	var res:DialogueConfig = ResourceLoader.load(new_path)
	if !res:return
	var dialogue_res:DialogueResource = res.dialogue_res
	for t in dialogue_res.titles.keys():
		title_list.add_item(t)	
func _on_choose_file_file_choosed(new_path:String,c) -> void:
	on_text_changed(new_path,c)
