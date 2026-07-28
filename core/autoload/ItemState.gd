@tool
extends Node
##当前的收集品字典
var current_item_dic:Dictionary
##添加收集品
func add_item(i:ITEMS,n:Node2D):
	if current_item_dic.has(i):
		current_item_dic[i][0]+=1
	else:
		current_item_dic[i] = [1,n]
##物品类型		
enum ITEMS {
	LENS = 0,
	帐篷 = 1,
	斧子 = 2,
	手电 = 3,
	绷带 = 4,
	钥匙 = 5,
	子弹 = 6,
	蓝图 = 7,
}
##物品字典
var item_box_dic:Dictionary = {
	ITEMS.帐篷:"res://core/item/resource/tent.tres",
	ITEMS.斧子:"res://core/item/resource/pickaxe.tres",
	ITEMS.手电:"res://core/item/resource/flashlight.tres",
	ITEMS.绷带:"res://core/item/resource/bandage.tres",
	ITEMS.钥匙:"res://core/item/resource/key.tres",
	ITEMS.子弹:"res://core/item/resource/ammo.tres",
	ITEMS.蓝图:"res://core/item/resource/blueprint2.tres",
	ITEMS.LENS:"res://core/item/resource/lens.tres",
}
##获取物品资源
func get_item_config(i:ITEMS):
	return ResourceLoader.load(item_box_dic[i])
##物品类型
enum ITEM_TYPE {
	LENS = 0,##镜片
	WOOD  = 1,##木
	COLLECTION = 2,##收集品
	PROGRESS = 3,##玩家成长
}
##物品图像资源
enum ITEM_TEXTURE_RES{
	TEST_ITEM = 0,
}
##物品图像资源字典
var item_texture_res_dic = {
	ITEM_TEXTURE_RES.TEST_ITEM:ResourceLoader.load("res://core/common/resource/texture/items/test_items/Pop Cans.tres")
}

var ui_current_select_item:ItemState.ITEMS:
	set(i):
		ui_current_select_item = i
		ui_current_select_item_update.emit()
signal ui_current_select_item_update
