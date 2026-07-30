extends MarginContainer
class_name MindTxtBox
@onready var dialogue_label: DialogueLabel = %DialogueLabel
@export var trans_time:float = 1
const trans_color:Color=Color("ffffff00")
const talker_name:Array[String] = ["M"]
var showing:bool = false
var is_waiting_for_input:bool = false
var dialogue_config:DialogueConfig
var dialogue_resource:DialogueResource
var nextable:bool=true
var enable:bool=false

func _ready() -> void:
	UiState.mind_txt_box = self
	Dialogue.talk_start.connect(on_talker_start)
	Dialogue.end_dialogue.connect(on_talker_end)
	
func dialogue_finished():
	hide_txt()

func on_talker_end():
	hide_txt()

func on_talker_start(current_talker:String,dialogue_config:DialogueConfig,dialogue_line:DialogueLine):
	if !talker_name.has(current_talker):
		return
	#Dialogue.current_talker = talker_name
	Dialogue.current_dialogue_balloon = self
	nextable=false
	enable = true
	dialogue_label.text=""
	is_waiting_for_input = false
	dialogue_label.dialogue_line = dialogue_line
	var txt = dialogue_line.text
	dialogue_line.text = "[center]%s" %txt
	dialogue_label.type_out()
	show_txt()
	await dialogue_label.finished_typing
	dialogue_line.text = "[center]%s" %txt
	nextable=true
	is_waiting_for_input = true	
	var l = Dialogue.dialogue_config.current_res+str(dialogue_line.id).split("@",true,0)[1]
	if Dialogue.dialogue_title_dic.has(dialogue_config.current_res):
		if Dialogue.dialogue_title_dic[dialogue_config.current_res].has(dialogue_config.title):
			return
		else :
			if Dialogue.dialogue_title_dic_tmp.has(l):
				if Dialogue.dialogue_title_dic_tmp[l]!=1:
					return			
	else :
		if Dialogue.dialogue_title_dic_tmp.has(l):
				if Dialogue.dialogue_title_dic_tmp[l]!=1:
					return	
					
	DialogueState.add_dialogue_history(DialogueState.player_name[0],txt)

func show_txt():
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self,"modulate",Color.WHITE,trans_time)
	await tw.finished
	tw.kill()
	showing = true
	
func hide_txt():
	enable = false
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self,"modulate",trans_color,trans_time)
	await tw.finished
	tw.kill()
	showing = false
	
func _unhandled_input(event: InputEvent) -> void:
	if !showing or !enable:return
	if not is_waiting_for_input: return
	if null!=Dialogue.dialogue_line and Dialogue.dialogue_line.responses.size() > 0: return
	if event.is_action_pressed("interactive"):
		Dialogue.next(Dialogue.dialogue_line.next_id)
		
