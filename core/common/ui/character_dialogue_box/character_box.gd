extends MarginContainer
class_name CharacterBox

@onready var img_box_top_marg: MarginContainer = $VBoxContainer/ImgBoxTopMarg
@onready var img_box: MarginContainer = $VBoxContainer/ImgBox
@onready var timer: Timer = $Timer
@onready var mouse_timer: Timer = $MouseTimer
@onready var ui_bar: UIbar = $VBoxContainer/ImgBoxTopMarg2/UIBar
@export var unselect_modulate:Color = Color("727272")
@export var selected_modulate:Color = Color("ffffff")
@export var img_box_top_marg_hide:float = 20
@export var img_box_top_marg_show:float = 0
@export var time:float = .5
@export var is_player:bool = false
@export var health_config:HealthConfig
@onready var shader_crt: ColorRect = %ShaderCRT

var box_selected:bool = false
var on_changing:bool = false

func _ready() -> void:
	modulate = unselect_modulate
	ui_bar.bar_max_value = health_config.max_health
	EventBus.player_health_damaged.connect(on_player_health_damaged)
	EventBus.player_health_healed.connect(on_player_health_healed)
	if is_player:
		UiState.player_character_box = self

func _on_call_player_pressed() -> void:
	if on_changing:return
	on_changing = true
	var real_ratio
	if box_selected:
		real_ratio = img_box_top_marg_hide
	else:
		real_ratio = img_box_top_marg_show
	var twn = img_box_top_marg.create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",real_ratio,time)
	await twn.finished
	twn.kill()
	box_selected = !box_selected
	on_changing = false

func _on_mouse_entered() -> void:
	mouse_timer.start()

func _on_mouse_exited() -> void:
	box_deselect()
	
func box_select():
	if on_changing or box_selected:return
	on_changing = true
	var twn = img_box_top_marg.create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",img_box_top_marg_show,time)
	twn.parallel().tween_property(self,"modulate",selected_modulate,time)
	await twn.finished
	twn.kill()
	timer.start()
	box_selected = true
	on_changing = false

func box_deselect():
	if on_changing or !box_selected:return
	timer.stop()
	on_changing = true
	var twn = img_box_top_marg.create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",img_box_top_marg_hide,time)
	twn.parallel().tween_property(self,"modulate",unselect_modulate,time)
	await  twn.finished
	twn.kill()
	box_selected = false
	on_changing = false

func _on_timer_timeout() -> void:
	if !box_selected:return
	if !check_has_mouse():
		_on_mouse_exited()
	else :
		pass
		
func check_has_mouse():
	return Rect2(img_box.position, img_box.size).has_point(get_local_mouse_position())

func _on_mouse_timer_timeout() -> void:
	if check_has_mouse():
		box_select()

func _on_img_box_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("uiselect"):
		if !UiState.state_box.showing:
			UiState.state_box.show_box()
		else :
			UiState.state_box.hide_box()
func on_player_health_damaged():
	ui_bar.bar_decrease(health_config.current_health)
	
func on_player_health_healed():
	ui_bar.bar_grow(health_config.current_health)
