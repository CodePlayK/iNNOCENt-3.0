@tool
##技能UIitem
extends MarginContainer
class_name ABTUIItem
@export var import:bool:
	set(f):
		import = f
		if f:on_update()
@export var ABT_item_config:ABTItemConfig
@onready var base: Sprite2D = $base
@onready var panel: PanelContainer = $Panel
signal selected
var on_select:bool = false

func on_update():
	if ABT_item_config:
		print("on")
		ABT_item_config.ABT_texture_rect = base.region_rect
		ABT_item_config.ABT_texture = base.texture
	
func _ready() -> void:
	_on_mouse_exited()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	selected.connect(owner.on_ABT_item_selected)
	
func _on_mouse_entered() -> void:
	on_select = true
	panel.self_modulate = Color.WHITE

func _on_mouse_exited() -> void:
	on_select = false
	panel.self_modulate = Color.TRANSPARENT

func _on_gui_input(event: InputEvent) -> void:
	if !on_select:return
	if event.is_action("uiselect"):
		selected.emit(ABT_item_config)
