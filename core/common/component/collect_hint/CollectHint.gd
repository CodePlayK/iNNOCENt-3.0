extends Area2D
@onready var hint_base: AnimatedSprite2D = $hintBase
@export var enable:bool = true
@export var obj:Node2D

func _ready() -> void:
	if !obj:
		obj = get_parent()
	hint_base.hide()
	enable = false

func _on_body_entered(body: Node2D) -> void:
	enable = true
	PlayerState.on_collection_hint = true
	hint_base.show()
	
func _on_body_exited(body: Node2D) -> void:
	enable = false
	PlayerState.on_collection_hint = false
	hint_base.hide()
	UiState.item_txt_box.hide_box()

func _unhandled_input(event: InputEvent) -> void:
	if !enable:return
	if event.is_action_pressed("interactive"):
		UiState.item_txt_box.show_item(obj.item)
		UiState.current_interact_item = obj
