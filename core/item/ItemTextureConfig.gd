@tool
extends Resource
class_name ItemTextureConfig
@export var import:bool:
	set(f):
		import = f
		on_update()
@export var item_texture:ItemState.ITEM_TEXTURE_RES:
	set(tx):
		item_texture = tx
		on_update_tx()
@export var animation_name:String:
	set(s):
		animation_name = s
		on_animation_name_update()
@export var static_texture_frame:int:
	set(i):
		static_texture_frame = i
		on_animation_name_update()
@export var static_texture:Texture2D
@export_multiline var animation_name_list:String

func on_update_tx():
	if !ItemState:return
	animation_name_list = ""
	for name in ItemState.item_texture_res_dic[item_texture].get_animation_names():
		animation_name_list+= "%s\n" %name
func on_update():
	on_update_tx()
func on_animation_name_update():
	if !ItemState:return
	var res:SpriteFrames = ItemState.item_texture_res_dic[item_texture]
	if res.has_animation(animation_name):
		if res.get_frame_count(animation_name)<=static_texture_frame or static_texture_frame<0:return
		static_texture = res.get_frame_texture(animation_name,static_texture_frame)
		
	
