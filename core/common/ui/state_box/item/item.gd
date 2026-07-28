extends MarginContainer
@onready var background: ColorRect = $Background
@onready var item_texture: TextureRect = $MarginContainer/HBoxContainer/MarginContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/HBoxContainer/MarginContainer2/ItemName
var item:ItemState.ITEMS
var item_config:ItemConfig
var on_focus:bool = false
signal selected
func init(i:ItemState.ITEMS):
	item = i
	self.item_config = ItemState.get_item_config(i)
	item_texture.texture = item_config.item_texture_config.static_texture
	item_name.text = item_config.item_name

func update():
	item_name.text ="%s [%s]" %[item_config.item_name,str(ItemState.current_item_dic[item][0])]

func on_select_item_update():
	if item == ItemState.ui_current_select_item:
		background.show()
	else :
		background.hide()

func _ready() -> void:
	background.hide()
	ItemState.ui_current_select_item_update.connect(on_select_item_update)

func _on_mouse_entered() -> void:
	background.show()
	on_focus = true

func _on_mouse_exited() -> void:
	if item == ItemState.ui_current_select_item:return
	background.hide()
	on_focus = false

func _on_gui_input(event: InputEvent) -> void:
	if !on_focus:return
	if event.is_action_pressed("uiselect"):
		ItemState.ui_current_select_item = item
		selected.emit(item_config)
