@icon("res://core/common/resource/icon/WeightMachineUI.svg")
extends Node2D
##总权重条容器
@onready var bar: HBoxContainer = $WeightMachineUi/VBC/PanelContainer/Bar
##总权重数据容器
@onready var text: HBoxContainer = $WeightMachineUi/VBC/Text
##总权重数据显示原型
@onready var weight_data: PanelContainer = $WeightMachineUi/VBC/Text/WeightData
##总权重条原型
@onready var weight_bar: PanelContainer = $WeightMachineUi/VBC/PanelContainer/Bar/WeightBar
##权重机名
@onready var wight_machine_title: Label = $WeightMachineUi/VBC/WightMachineTitle/HBoxContainer/WightMachineTitle
##权重明细
@onready var detail: PanelContainer = $WeightMachineUi/VBC/Detail
##所有权重明细容器
@onready var weight_state_debug_ui: VBoxContainer = $WeightMachineUi/VBC/Detail/WeightStateDebugUI
##权重目标容器原型,包含1*state_name与n*weight_detail_bar
@onready var weight_state: VBoxContainer = $WeightMachineUi/VBC/Detail/WeightStateDebugUI/WeightState
##权重目标状态名原型
@onready var state_name: PanelContainer = $WeightMachineUi/VBC/Detail/WeightStateDebugUI/StateName
##权重条原型
@onready var weight_detail_bar: MarginContainer = $WeightMachineUi/VBC/Detail/WeightStateDebugUI/WeightDetailBar
##权重条过度时间
@export var trans_time:float = .1
##负数权重条颜色
@export var negtive_color:Color
##实际总权重字典{"目标状态名":weight_bar}
var w_bars:Dictionary
##实际总权重数据字典{"目标状态名":weight_data}
var w_datas:Dictionary
##权重颜色{"目标状态名":权重node的modulate}
var w_color:Dictionary
##实际权重明细字典{"目标状态名":{"权重名":权重对象}}
var d_weight_states:Dictionary
@onready var timer: Timer = $WeightMachineUi/Timer
@onready var line: Line2D = $Line

@export var flash_time: float = .2
@export var detail_state_name_color:Color = "00000082"
@export var detail_state_name_flash_color:Color
var flag:bool
##最终选定的状态
var fink:String
var drag_on:bool = false
var base_postion:Vector2
var base_mouse_postion:Vector2
var obj:Node2D
func init_weightmachine(wm:WeightMachine):
	obj = wm.obj
	wight_machine_title.text = wm.name
	weight_bar.hide()
	weight_data.hide()
	for k in wm.weight_sum_dic.keys():
		var p = weight_bar.duplicate()
		p.modulate = wm.get_node(NodePath(k)).modulate
		w_color[k] = p.modulate
		p.get_child(0).text = k
		bar.add_child(p)
		w_bars[k] = p
		p.show()
		var wd = weight_data.duplicate()
		wd.modulate = wm.get_node(NodePath(k)).modulate
		w_datas[k] = wd.get_child(0)
		text.add_child(wd)
		wd.show()
	for state in wm.weight_dic.keys():
		var w_state = weight_state.duplicate()
		weight_state_debug_ui.add_child(w_state)
		d_weight_states[state] = {}
		w_state.show()
		var s_name = state_name.duplicate()
		d_weight_states[state]["state_name"] = s_name
		s_name.get_child(0).text = state
		s_name.show()
		w_state.add_child(s_name)
		for weight in wm.weight_dic[state]:
			var w_detail_bar = weight_detail_bar.duplicate()
			d_weight_states[state][weight.name] = w_detail_bar
			w_detail_bar.get_child(0).get_child(0).self_modulate = w_color[state]
			w_detail_bar.show()
			w_detail_bar.get_child(1).get_child(0).text = weight.name
			w_state.add_child(w_detail_bar)
			
func update(wm:WeightMachine,fin_k1):
	fink = fin_k1
	for k in wm.weight_sum_dic.keys():
		w_bars[k].modulate = w_color[k]
		if wm.weight_sum_dic[k]>0:w_bars[k].show()	
		w_datas[k].text = "%s | %s" %[str(wm.weight_sum_dic[k]).pad_decimals(2),wm.debug_dic[k]]
		d_weight_states[k]["state_name"].self_modulate = detail_state_name_color
	var sum:float = 0
	for k in wm.weight_sum_dic.keys():
		sum+=max(wm.weight_sum_dic[k],0)
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	for k in wm.weight_sum_dic.keys():
		tween.parallel().tween_property(w_bars[k].get_child(0),"size_flags_stretch_ratio", max(wm.weight_sum_dic[k],0)/sum,trans_time)
		for w in wm.weight_dic[k]:
			if w.weight< 0 :
				d_weight_states[k][w.name].get_child(0).get_child(0).self_modulate = negtive_color
			else :
				d_weight_states[k][w.name].get_child(0).get_child(0).self_modulate = w_color[k]
			tween.parallel().tween_property(d_weight_states[k][w.name].get_child(0).get_child(0),"size_flags_stretch_ratio", abs(w.weight)/abs(w.confirmed_weight),trans_time)
			tween.parallel().tween_property(d_weight_states[k][w.name].get_child(0).get_child(1),"size_flags_stretch_ratio", 1-abs(w.weight)/abs(w.confirmed_weight),trans_time)
			d_weight_states[k][w.name].get_child(1).get_child(1).text = "%s / %s" %[str(w.weight).pad_decimals(2),abs(w.confirmed_weight)]
	await tween.finished
	if sum!=0 and fin_k1:
		w_bars[fin_k1].modulate = Color.WHITE
		timer.start(flash_time)
		for k in wm.weight_sum_dic.keys():
			if max(wm.weight_sum_dic[k],0) == 0:
				w_bars[k].hide()
	else :
		pass
	tween.kill()

func _on_timer_timeout() -> void:
	flag=!flag
	if !w_bars.has(fink):return
	if flag:
		if fink=="attack0":
			pass
		w_bars[fink].modulate = Color.WHITE
		d_weight_states[fink]["state_name"].self_modulate = detail_state_name_flash_color
	else :
		w_bars[fink].modulate = w_color[fink]
		d_weight_states[fink]["state_name"].self_modulate = detail_state_name_color
		
func _on_show_detail_pressed() -> void:
	detail.visible = !detail.visible


func _on_detail_gui_input(event: InputEvent) -> void:
	if !drag_on and event.is_action_pressed("drag"):
		base_postion = position
		base_mouse_postion =  get_viewport().get_mouse_position()
		drag_on = true
	if drag_on and event.is_action_released("drag"):
		drag_on = false
func _process(delta: float) -> void:
	if drag_on:
		position=base_postion + get_viewport().get_mouse_position()-base_mouse_postion
	line.set_point_position(1,to_local(obj.get_screen_transform().origin))
