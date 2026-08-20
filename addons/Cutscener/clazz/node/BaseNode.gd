extends GraphNode
class_name BaseGraphNode
@onready var popdown_menu = %EditMenu
var node_type: CutscenerGlobal.NODES
@export var unconnect: Array[CutscenerGlobal.NODES]
@onready var title_edit: LineEdit = $EditMenu/EditMenu/MarginContainer/HBoxContainer/TitleEdit
@onready var copy: Button = $EditMenu/EditMenu/EditMenu/copy
@onready var timer: LineEdit = $EditMenu/EditMenu/EditMenu/timer
@onready var delete: Button = $EditMenu/EditMenu/EditMenu/delete
@onready var clear: Button = $EditMenu/EditMenu/EditMenu/clear
@onready var edit_menu: VBoxContainer = %EditMenu
##节点数据
var node_save_data: Dictionary
##复制节点时的数据
var duplicate_data: Dictionary
##是否有保存聚合节点数据
var protected: bool = false

func _init() -> void:
	self.node_selected.connect(_on_node_selected)
	self.node_deselected.connect(_on_node_deselected)
	CutscenerGlobal.load_global.connect(on_load_global)
	init_var()
	init()

func on_load_global() -> void:
	pass

func naming_node_and_add_2_global(generate_name: bool = true):
	if generate_name:
		self.name = CutscenerGlobal.get_nid(self.name, get_instance_id())
	CutscenerGlobal.NODE_INST[self.name] = self

func _ready() -> void:
	delete.pressed.connect(on_delete_button_pressed)
	copy.pressed.connect(on_copy_button_pressed)
	clear.pressed.connect(on_clear_button_pressed)
	popdown_menu_visible(false)
	set_meta("node_type", node_type)
	ready()

func ready():
	return
func init_var():
	return
func init():
	return

func _on_node_selected() -> void:
	popdown_menu_visible(true)
	on_selected()

func on_selected():
	return

func _on_node_deselected() -> void:
	popdown_menu_visible(false)
	on_deselected()

func on_deselected():
	return

func get_save_data(is_saving_other: bool = false):
	node_save_data["position.x"] = self.position.x
	node_save_data["position.y"] = self.position.y
	node_save_data["position_offset.x"] = self.position_offset.x
	node_save_data["position_offset.y"] = self.position_offset.y
	node_save_data["name"] = self.name
	node_save_data["node_type"] = node_type
	node_save_data["timer"] = timer.text
	node_save_data["title"] = self.title
	node_save_data["index_by_parent"] = edit_menu.base_index
	get_save(is_saving_other)
	return node_save_data

func get_save(is_saving_other: bool = false):
	pass

func load_save_data(dic: Dictionary, combine_node_name: String = "NA", dic_raw: Dictionary = {}):
	node_save_data = dic
	if dic.has("position_offset.x"):
		self.position_offset.x = dic["position_offset.x"]
	if dic.has("position_offset.y"):
		self.position_offset.y = dic["position_offset.y"]
	if dic.has("position.x"):
		self.position.x = dic["position.x"]
	if dic.has("position.y"):
		self.position.y = dic["position.y"]
	if dic.has("title"):
		self.title = dic["title"]
		if title_edit:
			title_edit.text = str(dic["title"])
	if dic.has("timer"):
		timer.text = str(dic["timer"])
	if dic.has("index_by_parent"):
		edit_menu.base_index = int(dic["index_by_parent"])
	load_save(combine_node_name, dic_raw)

func load_save(combine_node_name: String = "NA", dic_raw: Dictionary = {}):
	pass

func popdown_menu_visible(flag):
	if popdown_menu:
		popdown_menu.visible = flag
		self.size.y = 0

func delete_self(is_delete: bool = true):
	if is_delete and protected:
		var flag = await CutscenerGlobal.popup("该节点属于其他聚合节点,删除会导致聚合节点不可用!! \n确认要删除吗??", "警告!")
		if not flag:
			return
	on_delete(is_delete)
	if CutscenerGlobal.WORK_SPACE:
		CutscenerGlobal.WORK_SPACE.clear_node_connection(self.name)
	CutscenerGlobal.NODE_INST.erase(self.name)
	self.name = "NA"
	self.hide()
	self.queue_free()
	await tree_exited

func on_delete(is_delete: bool = true):
	pass
func on_delete_button_pressed():
	delete_self(true)

func on_copy_button_pressed():
	DisplayServer.clipboard_set(self.name)

func on_clear_button_pressed():
	CutscenerGlobal.clear_node_connection.emit(self.name)

func run_node():
	run()

func run():
	pass

func duplicate_node(_BaseGraphNode):
	pass

func on_save_other():
	var old_name = self.name
	var parts = self.name.split("_")
	var base = parts[0] if parts.size() > 0 else self.name
	var new_name = base + "_" + str(Time.get_ticks_msec())
	CutscenerGlobal.CONNECTION_LIST_MAP.append([old_name, new_name])
	save_as(new_name)

func save_as(_new_name: String):
	pass
