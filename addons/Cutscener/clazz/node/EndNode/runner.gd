@tool
extends Node
var node_type = 4
signal finished
var condition_result:bool = true
var condition_result_index:int = -1
func run(dic):
	await RenderingServer.frame_post_draw
	##CutscenerGlobal.ACTION_LOG = "------EndRunner[%s]正在运行!------" %dic["title"]
	CutscenerGlobal.cutscener_ended.emit()
	##CutscenerGlobal.ACTION_LOG = "------运行结束~------"
	finished.emit()
	return condition_result_index
