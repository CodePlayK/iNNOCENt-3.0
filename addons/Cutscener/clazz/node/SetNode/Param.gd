@tool
extends OptionButton
signal param_selected_set_node
func _on_item_selected(index: int) -> void:
		param_selected_set_node.emit(index,self)
