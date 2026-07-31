extends Node2D
class_name DialogueBalloon
@export var talker_name:Array[String]
#region onrady
@onready var balloon: Control = $Balloon
@onready var margin: MarginContainer = $Balloon/VB/background/Margin
@onready var hint_sprite = $Balloon/VB/background/Margin/HB/VB/HB/MC/Hint
@onready var character_label: RichTextLabel = $Balloon/VB/background/Margin/HB/VB/CharacterLabel
@onready var dialogue_label:DialogueLabel=$Balloon/VB/background/Margin/HB/VB/HB/DialogueLabel
@onready var responses_menu: VBoxContainer = %Responses
@onready var background =$Balloon/VB/background
@onready var response_margin =  %responseMargin
@onready var background_color: ColorRect = $Balloon/VB/background/BackgroundMC/BackgroundColor
@onready var background_mc: MarginContainer = $Balloon/VB/background/BackgroundMC
@onready var pointer_right = $Balloon/VB/MC/HB/MC2/PointerRight
@onready var pointer_left = $Balloon/VB/MC/HB/MC/PointerLeft
#@onready var response_style_box =preload("res://core/common/dialogue_ballon/dialogue/response style box focus.tres")
@onready var screen_checker_r = %ScreenCheckerR
@onready var screen_checker_l = %ScreenCheckerL
@onready var vb = $Balloon/VB
@onready var dialogue_start_timer: Timer = $DialogueStartTimer
@onready var dialogue_ended_timer: Timer = $DialogueEndedTimer
@onready var timer = $DialogueEndTimer
@onready var typeout_timer = $TypeoutTimer
@onready var response: MarginContainer = $Balloon/VB/responseMargin/Response
@onready var response_background: ColorRect = $Balloon/VB/responseMargin/Response/ResponseBackground

#endregion
var balloon_visiable:bool=false
var temp_position_l:Vector2
var temp_position_r:Vector2
#最大长度
var max_x=0
var temp_margin=6
var left_side_flag=false
var resource: DialogueResource
var is_waiting_for_input: bool = false
var nextable:bool=true
var enable:bool=true
var last_talk_obj
@export var dialogue_config:DialogueConfig
var current_id:String
var back_color_tween:Tween
@export_group("Debug")
@export var p_talk_too_fast:bool = false
var tween_killed:bool = false

func _ready() -> void:
	Dialogue.talk_start.connect(on_talker_start)
	hide_balloon()
	margin.size = Vector2.ZERO
	response_margin.size = Vector2.ZERO
	DialogueManager.mutated.connect(_on_mutation)
	
	
func dialogue_finished():
	hide_balloon()	
	
func on_talker_start(current_talker:String,d:DialogueConfig,dialogue_line:DialogueLine):
	if !talker_name.has(current_talker):
		return
	#Dialogue.current_talker = talker_name
	Dialogue.current_dialogue_balloon = self
	hide_balloon()
	if back_color_tween:back_color_tween.kill()
	var last_backcolor_mc_size = background.size.x
	for item in responses_menu.get_children():
		item.get_child(1).text=""
		item.queue_free()
	dialogue_label.text=""
	character_label.text=""
	max_x=0
	is_waiting_for_input = false
#		自动配置对话框颜色
	background_color.color=dialogue_config.balloon_color
	pointer_right.color=dialogue_config.balloon_color
	pointer_left.color=dialogue_config.balloon_color
	response_background.color=dialogue_config.balloon_color
	#pointer_right.material.set_shader_parameter("color",background_color.color)
	#pointer_left.material.set_shader_parameter("color",background_color.color)
	character_label.visible = not dialogue_line.character.is_empty()
	character_label.text = dialogue_line.character+":"
	dialogue_label.modulate.a = 0
	dialogue_label.dialogue_line = dialogue_line
	#if null==dialogue_line.next_id or ""==dialogue_line.next_id:
	hint_sprite.hide()
	#Show any responses we have
	responses_menu.modulate.a = 0
	margin.size = Vector2.ZERO
	response_margin.size = Vector2.ZERO
	#配置多选项
	if dialogue_line.responses.size() > 0:
		for response1 in dialogue_line.responses:
			var item = response.duplicate(0)
			item.get_child(1).mouse_filter = 0
			item.name = "Response%d" % responses_menu.get_child_count()
			if not response1.is_allowed:
				item.name = String(item.name) + "Disallowed"
				item.modulate.a = 0.4
			item.get_child(1).text = response1.text
			item.get_child(1).size.x=item.get_child(1).get_content_width()+5
			item.show()
			responses_menu.add_child(item)
			configure_menu()
	#	预计算左右位置
	temp_position_l= get_left_side_position()
	temp_position_r= get_right_side_position()
