extends Node2D
var drag_on:bool
var base_postion:Vector2
var base_mouse_postion:Vector2
@onready var line: Line2D = $Line2D
@onready var obj_name: Label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/ObjName
@onready var option_button: OptionButton = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/OptionButton
@onready var button: Button = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Button
@onready var label: Label = $MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/Label
@export var target:Node2D
@export var weight_machine_ui:Node2D
var npc:Npcs
var current_state
var state_machine:NpcStateManager
func init(sm:NpcStateManager):
	npc = sm.npc
	state_machine = sm
	option_button.clear()
	obj_name.text = npc.name
	for state in state_machine.all_states:
		option_button.add_item(state.name)
	if option_button.item_count>0:
		option_button.select(0)
		
func _process(delta: float) -> void:
	if !npc:return
	if drag_on:
		position=base_postion + get_viewport().get_mouse_position()-base_mouse_postion
	line.set_point_position(1,to_local(npc.get_screen_transform().origin))
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
