@tool
extends Resource
class_name DialogueConfig
##当前的台词资源
@export var dialogue_res:DialogueResource:
	set(r):
		dialogue_res=r
		if r:on_update_dialogue_res(r)
var dialogue_checker_path:String
#用于显示气球的定位名，可以配置多个
@export var talkers:Array[String] 
#当前的有效台词资源
@export var current_res:String 
@export var use_local_res:bool  = false
##只执行一次
@export var onece:bool  = false
@export var current_level:LevelState.LEVELS =LevelState.LEVELS.LEVEL_CURRENT
#当前标题
@export var title:String:
	set(r):
		title=r.strip_edges()
#当前表情
@export var current_default_expression:String="idle":
	set(ce):
		current_default_expression=ce
		on_update_current_expression(ce)
		
@export_multiline var title_list:String
@export var import:bool = false:
	set(f):
		import = f
		update()
@export var balloon_color:Color = Color("000000f0")

	

func on_update_dialogue_res(dialogue_res:DialogueResource):
	if !dialogue_res:return
	title_list = ""
	for title in dialogue_res.titles.keys():
		title_list += "%s | " %title
	if !current_res:
		var p= dialogue_res.resource_path.get_file().get_basename()
		current_res = p
	return
	
func on_update_current_expression(ce:String):
	return

func update():
	on_update_dialogue_res(dialogue_res)