#	判断当前对话框边界是否超出屏幕，超出则反向
	if left_side_flag:
		self.position=temp_position_l
	else :
		self.position=temp_position_r
	await RenderingServer.frame_post_draw
	show_balloon()
	background_mc.set("theme_override_constants/margin_right",background.size.x-last_backcolor_mc_size)
	dialogue_label.modulate.a = 1
	tween_killed = false
	back_color_tween = background_color.create_tween()
	back_color_tween.finished.connect(on_tween_finshed)
	back_color_tween.set_trans(Tween.TRANS_CUBIC)
	back_color_tween.set_ease(Tween.EASE_OUT)
	background_mc.show()
	back_color_tween.tween_property(background_mc,"theme_override_constants/margin_right",0,.5)
	max_x=0
	if not dialogue_line.text.is_empty():
		show_balloon()
		nextable=false
		dialogue_label.type_out()
		await dialogue_label.finished_typing
		if back_color_tween and !tween_killed and back_color_tween.is_running():
			await back_color_tween.finished
			back_color_tween.kill()
		nextable=true

		# Wait for input
	if dialogue_line.responses.size() > 0:
		responses_menu.modulate.a = 1
	elif dialogue_line.time != null:
		var time = dialogue_line.text.length() * 0.05 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		is_waiting_for_input = true
		#if dialogue_config.auto_next:
				#await get_tree().create_timer(dialogue_config.line_end_wait_time).timeout
				#if enable and current_id == dialogue_line.id:
					#next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
	hint_sprite.show()	
	#判断是否为第一次对白，是才进入历史	
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
	DialogueState.add_dialogue_history(talker_name[0],dialogue_line.text)
	
func end_talk():
	typeout_timer.stop()
	typeout_timer.start()
	DialogueManager.dialogue_ended.emit(null)
	if !nextable:
		nextable=true
	hide_balloon()
		
func configure_menu() -> void:
	balloon.focus_mode = Control.FOCUS_NONE
	var items = get_responses()
	for i in items.size():
		var item: Control = items[i]
		item.get_child(1).focus_mode = Control.FOCUS_ALL
		item.get_child(1).focus_neighbor_left = item.get_child(1).get_path()
		item.get_child(1).focus_neighbor_right = item.get_child(1).get_path()
		if i == 0:
			item.get_child(1).focus_neighbor_top = item.get_child(1).get_path()
			item.get_child(1).focus_previous = item.get_child(1).get_path()
		else:
			item.get_child(1).focus_neighbor_top = items[i - 1].get_child(1).get_path()
			item.get_child(1).focus_previous = items[i - 1].get_child(1).get_path()

		if i == items.size() - 1:
			item.get_child(1).focus_neighbor_bottom = item.get_child(1).get_path()
			item.get_child(1).focus_next = item.get_child(1).get_path()
		else:
			item.get_child(1).focus_neighbor_bottom = items[i + 1].get_child(1).get_path()
			item.get_child(1).focus_next = items[i + 1].get_child(1).get_path()
		if !item.get_child(1).mouse_entered.is_connected(_on_response_mouse_entered):
			item.get_child(1).mouse_entered.connect(_on_response_mouse_entered.bind(item))
		if !item.get_child(1).gui_input.is_connected(_on_response_gui_input):
			item.get_child(1).gui_input.connect(_on_response_gui_input.bind(item))
	items[0].get_child(1).grab_focus()
# Get a list of enabled items
func get_responses() -> Array:
	var items: Array = []
	for child in responses_menu.get_children():
		if "Disallowed" in child.name: continue
		items.append(child)
	return items

### Signals
func _on_mutation(mutation:Dictionary) -> void:
	is_waiting_for_input = false
	#hide_balloon()

func _on_response_mouse_entered(item: Control) -> void:
	if !enable:return
	if "Disallowed" in item.name: return
	item.get_child(1).grab_focus()

