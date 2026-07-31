@icon("res://core/common/resource/icon/dialogue.svg")
extends Node2D
class_name DialogueContext
@export var dialogue_config:DialogueConfig
@export var cutscener_debug:bool = false:
	set(f):
		cutscener_debug = f
		if cutscener_runner:cutscener_runner.print_debug = cutscener_debug
@onready var dialogue_balloon: DialogueBalloon = $DialogueBalloon
@onready var cutscener_runner: Node2D = $CutscenerRunner
var current_title
var obj

func on_master_ready(master) -> void:
	obj = master.obj
	dialogue_balloon.talker_name = obj.talker_name
	self.scale = self.scale / obj.scale
	Dialogue.end_dialogue.connect(end_dialogue)
	if !obj is Player and obj.dialogue_config:
		dialogue_config = obj.dialogue_config
	dialogue_balloon.dialogue_config = dialogue_config
	if obj is Player:return
	obj.interaction.body_entered.connect(_body_entered)
	obj.interaction.body_exited.connect(_body_exited)
	DialogueManager.dialogue_ended.connect(on_dialogue_ended)
	current_title = dialogue_config.title
	cutscener_runner.cutscener_data = dialogue_config.dialogue_checker_path
	cutscener_runner.print_debug = cutscener_debug
	
func _body_entered(body: Node2D) -> void:
	if !obj.interaction.enable:return
	var d:DialogueResource= DialogueState.dialogue_file_res[CutsceneState.current_cutscene]
	#判断当前cutscene state下是否有台词更新
	if obj.dialogue_debug and !d.get_titles().has(dialogue_config.title):
		Debug.dprintinfo(DebugCT.dp("[%s]在当前场景[%s]中无台词更新" %[dialogue_config.title,CutsceneState.current_cutscene],self))
	elif dialogue_config.current_res!=CutsceneState.current_cutscene:
		dialogue_config.dialogue_res=DialogueState.dialogue_file_res[CutsceneState.current_cutscene]
		dialogue_config.current_res=CutsceneState.current_cutscene
	#Dialogue.current_talker=obj.dialogue_config.talkers
	Dialogue.current_start_obj = obj
	Dialogue.start(dialogue_config)
	
func _body_exited(body: Node2D) -> void:
	if Dialogue.current_start_obj == obj:
		Dialogue.end_dialogue.emit()

func start_dialogue(dialogue_config1:DialogueConfig):
	dialogue_balloon.start(obj,dialogue_config1)

func end_dialogue():
	dialogue_balloon.end_talk()

func on_dialogue_ended(res:Resource):
	return
	var c = await cutscener_runner.run("Dialogue")
	if c:current_title= c
