extends CanvasLayer
@onready var v_box_container: VBoxContainer = $VBoxContainer
@onready var debug: HBoxContainer = $VBoxContainer/debug
@onready var main: MarginContainer = $VBoxContainer/debug/main
@onready var margin_l: MarginContainer = $VBoxContainer/debug/marginL
@onready var margin_r: MarginContainer = $VBoxContainer/debug/marginR
##[关卡:[debug0,debug1]]
var debug_dic:Dictionary
func _init() -> void:
	EventBus.add_debug.connect(add_debug)
	EventBus.level_changed.connect(on_level_changed)

func add_debug(d:Node,size:Vector2,max_y:float):
	if !debug_dic.has(LevelState.current_level):
		debug_dic[LevelState.current_level] = []
	margin_l.size_flags_stretch_ratio = size.x
	margin_r.size_flags_stretch_ratio = size.y
	var new_debug = debug.duplicate()
	new_debug.custom_maximum_size.y= 31
	new_debug.custom_minimum_size.y= 30
	v_box_container.add_child(new_debug)
	d.reparent(new_debug.get_child(1))
	debug_dic[LevelState.current_level].append(new_debug)
	new_debug.show()

func on_level_changed(fl, tl):
	for k in debug_dic:
		for d in debug_dic[k]:
			if tl!=k:
				d.hide()
			else :
				d.show()
	pass
