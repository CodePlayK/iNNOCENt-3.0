@tool
extends Node
const STATE_ITEM = preload("res://core/common/ui/state_box/item/item.tscn")
const SAVE_FILE_ITEM = preload("res://core/common/ui/state_box/setting/save_file_item/save_file_item.tscn")
##游戏中界面
var state_box:UIStateBox
##对白历史界面
var dialogue_history_box:DialogueHistoryBox
##玩家内心对白界面
var mind_txt_box:MindTxtBox
##拾取物体时的界面
var item_txt_box:ItemTxtBox
##左下角玩家头像界面
var player_character_box:CharacterBox
##储存角色box状态
var character_box_dic:Dictionary[String,CharacterBoxConfig]
func set_character_box_dic(key:String,cbc:CharacterBoxConfig,source:Node):
	character_box_dic[key]= cbc
	Debug.dprintwarn(DebugCT.dp("正在设置[character_box_dic]",source))
func set_character_box_showing(cbc:CharacterBoxConfig,flag:bool,source:Node):
	character_box_dic[cbc.character_box_id].showing= flag
	Debug.dprintwarn(DebugCT.dp("正在设置[%s]:showing状态为[%s]" %[cbc.character_box_id,flag],source))
##当前正在交互的物体
var current_interact_item:CollectableItem
#FIXME
##拾取物体时物体飞向的目标marker
var player_collect_marker: Marker
var canvas: CanvasLayer
##拾取物品动画
func collect_item_trans(item:Node2D):
	var tw = item.create_tween()
	tw.set_trans(Tween.TRANS_CUBIC)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(item,"global_position",LevelState.current_main_layer.to_local(player_collect_marker.get_global_transform_with_canvas().origin),1)
	await tw.finished
	tw.kill()
##设置
enum SETTING_ITEMS {
	保存 = 0,
	载入 = 1,
	新存档= 2,
	删除= 3,
}
##设置界面item字典
var setting_item_dic = {
	SETTING_ITEMS.保存:"res://core/common/ui/state_box/setting/save_game.tres",
	SETTING_ITEMS.载入:"res://core/common/ui/state_box/setting/load_game.tres",
	SETTING_ITEMS.新存档:"res://core/common/ui/state_box/setting/new_save_file.tres",
	SETTING_ITEMS.删除:"res://core/common/ui/state_box/setting/delete_game.tres",
}
##获取设置界面item资源
func get_setting_item(st:SETTING_ITEMS):
	return ResourceLoader.load(setting_item_dic[st])
