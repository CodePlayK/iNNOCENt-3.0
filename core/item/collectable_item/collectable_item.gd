@tool
@icon("res://core/common/resource/icon/Area3D.svg")
extends Node2D
class_name CollectableItem
@onready var base: AnimatedSprite2D = $item/base
@export var be_collected:bool = false
@export var update_now:bool:
	set(f):
		update_now = f
		on_update()
@export var item:ItemState.ITEMS = ItemState.ITEMS.LENS:
	set(i):
		item = i
		on_update()
@export var item_config:ItemConfig

func _ready() -> void:
	if be_collected:
		queue_free()
	on_update()
	
func on_update():
	if !base:return
	item_config = ItemState.get_item_config(item)
	base.sprite_frames = ItemState.item_texture_res_dic[item_config.item_texture_config.item_texture]
	base.animation = item_config.item_texture_config.animation_name
	base.play()

func on_collected():
	UiState.current_interact_item = null
	await UiState.collect_item_trans(self)
	be_collected = true
	hide()
	queue_free()
