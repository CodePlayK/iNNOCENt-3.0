@tool
extends LineEdit
signal txt_update

func _on_text_changed(new_text: String) -> void:
	txt_update.emit(new_text,get_parent())
