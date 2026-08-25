extends MarginContainer
##存档设置界面的存档item
class_name UISaveFileItem
@export var save_file_item_config:UISaveFileItemConfig
@onready var background: ColorRect = $Background
@onready var save_name: Label = $MarginContainer/HBoxContainer/MC2/VBoxContainer/MC2/HBoxContainer/MC/SaveName
@onready var save_time: Label = $MarginContainer/HBoxContainer/MC2/VBoxContainer/MC/SaveTime
@onready var level: Label = $MarginContainer/HBoxContainer/MC2/VBoxContainer/MC2/HBoxContainer/MC2/Level
@onready var screen_shot: TextureRect = $MarginContainer/HBoxContainer/MC/ScreenShot
@onready var check: TextureRect = $MarginContainer/HBoxContainer/MC3/Check

var on_focus:bool = false
var on_selected:bool = false
signal selected
signal inited


func _ready() -> void:
	EventBus.save_file_id_update.connect(_on_save_file_id_update)
	EventBus.save_game.connect(_on_save_game)
	EventBus.delete_save.connect(_on_delete_save)
	set_focus_mode(Control.FOCUS_CLICK)
	background.hide()
	_on_save_file_id_update()
	
func init(save_file_item_config:UISaveFileItemConfig):
	self.save_file_item_config = save_file_item_config
	screen_shot.texture = save_file_item_config.screen_shot
	save_name.text = "[%s]%s" %[save_file_item_config.save_id,save_file_item_config.save_name]
	level.text = "关卡-%s" %str(save_file_item_config.level)
	save_time.text = save_file_item_config.save_time
	inited.emit()
	
func _on_mouse_entered() -> void:
	background.show()
	on_focus = true

func _on_mouse_exited() -> void:
	if !on_selected:
		background.hide()
	on_focus = false

func _on_gui_input(event: InputEvent) -> void:
	if !on_focus:return
	if event.is_action_pressed("uiselect"):
		selected.emit(self)
		grab_focus()

func _on_focus_entered() -> void:
	on_selected = true

func _on_focus_exited() -> void:
	on_selected = false
	background.hide()

func _on_save_file_id_update():
	if !check or !save_file_item_config:
		return
	if DataState.current_save_id == save_file_item_config.save_id:
		check.show()
		selected.emit(self)
	else :
		check.hide()

func _on_save_game():
	if DataState.current_save_id == save_file_item_config.save_id:
		DataState.update_screenshot(save_file_item_config.save_id)
		screen_shot.texture = DataState.current_screenshot
		save_file_item_config.screen_shot = DataState.current_screenshot
		selected.emit(self)
		

func _on_delete_save(save_id):
	if save_id == save_file_item_config.save_id:
		hide()
		queue_free()
