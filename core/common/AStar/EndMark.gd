extends Node2D
var flag:bool = false
@onready var color_rect: ColorRect = $StartMark/ColorRect
var last_cell_pos:Vector2
var current_cell:Vector2i
var current_cell_pos:Vector2
@onready var astar: AStarMap = $".."
	
func _physics_process(delta: float) -> void:
	if flag:
		global_position = get_global_mouse_position()

func _on_start_mark_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("drag"):
		flag = true
	elif event.is_action_released("drag") :
		flag = false
