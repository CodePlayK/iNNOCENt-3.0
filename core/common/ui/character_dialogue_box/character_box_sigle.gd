extends VBoxContainer
class_name CharacterBox
@onready var img_box_top_marg: MarginContainer = %ImgBoxTopMarg
@onready var img_box: MarginContainer = %ImgBox
@onready var timer: Timer = $Timer
@onready var ui_bar: UIbar = %UIBar
@onready var texture_rect: TextureRect = $ImgBox/HBoxContainer/VBoxContainer/MarginContainer/TextureRect
@onready var test: Label = %TEST
@onready var delay_timer: Timer = $delay_timer

@export var character_box_config:CharacterBoxConfig:
	set(cbc):
		character_box_config=cbc
@export var is_player:bool = false
@export var health_config:HealthConfig

var box_selected:bool = false
var on_changing:bool = false
var on_showing:bool = false
@export var is_prototype:bool = true
@export var delay_time:Vector2 = Vector2(0.5,1)

func _ready() -> void:
	hide()
	img_box.size_flags_stretch_ratio=0
	size_flags_stretch_ratio=0
	img_box_top_marg.size_flags_stretch_ratio=20
	timer.wait_time = character_box_config.drag_time
	modulate = character_box_config.unselect_modulate
	ui_bar.bar_max_value = health_config.max_health
	timer.timeout.connect(_on_timer_timeout)
	EventBus.player_health_damaged.connect(on_player_health_damaged)
	EventBus.player_health_healed.connect(on_player_health_healed)
	EventBus.remove_character_box.connect(on_remove_character_box)
	EventBus.remove_all_character_box.connect(on_remove_all_character_box)
	Dialogue.end_dialogue.connect(on_end_dialogue)
	Dialogue.talk_start.connect(on_talk_start)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	if character_box_config.is_player:
		UiState.player_character_box = self
	
func on_level_changed(fl,tl):
	#if character_box_config.is_player:return
	if is_prototype:
		return
	on_remove_character_box(character_box_config,character_box_config.level_id)

#卸载角色box事件
func on_remove_character_box(cbc:CharacterBoxConfig,el:LevelState.LEVELS):
	if is_prototype:
		return
	if cbc.character_box_id!=character_box_config.character_box_id or el!=character_box_config.level_id:return
	UiState.set_character_box_showing(character_box_config,false,self)
	on_remove_all_character_box()
	
#卸载角色box事件
func on_remove_all_character_box():
	#if character_box_config.is_player:return
	delay_timer.stop()
	anime_dead()
	
#出生动画
func anime_born():
	if is_prototype:return
	delay_timer.start(randf_range(delay_time.x,delay_time.y))
	return

func anime_dead():
	if is_prototype:return
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_IN)
	#twn.tween_property(self,"size_flags_stretch_ratio",0,0.5)
	twn.parallel().tween_property(img_box,"size_flags_stretch_ratio",0,0.5)
	twn.parallel().tween_property(img_box_top_marg,"size_flags_stretch_ratio",20,0.5)
	await twn.finished
	twn.kill()
	queue_free()	
	return
		
#台词事件
func on_talk_start(character:String,dialogue_config:DialogueConfig,dialogue_line:DialogueLine):
	#Debug.dprintwarn(DebugCT.dp("台词角色[%s]，characterBox当前角色[%s]" %[character,str(character_box_config.character_names)],self))
	if !character_box_config.character_names.has(character):return
	box_show()
	return

func on_end_dialogue():
	box_deselect()

func on_character_box_config_upate():
	return

func box_show():
	if on_changing or box_selected:return
	on_changing = true
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",character_box_config.img_box_top_marg_show,character_box_config.animation_time)
	twn.parallel().tween_property(self,"size_flags_stretch_ratio",character_box_config.wide_marg_show,character_box_config.animation_time)
	twn.parallel().tween_property(self,"modulate",character_box_config.selected_modulate,character_box_config.animation_time)
	await twn.finished
	twn.kill()
	box_selected = true
	on_changing = false
	on_showing = true


func _on_mouse_entered() -> void:
	box_select()

func _on_mouse_exited() -> void:
	box_deselect()
	
func box_select():
	if on_changing or box_selected:return
	on_changing = true
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",character_box_config.img_box_top_marg_show,character_box_config.animation_time)
	twn.parallel().tween_property(self,"size_flags_stretch_ratio",character_box_config.wide_marg_show,character_box_config.animation_time)
	twn.parallel().tween_property(self,"modulate",character_box_config.selected_modulate,character_box_config.animation_time)
	await twn.finished
	twn.kill()
	timer.start()
	box_selected = true
	on_changing = false

func box_deselect():
	if on_changing or !box_selected:return
	timer.stop()
	on_changing = true
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(img_box_top_marg,"size_flags_stretch_ratio",character_box_config.img_box_top_marg_hide,character_box_config.animation_time)
	twn.parallel().tween_property(self,"modulate",character_box_config.unselect_modulate,character_box_config.animation_time)
	twn.parallel().tween_property(self,"size_flags_stretch_ratio",character_box_config.wide_marg_hide,character_box_config.animation_time)
	await twn.finished
	twn.kill()
	box_selected = false
	on_changing = false
	on_showing = false


func _on_timer_timeout() -> void:
	#Debug.dprintwarn(DebugCT.dp("检查flag[%s][%s][%s]" %[box_selected,on_showing,on_changing],self))
	if !box_selected or on_showing or on_changing:
		return
	if !check_has_mouse():
		_on_mouse_exited()

		
func check_has_mouse():
	#Debug.dprintwarn(DebugCT.dp("检查数遍是否悬空[%s][%s]" %[Rect2(position,size),get_local_mouse_position()],self))
	return get_global_rect().has_point(get_global_mouse_position())


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


func _on_gui_input(event: InputEvent) -> void:
	if !character_box_config.is_player:return
	if event.is_action_pressed("uiselect"):
		if !UiState.state_box.showing:
			UiState.state_box.show_box()
		else :
			UiState.state_box.hide_box()


func _on_delay_timer_timeout() -> void:
	test.text=character_box_config.character_box_id
	texture_rect.texture = character_box_config.image
	img_box.size_flags_stretch_ratio=0
	size_flags_stretch_ratio=0
	img_box_top_marg.size_flags_stretch_ratio=20
	modulate=character_box_config.unselect_modulate
	show()
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_SPRING)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(self,"size_flags_stretch_ratio",character_box_config.wide_marg_hide,0.5)
	twn.parallel().tween_property(img_box,"size_flags_stretch_ratio",20,0.3)
	twn.parallel().tween_property(img_box_top_marg,"size_flags_stretch_ratio",character_box_config.img_box_top_marg_hide,0.5)
	await twn.finished
	UiState.set_character_box_showing(character_box_config,true,self)
	twn.kill()	
