@icon("res://core/common/resource/icon/ProgressBar.png")
extends Control
class_name UIbar
@export_group("基础配置")
@export var only_show_in_combat:bool = true	
@export var keep_show_in_combat:bool = true	
@export_group("初始化设置")
@export var bar_max_value:float:
	set(f):
		bar_max_value = f
		if ui_bar:ui_bar.max_value = f
		if back_bar:back_bar.max_value = f
@export var bar_min_value:float = 0:
	set(f):
		bar_min_value = f
		if ui_bar:ui_bar.min_value = f
		if back_bar:back_bar.min_value = f
@export var back_bar_enable:bool = true:
	set(f):
		back_bar_enable = f
		preset_back_bar(back_bar_enable)
@export var current_value:float:
	set(v):
		last_value = current_value
		current_value = v
@export_group("外观")
@export var bar_max_hide_time:float = 3
@export var back_bar_delay_time:float
@export var bar_animation_time:float = .2
@export var back_bar_animation_time:float = .2
@export var bar_color:Color = "00ff00ef":
	set(c):
		bar_color = c
		set_color()
@export var back_bar_color:Color = "ff00007b":
	set(c):
		back_bar_color = c
		set_color()
var last_value:float
@onready var back_bar_timer: Timer = $BackBarTimer
@onready var back_bar: ProgressBar = $UIBarBack
@onready var ui_bar: ProgressBar = $UIBar
@onready var max_hide_timer: Timer = $MaxHideTimer

func _ready() -> void:
	hide()
	preset_back_bar(back_bar_enable)
	set_color()
	EventBus.on_new_game.connect(on_new_game)
	

func on_new_game():
	current_value = bar_max_value
	hide()
	
##master初始化事件			
func on_master_ready(m:Master) -> void:
	bar_max_value = m.obj.data.health
	current_value = m.obj.data.health
	
func bar_decrease(v):
	current_value = v
	if !ui_bar:return
	#Debug.dprintwarn(DebugCT.dp("[max:%s][%s]->[%s]" %[bar_max_value,last_value,current_value],self))
	var bar_tween = ui_bar.create_tween() 
	bar_tween.set_trans(Tween.TRANS_CUBIC)
	bar_tween.set_ease(Tween.EASE_OUT)
	bar_tween.tween_property(ui_bar,"value",current_value,bar_animation_time)
	await bar_tween.finished
	bar_tween.kill()
	if back_bar_timer.is_stopped() and back_bar_enable:
		await get_tree().create_timer(back_bar_animation_time)
		back_bar.value = last_value
		back_bar_timer.start(back_bar_delay_time)

func _on_back_bar_timer_timeout() -> void:
	var back_bar_tween = back_bar.create_tween() 
	back_bar_tween.set_trans(Tween.TRANS_CUBIC)
	back_bar_tween.set_ease(Tween.EASE_OUT)
	back_bar_tween.tween_property(back_bar,"value",current_value,back_bar_animation_time)
	await back_bar_tween.finished
	back_bar_tween.kill()

func bar_grow(v):
	current_value = v
	if !ui_bar:return
	#Debug.dprintwarn(DebugCT.dp("[max:%s][%s]->[%s]" %[bar_max_value,last_value,current_value],self))
	var bar_tween = ui_bar.create_tween() 
	bar_tween.set_trans(Tween.TRANS_CUBIC)
	bar_tween.set_ease(Tween.EASE_OUT)
	bar_tween.tween_property(ui_bar,"value",current_value,bar_animation_time)
	await bar_tween.finished
	bar_tween.kill()
	
func preset_back_bar(f):
	if !back_bar:return
	if f:
		back_bar.value = bar_max_value
	else :
		back_bar.value = bar_min_value
		
func set_color():
	#back_bar.modulate = back_bar_color
	if ui_bar:ui_bar.modulate = bar_color
	if back_bar:back_bar.modulate = back_bar_color

func preset():
	ui_bar.max_value = bar_max_value
	ui_bar.min_value = bar_min_value
	ui_bar.value = current_value
	back_bar.max_value = bar_max_value
	back_bar.min_value = bar_min_value
	back_bar.value = current_value


func _on_ui_bar_value_changed(value: float) -> void:
	if keep_show_in_combat and PlayerState.player_on_fighting:
		max_hide_timer.stop()	
		show()
		return
	if current_value >= bar_max_value and visible and max_hide_timer.is_stopped():
		max_hide_timer.start(bar_max_hide_time)
	elif current_value < bar_max_value :
		if only_show_in_combat :
			if PlayerState.player_on_fighting:
				max_hide_timer.stop()
				show()
		else:
			max_hide_timer.stop()
			show()
	
func _on_max_hide_timer_timeout() -> void:
	hide()


func _on_check_timer_timeout() -> void:
	_on_ui_bar_value_changed(current_value)
