@tool
extends VBoxContainer
##节点公共菜单
@onready var node: GraphNode = $"../.."
@onready var index: LineEdit = $MarginContainer/HBoxContainer/Index
@export var index1: Button
var real_target

##默认标题
var base_text:String
##节点同级运行顺序
var base_index:int=0:
	set(i):
		base_index = i
		index.text=str(base_index)
		if real_target:
			real_target.text = "#" + str(base_index)
			
		
func _ready() -> void:
	base_text = node.title
	#if index1:real_target = get_parent().get_node(str(index1.name))
##更新标题
func _on_title_edit_text_changed(new_text: String) -> void:
	if new_text != "":
		node.title = new_text
	else:
		node.title = base_text
##index+
func _on_plus_button_down() -> void:
	base_index+=1
##index
func _on_min_pressed() -> void:
	base_index-=1
	
func _on_index_op_index_changed() -> void:
	base_index=type_convert(index.text,TYPE_INT)
