@tool
extends HBoxContainer
@export var target:LineEdit
signal index_changed
var real_target:LineEdit
func _ready() -> void:
	real_target = get_parent().get_node(str(target.name))

func _on_plus_pressed() -> void:
	if !real_target:return
	real_target.text = str(type_convert(real_target.text,TYPE_INT)+1)
	index_changed.emit()
func _on_min_pressed() -> void:
	if !real_target:return
	real_target.text = str(type_convert(real_target.text,TYPE_INT)-1)
	index_changed.emit()
