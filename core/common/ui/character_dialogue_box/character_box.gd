extends MarginContainer
class_name CharacterBoxs
@export var time_rand_range:Vector2 = Vector2(0.5,1.5)
@onready var margin_side: MarginContainer = $VBoxContainer/HBoxContainer/MarginSide
@onready var margin_mid: MarginContainer = $VBoxContainer/HBoxContainer/MarginMid
@onready var wide_marg:CharacterBox = $VBoxContainer/HBoxContainer/WideMarg
@onready var boxs: HBoxContainer = $VBoxContainer/HBoxContainer
var current_index:int=1
var left_index_max:int=1
var margin_mid_index:int=0
var left_index_max_node:int=0
var left_box_max:CharacterBox
var left_ct:int=0
var right_ct:int=0
func _init() -> void:
	EventBus.create_character_box.connect(on_create_character_box)
	EventBus.create_all_character_box.connect(on_level_changed)
	
func on_level_changed():
	Debug.dprintwarn(DebugCT.dp("收到切换关卡指令",self))
	current_index=1
	left_index_max=1
	margin_mid_index=0
	left_index_max_node=0
	for cbc_id in UiState.character_box_dic:
		if UiState.character_box_dic[cbc_id].showing:
			on_create_character_box(UiState.character_box_dic[cbc_id])
		else :
			pass
#创建角色box事件
func on_create_character_box(cbc:CharacterBoxConfig):
	#Debug.dprintinfo(DebugCT.dp("[%s]创建角色box:[%s][%s][%s]" %[LevelState.current_level,cbc.character_box_id,cbc.level_id,cbc.showing],self))
	if !cbc:
		return
	if cbc.level_id!=LevelState.current_level and !cbc.is_player:
		return
	else :
		pass
	if !wide_marg:
		await wide_marg.ready
	elif !margin_mid:
		await ready
	#Debug.dprintwarn(DebugCT.dp("[%s]创建角色box:[%s][%s][%s]" %[LevelState.current_level,cbc.character_box_id,cbc.level_id,cbc.showing],self))
	get_margin_mid_index()
	if cbc.is_player:
		var new_box:CharacterBox = wide_marg.duplicate()
		new_box.is_prototype=false
		var margin_side:MarginContainer = margin_side.duplicate()
		new_box.tree_exited.connect(margin_side.on_box_removed)
		new_box.name = "box|-999" 
		boxs.add_child(new_box)
		boxs.move_child(new_box,1)
		new_box.character_box_config=cbc
		new_box.anime_born()
	else:
		if cbc.on_screen_left:	
			var new_box = wide_marg.duplicate()
			new_box.is_prototype=false
			var margin_side:MarginContainer = margin_side.duplicate()
			new_box.tree_exited.connect(margin_side.on_box_removed)
			new_box.name = "box|%s" %current_index
			get_left_index_max()
			boxs.add_child(margin_side)
			boxs.move_child(margin_side,left_index_max_node+1)
			boxs.add_child(new_box)
			boxs.move_child(new_box,left_index_max_node+2)
			new_box.character_box_config=cbc
			current_index+=1
			new_box.anime_born()
		else :
			var new_box = wide_marg.duplicate()
			new_box.is_prototype=false
			var margin_side = margin_side.duplicate()
			new_box.tree_exited.connect(margin_side.on_box_removed)
			new_box.name = "rbox"
			boxs.add_child(margin_side)
			boxs.move_child(margin_side,margin_mid_index+1)
			boxs.add_child(new_box)
			boxs.move_child(new_box,margin_mid_index+2)
			new_box.character_box_config=cbc
			new_box.anime_born()		
	get_left_index_max()
	
func get_left_index_max():
	var has_player_box:bool=false
	for c in boxs.get_children():
		if c.name.begins_with("box"):
			if left_index_max < int(c.name.split("|",false,2)[1]):
				left_index_max = int(c.name.split("|",false,2)[1])
				left_box_max = c
			elif c.name.begins_with("box|-999"):
				has_player_box = true
	if !left_box_max :
		if has_player_box:
			left_index_max_node = 1
		return
	left_index_max_node = left_box_max.get_index()
	
func get_margin_mid_index():
	margin_mid_index=margin_mid.get_index()
