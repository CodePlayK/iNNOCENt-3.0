extends MarginContainer
var drag_on:bool
var base_postion:Vector2
var base_mouse_postion:Vector2
@onready var line: Line2D = $Line2D
@onready var obj_name: Label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ObjName
@onready var option_button: OptionButton = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionButton
@onready var button: Button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Button
@onready var label: Label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label
@export var start_state_name:String = "chase"
@export var target:Node2D
##在行内的位置,x=左侧比例,y=右侧比例
@export var x_stretch_ratio:Vector2 = Vector2(1,10)
@export var weight_machine_ui:Node2D
var npc:Npcs
var current_state
var state_machine:NpcStateManager
var index_state:Dictionary
@onready var node_2d: Node2D = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ObjName/Node2D

func init(sm:NpcStateManager):
	npc = sm.npc
	state_machine = sm
	option_button.clear()
	obj_name.text = npc.name
	var i =0
	for state in state_machine.all_states:
		option_button.add_item(state.name)
		index_state[state.name]= i
		i+=1
	if option_button.item_count>0:
		if index_state.has(start_state_name):
			option_button.select(index_state[start_state_name])
		else :
			option_button.select(11)
	EventBus._add_debug(self,x_stretch_ratio,30)
		
func _process(delta: float) -> void:
	if !npc:return
	obj_name.text = npc.name
	if drag_on:
		position=base_postion + get_viewport().get_mouse_position()-base_mouse_postion
	line.set_point_position(1,node_2d.to_local(npc.get_screen_transform().origin))
	if state_machine:
		if current_state != state_machine.current_state.name:
			label.text = state_machine.current_state.name
func _on_button_pressed() -> void:
	if state_machine:
		state_machine.string2state(option_button.get_item_text(option_button.selected),self)


func _on_margin_container_gui_input(event: InputEvent) -> void:
	if !drag_on and event.is_action_pressed("drag"):
		base_postion = position
		base_mouse_postion =  get_viewport().get_mouse_position()
		drag_on = true
	if drag_on and event.is_action_released("drag"):
		drag_on = false

func _on_button_2_pressed() -> void:
	line.visible = !line.visible

func _on_button_3_pressed() -> void:
	if weight_machine_ui:
		weight_machine_ui.visible = !weight_machine_ui.visible
