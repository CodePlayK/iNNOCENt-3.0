extends MarginContainer
class_name UIStateBox
@onready var state_tabs: TabContainer = %StateTabs
@onready var state_box_center: VBoxContainer = %StateBoxCenter
@onready var close_box_but: Button = %CloseBoxBut
@onready var item_list: VBoxContainer = %ItemList
@onready var item_data_txt: RichTextLabel = $"HBoxContainer/StateBoxCenter/MarginContainer2/HBoxContainer/MarginContainer/StateTabs/收集品/VBoxContainer2/VBoxContainer/MarginContainer2/VBoxContainer/MarginContainer2/ItemDataTxt"
@onready var item_texture: AnimatedSprite2D = $"HBoxContainer/StateBoxCenter/MarginContainer2/HBoxContainer/MarginContainer/StateTabs/收集品/VBoxContainer2/VBoxContainer/MarginContainer2/VBoxContainer/MarginContainer/CenterContainer/ItemTexture"
@onready var mc_left: MarginContainer = %MCLeft
@onready var mc_right: MarginContainer = %MCRight
@onready var mc_bot: MarginContainer = $HBoxContainer/StateBoxCenter/MCBot
@onready var mc_top: MarginContainer = $HBoxContainer/StateBoxCenter/MCTop
@onready var abt_data_txt: RichTextLabel = %ABTDataTxt
@onready var shader_crt: ColorRect = %ShaderCRT
@export var state_box_trans_time:float = 1
var showing:bool = false
var on_hiding:bool = false
var show_tweens:Array[Tween]
var hide_tweens:Array[Tween]
signal clear_items

func _ready() -> void:
	UiState.state_box = self
	mc_left.gui_input.connect(_on_gui_input)
	mc_right.gui_input.connect(_on_gui_input)
	mc_top.gui_input.connect(_on_gui_input)
	mc_bot.gui_input.connect(_on_gui_input)
	UiState.SAVE_FILE_ITEM.instantiate()
	set_crt_shader(false)
##设置CRTsgader是否启用	
func set_crt_shader(f):
	shader_crt.material.set_shader_parameter("enable",f)
##显示	
func show_box():
	showing = true
	set_crt_shader(true)
	DataState.current_screenshot = ImageTexture.create_from_image(get_viewport().get_texture().get_image())##更新截图
	DataState.current_select_save_id = DataState.current_save_id
	var show_tween = self.create_tween()
	for tw in show_tweens:
		tw.kill()
	show_tweens.append(show_tween)
	show_tween.finished.connect(on_show_tween_finished)
	show_tween.set_trans(Tween.TRANS_QUAD)
	show_tween.set_ease(Tween.EASE_OUT)
	show_tween.tween_property(self,"position",Vector2.ZERO,state_box_trans_time)
##隐藏
func hide_box():
	showing = false
	on_hiding = true
	for tw in hide_tweens:
		tw.kill()
	var hide_tween = self.create_tween()
	hide_tweens.append(hide_tween)
	hide_tween.finished.connect(on_hide_tween_finished)
	hide_tween.set_trans(Tween.TRANS_QUAD)
	hide_tween.set_ease(Tween.EASE_IN)
	hide_tween.tween_property(self,"position",Vector2(0,state_box_center.size.y),state_box_trans_time)
	await hide_tween.finished
	on_hiding = false
	
func _on_state_tabs_focus_exited() -> void:
	Debug.dprintinfo(DebugCT.dp("失去焦点",self))

func _on_close_box_but_pressed() -> void:
	hide_box()
	
func on_show_tween_finished():
	Debug.dprintinfo(DebugCT.dp("暂停界面转为显示状态",self))
	
func on_hide_tween_finished():
	Debug.dprintinfo(DebugCT.dp("暂停转为隐藏状态",self))
	set_crt_shader(false)
##添加收集品
func add_item(item1:ItemState.ITEMS):
	new_item(item1)
	if UiState.current_interact_item:
		UiState.current_interact_item.on_collected()
##更新技能明细
func on_ABT_item_selected(ABT_item_config:ABTItemConfig):
	var txt:String
	var ac = AbtState.get_ABT_config(ABT_item_config.ABT)
	txt += "技能名:%s\n" %ABT_item_config.ABT_name
	txt += "冷却:%s\n" %str(ac.get_cooldown()).pad_decimals(2)
	txt += "持续:%s\n" %str(ac.get_during()).pad_decimals(2)
	txt += "额外:%s\n" %AbtState.get_ABT_config(ABT_item_config.ABT).get_attribute_txt()
	txt += "技能说明:%s\n" %ABT_item_config.ABT_name_line
	txt += "技能背景:%s\n" %ABT_item_config.ABT_name_txt
	abt_data_txt.text = txt
##更新物品明细			
func on_item_selected(item_config:ItemConfig):
	var txt:String
	txt += "物品名:%s\n" %item_config.item_name
	txt += "物品简述:%s\n" %item_config.item_txt
	txt += "物品说明:%s\n" %item_config.item_detail_txt
	item_data_txt.text = txt
	var res:SpriteFrames = ItemState.item_texture_res_dic[item_config.item_texture_config.item_texture]
	item_texture.sprite_frames = res
	item_texture.play(item_config.item_texture_config.animation_name)
##新建物品	
func new_item(i:ItemState.ITEMS):
	if ItemState.current_item_dic.has(i):
		ItemState.add_item(i,null)
		ItemState.current_item_dic[i][1].update()
		return
	ItemState.add_item(i,null)
	var item = UiState.STATE_ITEM.instantiate()
	ItemState.current_item_dic[i][1] = item
	item_list.add_child(item)
	item.init(i)
	item_list.move_child(item,0)
	item.selected.connect(on_item_selected)
##从存档载入item
func load_item(i:ItemState.ITEMS,count:int):
	ItemState.current_item_dic[i] = [count,null]
	var item = UiState.STATE_ITEM.instantiate()
	ItemState.current_item_dic[i][1] = item
	item_list.add_child(item)
	item.init(i)
	item.update()
	item_list.move_child(item,0)
	item.selected.connect(on_item_selected)

func _on_gui_input(event: InputEvent) -> void:
	if on_hiding:return
	if event.is_action("uiselect"):
		hide_box()
