@tool
extends MarginContainer
class_name UISettingItem
#region onready
@onready var item_texture: TextureRect = $MarginContainer/HBoxContainer/MarginContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/HBoxContainer/MarginContainer2/ItemName
@onready var bg: HBoxContainer = $BG
@onready var bg_2: MarginContainer = $BG/BG2
@onready var background_2: ColorRect = $BG/BG2/Background2
@onready var background: ColorRect = $BG/BG1/Background
#endregion
##按钮背景颜色
@export var bk_color:Color=Color("85ffffa9")
##按钮确认颜色
@export var bk_conf_color:Color=Color("10bf00b9")
@export var update:bool = false:
	set(f):
		update = f
		if f:init()		
@export var setting_item:UiState.SETTING_ITEMS:
	set(f):
		setting_item = f
		init()		
@export var setting_item_config:UISettingItemConfig
var on_focus:bool = false
var check_first:bool = false
var check_conf:bool = false
var t_list:Array
signal selected

func _ready() -> void:
	bg.hide()
	init()
func init():
	var i = UiState.get_setting_item(setting_item)
	if i and item_texture and item_name:
		setting_item_config = i
		item_texture.texture = setting_item_config.texture
		item_name.text = setting_item_config.setting_name
		tooltip_text = setting_item_config.setting_txt
func _on_mouse_entered() -> void:
	background.color = bk_color
	background_2.color = bk_conf_color
	for t in t_list:
		t.kill()
	check_conf = false
	check_first = false		
	bg_2.size_flags_stretch_ratio = 0
	bg.show()
	on_focus = true

func _on_mouse_exited() -> void:
	if check_first:await hide_conf()
	bg.hide()
	on_focus = false
	check_conf = false
	check_first = false
	for t in t_list:
		t.kill()
	var t = bg_2.create_tween()	
	t.tween_property(bg_2,"size_flags_stretch_ratio",0,.5)
	
func _on_gui_input(event: InputEvent) -> void:
	if !on_focus:return
	if event.is_action_pressed("uiselect"):
		if check_conf:return
		if !check_first:
			show_conf()
			check_first=true
		else :
			check_conf = true
			selected.emit()
			_on_mouse_exited()
func show_conf():
	var t = bg_2.create_tween()
	t.tween_property(bg_2,"size_flags_stretch_ratio",20,.5)
	t_list.append(t)
	
func hide_conf():
	var t = bg_2.create_tween()
	t.tween_property(bg_2,"size_flags_stretch_ratio",0,.5)
	t_list.append(t)
	await t.finished
