extends Node2D
var showing:bool = false
var show_tweens:Array[Tween]
var hide_tweens:Array[Tween]
@export var target:Node2D
@export var trans_time:float = .5
@export var hide_node_pos:Node2D
var hide_pos:Vector2

func _ready() -> void:
	if !target:
		target = owner

func show_box():
	showing = true
	var show_tween = self.create_tween()
	for tw in show_tweens:
		tw.kill()
	show_tweens.append(show_tween)
	show_tween.finished.connect(on_show_tween_finished)
	show_tween.set_trans(Tween.TRANS_CUBIC)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.tween_property(target,"position",Vector2.ZERO,trans_time)
	
func hide_box():
	if hide_node_pos:hide_pos = hide_node_pos.position
	showing = false
	for tw in hide_tweens:
		tw.kill()
	var hide_tween = self.create_tween()
	hide_tweens.append(hide_tween)
	hide_tween.finished.connect(on_hide_tween_finished)
	hide_tween.set_trans(Tween.TRANS_CUBIC)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.tween_property(target,"position",hide_pos,trans_time)


func on_show_tween_finished():
	Debug.dprintinfo(DebugCT.dp("转为显示状态",self))
	
func on_hide_tween_finished():
	Debug.dprintinfo(DebugCT.dp("转为隐藏状态",self))
