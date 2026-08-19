@tool
extends TabContainer
##所有全局变量
var all_globals: Dictionary
@onready var state_tree: Tree = $"Enable Autoloads/TabContainer/StateBus/StateTree"
@onready var method_tree: Tree = $"Enable Autoloads/TabContainer/MethodBus/MethodTree"
const TAB_0 = "配置Autoloads"

func _init() -> void:
	CutscenerGlobal.refresh_setting_autoload_config.connect(on_refresh_setting_autoload_config)

func _ready() -> void:
	set_tab_title(0, TAB_0)

##刷新setting中的autoload列表
func on_refresh_setting_autoload_config():
	if method_tree == null or state_tree == null:
		return
	load_all_global(method_tree, CutscenerGlobal.CONFIG_DATA_DIC["method_bus"])
	load_all_global(state_tree, CutscenerGlobal.CONFIG_DATA_DIC["state_bus"])
	CutscenerGlobal.load_all_method_state_from_global.emit()

func load_all_global(global_tree: Tree, list: Array):
	var project = ConfigFile.new()
	var err = project.load("res://project.godot")
	if err != OK:
		push_error("Cutscener: 无法读取 project.godot")
		return
	all_globals.clear()
	if project.has_section("autoload"):
		for key in project.get_section_keys("autoload"):
			if key == "CutscenerGlobal":
				continue
			# 不再依赖 has_node：编辑器时序下经常失败
			all_globals[key] = project.get_value("autoload", key)
	global_tree.clear()
	var root = global_tree.create_item()
	for name in all_globals.keys():
		var item: TreeItem = global_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		if list and not list.is_empty():
			item.set_checked(0, name in list)
		item.set_text(0, name)
		item.add_button(1, get_theme_icon("Edit", "EditorIcons"))
		var path_text: String = str(all_globals.get(name, "")).replace("*", "")
		item.set_text(2, path_text)
	global_tree.set_column_expand(0, false)
	global_tree.set_column_custom_minimum_width(0, 250)
	global_tree.set_column_expand(1, false)
	global_tree.set_column_custom_minimum_width(1, 40)
	global_tree.set_column_title(0, "Autoload")
	global_tree.set_column_title(1, "打开")
	global_tree.set_column_title(2, "Path")
	global_tree.set_column_titles_visible(true)

func _on_method_tree_item_selected() -> void:
	set_tree_selected(method_tree, CutscenerGlobal.CONFIG_DATA_DIC["method_bus"])

func set_tree_selected(global_tree: Tree, list: Array):
	var item = global_tree.get_selected()
	if item == null:
		return
	var is_checked = not item.is_checked(0)
	item.set_checked(0, is_checked)
	var text: String = item.get_text(0)
	if is_checked:
		if not list.has(text):
			list.append(text)
	else:
		list.erase(text)

func _on_state_tree_item_mouse_selected(_position: Vector2, _mouse_button_index: int) -> void:
	set_tree_selected(state_tree, CutscenerGlobal.CONFIG_DATA_DIC["state_bus"])

func _on_method_tree_button_clicked(item: TreeItem, _column: int, _id: int, _mouse_button_index: int) -> void:
	var path: String = item.get_text(2)
	if ResourceLoader.exists(path):
		EditorInterface.edit_resource(load(path))
