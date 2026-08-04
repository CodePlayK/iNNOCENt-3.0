extends Resource
class_name DebugCT
static var from_node_name:String
static var from_node:String
static var text:String
static func dp(text1,from_node1:Node = null):
	from_node = from_node1.get_path()
	from_node_name = from_node1.get_name()
	text = str(text1)
