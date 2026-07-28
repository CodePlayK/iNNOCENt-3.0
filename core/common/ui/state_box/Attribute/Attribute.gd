extends MarginContainer
class_name UIAttribute
@onready var state_name: Label = $MarginContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/StateName
@onready var background: ColorRect = $Background
@onready var max: Label = $MarginContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/Max
@onready var current: Label = $MarginContainer/HBoxContainer/MarginContainer2/VBoxContainer/HBoxContainer/Current
@onready var ui_bar: ProgressBar = $MarginContainer/HBoxContainer/MarginContainer2/VBoxContainer/UIBar

var on_focus:bool = false
signal selected

func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	background.hide()
	on_ready()
	
func on_ready():
	pass

func _on_mouse_entered() -> void:
	background.show()
	on_focus = true

func _on_mouse_exited() -> void:
	background.hide()
	on_focus = false

func _on_gui_input(event: InputEvent) -> void:
	if !on_focus:return
	if event.is_action_pressed("uiselect"):
		selected.emit()
