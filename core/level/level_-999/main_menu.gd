extends VBoxContainer
@onready var menu_1: VBoxContainer = $VBoxContainer/menu1
@onready var menu_2: MarginContainer = $VBoxContainer/menu2
@onready var menu_1r: MarginContainer = $VBoxContainer/menu1R
@onready var menu_3: VBoxContainer = $VBoxContainer/menu3

func _ready() -> void:
	default_view()

func _on_read_save_pressed() -> void:
	save_file_view()
	pass # Replace with function body.

func _on_back_2_main_pressed() -> void:
	default_view()	
	pass # Replace with function body.


func default_view():
	menu_2.hide()
	menu_1r.show()
	menu_3.hide()	
	menu_1.show()


func save_file_view():
	menu_2.show()
	menu_3.show()
	menu_1r.hide()
	menu_1.hide()
