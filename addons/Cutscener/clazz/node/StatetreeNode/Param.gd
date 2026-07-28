@tool
extends OptionButton
signal param_selected
func _on_item_selected(index: int) -> void:
	param_selected.emit(index,self)

