extends MarginContainer
@onready var background: ColorRect = $Background
@onready var item_texture: TextureRect = $MarginContainer/HBoxContainer/MarginContainer/ItemTexture
@onready var item_name: Label = $MarginContainer/HBoxContainer/MarginContainer2/ItemName
var item_config:ItemConfig
var on_focus:bool = false
signal selected


func init(item_config:ItemConfig):
	self.item_config = item_config
	item_texture.texture = item_config.item_texture_config.static_texture
	item_name.text = item_config.item_name

func _ready() -> void:
	background.hide()

func _on_mouse_entered() -> void:
	background.show()
	on_focus = true

func _on_mouse_exited() -> void:
	background.hide()
	on_focus = false

func _on_gui_input(event: InputEvent) -> void:
	if !on_focus:return
	if event.is_action_pressed("uiselect"):
		selected.emit(item_config)
