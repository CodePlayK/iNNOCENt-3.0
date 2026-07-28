extends Node

var npcs_data:Dictionary

var dic_on_player={
	"Npc_Sen":false,
	"Npc_An":false,
	"NPC_BloodKing":false
}
var dic_dialogue_side_left={
	"Npc_Sen":false,
	"Npc_An":false,
	"NPC_BloodKing":true
}

enum NPC{
	SEN = 0,
	AN = 1,
	BLOODKING = 2,
}

var NpcCacheExportNodes:Dictionary={
	
} 
##将导出的node的路径加入缓存中,以在场景复制时正确指向新建对象中的node,而不是原node
##(被复制的场景的唯一名比如NpcSen,有导出node节点的node名,导出的node,用于执行root_node()的Node一般为场景根节点)
##从缓存中获取
func add_to_export_node_cache(root_node:Node,node:Node,export_node:Node):
	if NpcCacheExportNodes.has(root_node.obj_name):
		if NpcCacheExportNodes[root_node.obj_name].has(node.name):
			if NpcCacheExportNodes[root_node.obj_name][node.name].has(export_node.name):
				return
			NpcCacheExportNodes[root_node.obj_name][node.name][export_node.name]=root_node.get_path_to(export_node)
		else :
			NpcCacheExportNodes[root_node.obj_name][node.name]={export_node.name:root_node.get_path_to(export_node)}
	else :
		NpcCacheExportNodes[root_node.obj_name]={node.name:{export_node.name:root_node.get_path_to(export_node)}}

func get_export_node_cache(root_node:Node,node:Node,export_node:Node):
	return root_node.get_node(NpcCacheExportNodes[root_node.obj_name][node.name][export_node.name])
