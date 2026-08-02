extends Node
## NPC 全局状态
##
## 管理 NPC 数据、对话方位、以及场景复制时 @export Node 的路径缓存。


#region Data
## 各 NPC 运行时数据（按需写入，结构由业务决定）
var npcs_data: Dictionary = {}

## 对应 NPC 是否处于玩家侧（对白/站位用）
## key: 场景/对象唯一名（如 "Npc_Sen"）
var dic_on_player: Dictionary = {
	"Npc_Sen": false,
	"Npc_An": false,
	"NPC_BloodKing": false,
}

## 对白时该 NPC 是否显示在左侧
## key: 同上；true = 左侧，false = 右侧
var dic_dialogue_side_left: Dictionary = {
	"Npc_Sen": false,
	"Npc_An": false,
	"NPC_BloodKing": true,
}
#endregion


#region Enum
## NPC 枚举 ID
enum NPC {
	SEN = 0,
	AN = 1,
	BLOODKING = 2,
}
#endregion


#region Export Node Cache
## 场景复制时，把 @export Node 的相对路径缓存下来，
## 避免复制实例仍指向原场景节点。
## 结构: [obj_name][组件节点名][导出节点名] = NodePath
## 例: NpcCacheExportNodes["NpcSen"]["HitBox"]["HurtTarget"] = NodePath("...")
var NpcCacheExportNodes: Dictionary = {}


## 将导出节点相对根节点的路径写入缓存
## [param root_node] 场景根（需有 obj_name，一般为 NPC 根）
## [param node] 持有 @export 的组件（如 HitBox / HurtBox）
## [param export_node] 被导出、需要在复制后重定向的节点
func add_to_export_node_cache(root_node: Node, node: Node, export_node: Node) -> void:
	if not is_instance_valid(root_node) or not is_instance_valid(node) or not is_instance_valid(export_node):
		return
	if not "obj_name" in root_node:
		push_warning("NpcState.add_to_export_node_cache: root_node 缺少 obj_name")
		return

	var obj_key: String = str(root_node.obj_name)
	var node_key: String = node.name
	var export_key: String = export_node.name
	var path: NodePath = root_node.get_path_to(export_node)

	if not NpcCacheExportNodes.has(obj_key):
		NpcCacheExportNodes[obj_key] = {}
	if not NpcCacheExportNodes[obj_key].has(node_key):
		NpcCacheExportNodes[obj_key][node_key] = {}
	# 已存在则跳过，避免重复写入
	if NpcCacheExportNodes[obj_key][node_key].has(export_key):
		return

	NpcCacheExportNodes[obj_key][node_key][export_key] = path


## 从缓存取出路径，并在当前 root 下解析为节点
## 调用前需已执行 [method add_to_export_node_cache]
func get_export_node_cache(root_node: Node, node: Node, export_node: Node) -> Node:
	if not is_instance_valid(root_node) or not is_instance_valid(node) or not is_instance_valid(export_node):
		return null
	if not "obj_name" in root_node:
		push_warning("NpcState.get_export_node_cache: root_node 缺少 obj_name")
		return null

	var obj_key: String = str(root_node.obj_name)
	var node_key: String = node.name
	var export_key: String = export_node.name

	if not NpcCacheExportNodes.has(obj_key) \
			or not NpcCacheExportNodes[obj_key].has(node_key) \
			or not NpcCacheExportNodes[obj_key][node_key].has(export_key):
		push_warning("NpcState.get_export_node_cache: 缓存未命中 %s/%s/%s" % [obj_key, node_key, export_key])
		return null

	var path: NodePath = NpcCacheExportNodes[obj_key][node_key][export_key]
	return root_node.get_node_or_null(path)


## 清除某个 NPC 的导出节点缓存（实例销毁时可选调用）
func clear_export_node_cache(obj_name: String = "") -> void:
	if obj_name.is_empty():
		NpcCacheExportNodes.clear()
	else:
		NpcCacheExportNodes.erase(obj_name)
#endregion
