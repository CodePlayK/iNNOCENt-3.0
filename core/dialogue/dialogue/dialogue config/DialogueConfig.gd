@tool
extends Resource
class_name DialogueConfig
#台词资源
@export var dialogue_res:DialogueResource:
	set(r):
		dialogue_res=r
		if r:on_update_dialogue_res(r)
var dialogue_checker_path:String
#用于显示气球的定位名，可以配置多个
@export var talkers:Array[String] 
#当前的有效台词资源
@export var current_res:String 
#当前标题
@export var title:String:
	set(r):
		title=r.strip_edges()

@export_multiline var title_list:String
@export var import:bool = false:
	set(f):
		import = f
		update()
@export var auto_next:bool = true
@export var balloon_color:Color
@export var line_end_wait_time:float = 1

func on_update_dialogue_res(dialogue_res:DialogueResource):
	if !dialogue_res:return
	title_list = ""
	for title in dialogue_res.titles.keys():
		title_list += "%s | " %title
	if !current_res:
		var p= dialogue_res.resource_path.get_file().get_basename()
		current_res = p
	return
func update():
	on_update_dialogue_res(dialogue_res)
