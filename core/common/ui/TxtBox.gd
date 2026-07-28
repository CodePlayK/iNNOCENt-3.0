extends MarginContainer
class_name DialogueHistoryBox

@onready var trigger: MarginContainer = %Trigger
@onready var box: VBoxContainer = %Box
@onready var vc: VBoxContainer = %VC
@onready var pin: Button = %Pin
@onready var shader_crt: ColorRect = %ShaderCRT
@onready var txt_box: ScrollContainer = %TxtBox

var showing:bool = false
var on_showing:bool = false
var on_hiding:bool = false
var hidden_position:Vector2
var pined:bool = false

func _ready() -> void:
	UiState.dialogue_history_box = self
	hidden_position = position
	trigger.mouse_entered.connect(_on_trigger_mouse_entered)
	pin.mouse_exited.connect(_on_txt_box_mouse_exited)
	set_crt_shader(false)
	show()
	
func set_crt_shader(f):
	shader_crt.material.set_shader_parameter("enable",f)
##添加新talker的台词	
func add_new_talker_dialogue(current_index,dialogue_his_dic:Dictionary):
	var dh:DialogueHistory = DialogueState.dialogue_his_line.instantiate()
	box.add_child(dh)
	dh.init(dialogue_his_dic["lines"][0],dialogue_his_dic["talker"],dialogue_his_dic["left_side"])
	DialogueState.dialogue_his_box_dic[current_index] = [dh]
##添加当前talker的台词
func add_current_talker_dialogue(current_index,left_side:bool,line:String):
	var dh:DialogueHistory = DialogueState.dialogue_his_line.instantiate()
	box.add_child(dh)
	dh.init(line,"",left_side)
	DialogueState.dialogue_his_box_dic[current_index].append(dh)

func _on_trigger_mouse_entered() -> void:
	if on_showing or on_hiding:return
	on_showing = true
	await show_txt_history()
	on_showing = false
	showing = true
	
func _on_txt_box_mouse_exited() -> void:
	if Rect2(Vector2(), vc.size).has_point(get_local_mouse_position()):return
	if pined:return
	if on_hiding:return
	on_hiding = true
	await hide_txt_history()
	on_hiding = false
	showing = false
	
func show_txt_history():
	set_crt_shader(true)
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUINT)
	tw.set_ease(Tween.EASE_OUT)
	tw.tween_property(self,"position",hidden_position+Vector2(txt_box.size.x,0)*scale,1)
	await tw.finished
	tw.kill()
	
func hide_txt_history():
	var tw = create_tween()
	tw.set_trans(Tween.TRANS_QUINT)
	tw.set_ease(Tween.EASE_IN)
	tw.tween_property(self,"position",hidden_position,1)
	await tw.finished
	tw.kill()
	set_crt_shader(false)

func _on_button_pressed() -> void:
	pined = !pined

func _on_timer_timeout() -> void:
	if !showing:return
	if !Rect2(Vector2(), vc.size).has_point(get_local_mouse_position()):
		_on_txt_box_mouse_exited()
