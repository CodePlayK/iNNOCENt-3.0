@icon("res://addons/at-icons/control/speech_bubble_ellipsis.svg")

extends Node2D
class_name DialogueContext
@export var has_master:bool = true
@export_enum("BODY_ENTER","MOUSE_ENTER") var interact_type = "BODY_ENTER"
@export var dialogue_config:DialogueConfig
@export var cutscener_debug:bool = false:
	set(f):
		cutscener_debug = f
		if cutscener_runner:cutscener_runner.print_debug = cutscener_debug
@onready var dialogue_balloon: DialogueBalloon = $DialogueBalloon
@onready var cutscener_runner: Node2D = $CutscenerRunner
var current_title
var obj

func _ready() -> void:
	if !has_master:
		on_master_ready(get_parent())

func on_master_ready(master) -> void:
	if has_master:
		obj = master.obj
	else :
		obj = master
	dialogue_balloon.set_level(dialogue_config)
	self.scale = self.scale / obj.scale
	Dialogue.end_dialogue.connect(end_dialogue)
	if !obj is Player and obj.dialogue_config:
		obj.dialogue_config.current_level = LevelState.current_level
		dialogue_balloon.talker_name = obj.dialogue_config.talkers
		dialogue_config = obj.dialogue_config
	dialogue_balloon.dialogue_config = dialogue_config
	if obj is Player:
		dialogue_balloon.talker_name = obj.dialogue_config.talkers
		return
	match interact_type:
		"BODY_ENTER":
			obj.interaction.body_entered.connect(_body_entered)
			obj.interaction.body_exited.connect(_body_exited)
		"MOUSE_ENTER":
			obj.interaction.mouse_entered.connect(_mouse_entered)
			obj.interaction.mouse_exited.connect(_mouse_exited)
	DialogueManager.dialogue_ended.connect(on_dialogue_ended)
	current_title = dialogue_config.title
	cutscener_runner.cutscener_data = dialogue_config.dialogue_checker_path
	cutscener_runner.print_debug = cutscener_debug
	
func _body_entered(body: Node2D) -> void:
	if !obj.interaction.enable or PlayerState.get_player_control_lock(self):
		return
	if dialogue_config.onece and Dialogue.get_dialogue_title_time(dialogue_config)>0:
		return
	if dialogue_config.use_local_res and dialogue_config.dialogue_res:
		pass
	else:
		#Debug.dprintinfo(DebugCT.dp("[%s]在当前场景[%s]中无台词更新" %[dialogue_config.title,CutsceneState.current_cutscene],self))
		dialogue_config.dialogue_res = DialogueState.dialogue_file_res[DialogueState.get_latest_cutscene_contain_title(dialogue_config.title)]
		dialogue_config.current_res=CutsceneState.current_cutscene
	#Dialogue.current_talker=obj.dialogue_config.talkers
	Dialogue.current_start_obj = obj
	Dialogue.start(dialogue_config)
	
func _body_exited(body: Node2D) -> void:
	if Dialogue.current_start_obj == obj:
		Dialogue.end_dialogue.emit()


func _mouse_entered() -> void:
	if !obj.interaction.enable or PlayerState.get_player_control_lock(self):
		return
		
		
	if FileAccess.file_exists(dialogue_config.dialogue_checker_path):
		var c = await cutscener_runner.run("Dialogue")
		if c and dialogue_config.dialogue_res.titles.has(c):
			dialogue_config.title = c
	if dialogue_config.use_local_res and dialogue_config.dialogue_res:
		pass
	else:
		var d:DialogueResource= DialogueState.dialogue_file_res[CutsceneState.current_cutscene]
		#判断当前cutscene state下是否有台词更新
		if !d.get_titles().has(dialogue_config.title):
			#Debug.dprintinfo(DebugCT.dp("[%s]在当前场景[%s]中无台词更新" %[dialogue_config.title,CutsceneState.current_cutscene],self))
			pass
		elif dialogue_config.current_res!=CutsceneState.current_cutscene:
			dialogue_config.dialogue_res=DialogueState.dialogue_file_res[CutsceneState.current_cutscene]
			dialogue_config.current_res=CutsceneState.current_cutscene
	Dialogue.current_start_obj = obj
	Dialogue.start(dialogue_config)
	
func _mouse_exited() -> void:
	if Dialogue.current_start_obj == obj:
		Dialogue.end_dialogue.emit()

func start_dialogue(dialogue_config1:DialogueConfig):
	dialogue_balloon.start(obj,dialogue_config1)

func end_dialogue():
	if obj is Player:
		pass
	dialogue_balloon.end_talk()
	

func on_dialogue_ended(res:Resource):
	return
	var c = await cutscener_runner.run("Dialogue")
	if c:current_title= c
