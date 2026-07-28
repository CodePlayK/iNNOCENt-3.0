extends MarginContainer
class_name ItemTxtBox
@onready var item_txt: RichTextLabel = %ItemTxt
@onready var item_texture: TextureRect = $VBoxContainer/MarginContainer2/HBoxContainer/MarginContainer2/HBoxContainer/MarginContainer/ItemTexture
@onready var flashlight_count_event: Node = $FlashlightCountEvent
@export var trans_time:float = 1
@export var txt_trans_time:float = .2
const trans_color:Color=Color("ffffff00")
var showing:bool = false
var enable:bool=false
var item_config:ItemConfig
var item:ItemState.ITEMS

func _ready() -> void:
	hide()
	UiState.item_txt_box = self

func show_item(item1:ItemState.ITEMS):
	if !showing:
		item = item1
		item_config = ItemState.get_item_config(item)
		show_box()
		item_txt.text = item_config.item_txt
		item_texture.texture = null
		item_texture.texture = item_config.item_texture_config.static_texture
		await show_item_txt()
		showing = true
	else :
		hide_box()
func show_box():
	show()
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self,"modulate",Color.WHITE,trans_time)
	await tw.finished
	tw.kill()
	showing = true
	enable = true
	
func hide_box():
	enable = false
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self,"modulate",trans_color,trans_time)
	await tw.finished
	tw.kill()
	showing = false

func _unhandled_input(event: InputEvent) -> void:
	if !showing or !enable or !UiState.current_interact_item:return
	if event.is_action_pressed("interactive"):
		UiState.state_box.add_item(item)
		hide_box()
		flashlight_count_event.update()
		
func show_item_txt():
	item_txt.visible_ratio = 0
	var it = item_txt.create_tween()
	it.tween_property(item_txt,"visible_ratio",1,txt_trans_time)
	await it.finished
	it.kill()
