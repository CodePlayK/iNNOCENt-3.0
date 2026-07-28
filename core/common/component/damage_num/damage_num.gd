extends Component
@onready var damage_num: Label = $damageNum
var damage_num_marker
@export var num_size_px:int = 13
@export var time_scale:float = 1
@export var x_scale:float = 1
@export var y_scale:float = 1
@export var num_color:Color = "ff8080"

func _ready() -> void:
	for node in get_children():
		if node is Marker2D:
			damage_num_marker = node
	damage_num.hide()

func emit_num(damage:float):
	var current_marker_pos = damage_num_marker.global_position
	var d_num = damage_num.duplicate(8)
	var lable_setting = damage_num.label_settings.duplicate()
	d_num.label_settings=lable_setting
	d_num.text = str(damage)
	d_num.label_settings.font_size = num_size_px
	d_num.label_settings.font_color = num_color
	LevelState.current_main_layer.add_child(d_num)
	d_num.global_position = damage_num.global_position
	d_num.show()
	var tween = d_num.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	var desv = Vector2(current_marker_pos.x+x_scale*randf_range(-1,1),current_marker_pos.y-y_scale*randf_range(0,1))
	var rand_time:float = randf_range(.5,1.0)*time_scale
	tween.parallel().tween_property(d_num,"global_position",desv,rand_time)
	var trans_color = d_num.self_modulate
	trans_color.a = 0
	tween.set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(d_num,"self_modulate",trans_color,rand_time)
	await tween.finished
	tween.kill()
	d_num.hide()
	d_num.queue_free()
	
