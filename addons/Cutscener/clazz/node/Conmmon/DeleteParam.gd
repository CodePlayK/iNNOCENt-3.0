@tool
extends Button
signal remove_param
var index:int = 0

func _ready() -> void:
	index = get_parent().get_index()
func _on_pressed() -> void:
	var p_node = get_parent()
	p_node.queue_free()
	await p_node.tree_exited
	remove_param.emit()
	
