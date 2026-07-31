extends MarginContainer
class_name CharacterBoxs
@onready var margin_side: MarginContainer = $VBoxContainer/HBoxContainer/MarginSide
@onready var margin_mid: MarginContainer = $VBoxContainer/HBoxContainer/MarginMid

@onready var wide_marg:CharacterBox = $VBoxContainer/HBoxContainer/WideMarg
@onready var boxs: HBoxContainer = $VBoxContainer/HBoxContainer
var current_index:int=1
var left_index_max:int=1
var margin_mid_index:int=0
var left_index_max_node:int=0
var left_box_max:CharacterBox
var character_box_config:CharacterBoxConfig
var left_ct:int=0
var right_ct:int=0


func _init() -> void:
	EventBus.create_character_box.connect(on_create_character_box)
	
#创建角色box事件
func on_create_character_box(character_box_config:CharacterBoxConfig):
	if !character_box_config:
		return
	character_box_config = character_box_config
	if !wide_marg or !margin_mid:
		await ready
	get_margin_mid_index()
	if character_box_config.is_player:
		var new_box = wide_marg.duplicate()
		var margin_side = margin_side.duplicate()
		new_box.name = "box|-999" 
		boxs.add_child(new_box)
		boxs.move_child(new_box,1)
		new_box.character_box_config=character_box_config
		new_box.show()
		new_box.anime_born()
	else:
		if character_box_config.on_screen_left:	
			get_left_index_max()
			var new_box = wide_marg.duplicate()
			var margin_side = margin_side.duplicate()
			new_box.name = "box|%s" %current_index
			boxs.add_child(margin_side)
			boxs.move_child(margin_side,left_index_max_node+1)
			boxs.add_child(new_box)
			boxs.move_child(new_box,left_index_max_node+2)
			new_box.character_box_config=character_box_config
			current_index+=1
			new_box.show()
			new_box.anime_born()
		else :
			var new_box = wide_marg.duplicate()
			var margin_side = margin_side.duplicate()
			new_box.name = "rbox"
			boxs.add_child(margin_side)
			boxs.move_child(margin_side,margin_mid_index+1)
			boxs.add_child(new_box)
			boxs.move_child(new_box,margin_mid_index+2)
			new_box.character_box_config=character_box_config
			new_box.show()
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