func _on_response_gui_input(event: InputEvent, item: Control) -> void:
	if !enable:return
	if "Disallowed" in item.name: return
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == 1:
				#Dialogue.current_talker = DialogueState.player_name
				DialogueState.add_dialogue_history(DialogueState.player_name[0],Dialogue.dialogue_line.responses[item.get_index()].text)
				dialogue_finished()
				Dialogue.next(Dialogue.dialogue_line.responses[item.get_index()].next_id)
	elif event.is_action_pressed("ui_accept") and item in get_responses():
		Dialogue.current_talker = DialogueState.player_name
		dialogue_finished()
		Dialogue.next(Dialogue.dialogue_line.responses[item.get_index()].next_id)
		if Dialogue.dialogue_line.responses.has(item.get_index()): 
			DialogueState.add_dialogue_history(DialogueState.player_name[0],Dialogue.dialogue_line.responses[item.get_index()].text)

func _on_balloon_gui_input(event: InputEvent) -> void:
	return
	if !event is InputEventMouseButton:return
	if !enable:return
	if not is_waiting_for_input: return
	if null!=Dialogue.dialogue_line and Dialogue.dialogue_line.responses.size() > 0: return
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == 1:
		Dialogue.next(Dialogue.dialogue_line.next_id)

func _unhandled_input(event: InputEvent) -> void:
	if !enable:return
	if UiState.item_txt_box.showing:return
	if PlayerState.on_collection_hint:return
	if not is_waiting_for_input: return
	if null!=Dialogue.dialogue_line and Dialogue.dialogue_line.responses.size() > 0: return
	if event.is_action_pressed("interactive"):
		Dialogue.next(Dialogue.dialogue_line.next_id)

func get_left_side_position() -> Vector2:
	if Dialogue.dialogue_line.responses.size() > 0:
		for item in responses_menu.get_children():
			max_x=max(max_x,item.get_child(1).get_content_width())
	else:
		max_x=0
		if max_x>dialogue_label.get_content_width()+6:
			temp_margin=3
		else :
			temp_margin=3
	temp_position_l=Vector2(-(max(max_x,dialogue_label.get_content_width(),character_label.get_content_width()))*self.scale.x-temp_margin,0)
	return temp_position_l

func get_right_side_position() -> Vector2:
	temp_position_r=Vector2.ZERO
	return temp_position_r
	
func hide_balloon():
	enable = false
	response_margin.modulate.a=0
	background.modulate.a=0
	pointer_left.self_modulate.a=.01
	pointer_right.self_modulate.a=.01
	balloon_visiable=false
	for item in responses_menu.get_children():
		item.get_child(1).text=""
		item.queue_free()
	
func show_balloon():
	enable = true
	if !nextable:
		await dialogue_label.finished_typing
		nextable=true
	response_margin.modulate.a=.95
	background.modulate.a=.95
	if left_side_flag:
		pointer_left.self_modulate.a=.01
		pointer_right.self_modulate.a=.95
	else:
		pointer_right.self_modulate.a=.01
		pointer_left.self_modulate.a=.95
	vb.visible = true
	balloon_visiable=true


func _on_typeout_timer_timeout():
	hide_balloon()

func _on_dialogue_ended_timer_timeout() -> void:
	if null!=last_talk_obj and !last_talk_obj.on_talk:
		hide_balloon()

func on_tween_finshed():
	if back_color_tween: 
		tween_killed = true
		back_color_tween.kill()

func _on_screen_checker_l_screen_exited() -> void:
	if !Dialogue.dialogue_line:return
	temp_position_r= get_right_side_position()
#	判断当前对话框边界是否超出屏幕，超出则反向
	left_side_flag=false
	if enable:
		pointer_right.self_modulate.a=.01
		pointer_left.self_modulate.a=.95	
	self.position=temp_position_r

func _on_screen_checker_r_screen_exited() -> void:
	if !Dialogue.dialogue_line:return
	temp_position_l= get_left_side_position()
#	判断当前对话框边界是否超出屏幕，超出则反向
	left_side_flag=true
	if enable:
		pointer_left.self_modulate.a=.01
		pointer_right.self_modulate.a=.95
	self.position=temp_position_l
