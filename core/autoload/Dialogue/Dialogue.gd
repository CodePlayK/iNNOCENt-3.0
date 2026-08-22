@tool
extends Node
signal talk_start
signal end_dialogue

##全局单例台词
var dialogue_resource: DialogueResource
var temporary_game_states: Array = []
#台词配置
var dialogue_config:DialogueConfig:
	set(dc):
		dialogue_config=dc
		current_title=dc.title
		current_talker=dc.talkers
		
var current_talker:Array[String]
		
var current_dialogue_balloon:
	set(cdb):
		#Debug.dprintwarn(DebugCT.dp("设置气球[%s]" %cdb.get_path(),self))
		current_dialogue_balloon=cdb
var current_title:String
var current_start_obj
var current_start_title:String
#记录每条对话的执行次数：{对白资源名+标题名+[talker]}
var dialogue_title_dic:Dictionary
#记录每条对话的执行次数：{对白资源名+标题名+[talker]:次数}
var dialogue_title_dic_tmp:Dictionary


func set_dialogue_title_dic(title,ct):
	dialogue_title_dic[title] = int(ct)

var dialogue_line: DialogueLine:
	set(next_dialogue_line):
		if not next_dialogue_line:
			current_dialogue_balloon.dialogue_finished()
			#记录对话整体执行的次数，只会在整个话结束后统计，中断不会统计
			if dialogue_title_dic.has(dialogue_config.current_res):
				if dialogue_title_dic[dialogue_config.current_res].has(current_title):
					dialogue_title_dic[dialogue_config.current_res][current_title]+=1
				else:
					dialogue_title_dic[dialogue_config.current_res][current_title] = 1
			else :
				dialogue_title_dic[dialogue_config.current_res]={current_title:1}
			end_dialogue.emit()
			return
		dialogue_line = next_dialogue_line
		if dialogue_line.expression:
			dialogue_config.current_expression=dialogue_line.expression
		if !current_talker.has(dialogue_line.character):
			if current_dialogue_balloon:
				current_dialogue_balloon.dialogue_finished()
				#Debug.dprintwarn(DebugCT.dp("当前气球[%s][%s]" %[current_dialogue_balloon.get_path(),current_dialogue_balloon.dialogue_label.dialogue_line.text],self))

		talk_start.emit(dialogue_line.character,dialogue_config,dialogue_line)

	get:
		return dialogue_line

func _on_next_dialogue() -> void:
	next(dialogue_line.next_id)
	
func start(dialogue_config1:DialogueConfig,start_title:String = "",extra_game_states: Array = []) -> void:
	# 防止上一次未正常结束的残留
	if DialogueManager.has_method("_pending_method_mutations"):
		DialogueManager._pending_method_mutations.clear()
		DialogueManager._pending_method_states.clear()
	if dialogue_config1:dialogue_config = dialogue_config1
	temporary_game_states = extra_game_states
	current_start_title = dialogue_config.title
	dialogue_resource = dialogue_config.dialogue_res
	if start_title and dialogue_resource.titles.has(start_title):
		dialogue_config.title = start_title
	var d = await DialogueManager.get_next_dialogue_line(dialogue_resource, dialogue_config.title, temporary_game_states)
	if d and d.text:self.dialogue_line = d
	
func next(next_id: String) -> void:
	self.dialogue_line = await DialogueManager.get_next_dialogue_line(dialogue_resource, next_id, temporary_game_states)

func on_passed_title(title):
	current_title = title
	
func _ready() -> void:
	DialogueManager.passed_title.connect(on_passed_title)
