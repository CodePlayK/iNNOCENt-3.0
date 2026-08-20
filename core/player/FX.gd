extends Node2D
var area
## 剑风特效沿朝向飞出的距离
@export_range(0,500) var length = 300.0
## 剑风飞出到目标位置所用时间（秒）
@export_range(0,5.0) var time = 1.0
## 开始淡出的时间点，相对 [member time] 的比例（0~1）
@export var fade_start_time:float = .3
## 淡出至透明所用时间（秒）
@export var fade_time:float = .3
@onready var master: Master = %Master
var obj
func _ready() -> void:
	area = get_child(0)
	
func playAFX(anime:Anime):
	var side:int=1
	if PlayerState.face_left:
		side=-1
	obj = area.duplicate()
	obj.scale.x = side*abs(obj.scale.x)
	obj.obj = area.obj
	add_child(obj)
	obj.on_master_ready(master)
	obj.set_enable(true)
	obj.show()
	var tween:Tween = obj.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(obj,"global_position",Vector2(obj.global_position.x+length*side,obj.global_position.y),time)
	tween.parallel().tween_callback(hide)
	await tween.finished
	tween.kill()
	obj.set_enable(false)
	obj.queue_free()
	
func hide():
	var tween = obj.create_tween()
	tween.tween_interval(time*fade_start_time)
	tween.tween_property(obj,"modulate",Color("ffffff00"),fade_time)
	await tween.finished
	tween.kill
