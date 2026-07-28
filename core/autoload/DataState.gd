extends Node
const DB_NAME="user://data/data"
const SAVE_SCREENSHOT_PATH = "user://data/screen shot/"
const TABLE ="save"
const TRASH_TABLE ="trash"
const DATA ="data"
const GROUP_ID ="group_id"
const LEVEL_ID ="level_id"
const SAVE_ID ="save_id"
const parallax_move_data_source_path="res://core/common/parallax/parallax_move_data.tres"
const parallax_save_data_source_path="res://core/common/parallax/parallax_save_data.tres"
var ui_save_config = ResourceLoader.load("res://core/common/ui/state_box/setting/save_menu_ui_save_file_config.tres")
##存档的group类型
enum GROUP{
	WORLD = -1,##世界
	PLAYER = 0,##玩家
	NPC = 1,##npc
	PARALLAX = 2,##视差层
	OBJ = 3,##物体
	ITEM = 4,##交互物体
	SAVE = 5,##存档
	DIALOGUE_HIS = 6,##对白历史
}
var DB:SQLite
##存档数据缓存
var save_cache:Dictionary
##要存档的物体注册字典
var save_obj_state:Dictionary
##存档菜单
var ui_save_data_controller:BaseDataCollector
##存档配置类
var save_file_config:SaveDataConfig
##当前屏幕截图
var current_screenshot:Texture2D
##当前的存档id
var current_save_id:int = 0:
	set(i):
		current_save_id = i
		EventBus._save_id_update()
##当前的最大存档id值
var current_max_save_id:int = 0
##当前在界面中选中的存档id
var current_select_save_id:int = 0
##当前存档文件数据
var current_save_file_dic:Dictionary
##添加到存档文件字典
func add2save_file_dic(key,v):
	current_save_file_dic[key] = v
	update_max_save_id()
##更新最大存档id	
func update_max_save_id():
	current_max_save_id = 0
	for k in current_save_file_dic.keys():
		current_max_save_id = max(current_max_save_id,int(k))	
##更新存档id对应的截图资源		
func update_screenshot(save_id):
	if !DirAccess.dir_exists_absolute(SAVE_SCREENSHOT_PATH):
		DirAccess.make_dir_absolute(SAVE_SCREENSHOT_PATH)
	ResourceSaver.save(DataState.current_screenshot,SAVE_SCREENSHOT_PATH+str(save_id)+".res")
##从资源中读取截图	
func get_screenshot(save_id):
	return ResourceLoader.load(SAVE_SCREENSHOT_PATH+str(save_id)+".res")
##将obj注册到应存档字典中
func obj_save_state_init(K):
	save_obj_state[K] = false
##重置应存档字典
func obj_save_state_reset():
	for k in save_obj_state.keys():
		save_obj_state[k] = false
	save_cache.clear()
##将应存档字典中的所有锁设定为真
func obj_save_state_enable_all():
	for k in save_obj_state.keys():
		save_obj_state[k] = true
		save_cache.clear()
##将应存档字典中的对象锁设置为真
func obj_save_state_ready(K):
	save_obj_state[K] = true
	for k in save_obj_state.keys():
		if !save_obj_state[k]:
			return
	save_all()
##将存档数据配置添加到缓存中,唯一键约束为[save_id][group][level_id][key]:data	
func add2cache(sc1:SaveDataConfig):
	var sc = sc1.duplicate()
	if save_cache.has(sc.save_id):
		if save_cache[sc.save_id].has(sc.group):
			if save_cache[sc.save_id][sc.group].has(sc.level_id):
				save_cache[sc.save_id][sc.group][sc.level_id][sc.key] = sc.data
			else :
				save_cache[sc.save_id][sc.group][sc.level_id]=({sc.key:sc.data})
		else :
			save_cache[sc.save_id][sc.group]={sc.level_id:{sc.key:sc.data}}
	else :
		save_cache[sc.save_id] = {sc.group:{sc.level_id:{sc.key:sc.data}}}
##开始储存到数据库
func save_all():
	DB.open_db()
	var insert_list:Array
	for s in save_cache.keys():
		for g in save_cache[s].keys():
			for l in save_cache[s][g].keys():
				var c = "%s = %s and %s = %s and %s = %s" %[SAVE_ID,str(s),GROUP_ID,str(g),LEVEL_ID,str(l)]
				var ids = DB.select_rows(TABLE,c,["id"])
				if ids and ids[0]:
					DB.update_rows(TABLE,"id = %s" %ids[0]["id"],{DATA:JSON.stringify(save_cache[s][g][l])})
				else :
					var dic:Dictionary = {
						SAVE_ID = str(s),
						LEVEL_ID = str(l),
						GROUP_ID = str(g),
						DATA = JSON.stringify(save_cache[s][g][l]),
					}
					insert_list.append(dic)
	DB.insert_rows(TABLE,insert_list)
	DB.close_db()
	obj_save_state_reset()
##删除指定存档	
func delete_save(save_id):
	current_save_file_dic[save_id] = null##从存档文件字典中清除存档id
	current_save_file_dic.erase(save_id)
	DB.open_db()
	var list = DB.select_rows(TABLE,"save_id = %s" %str(save_id),["*"])
	var DB1 = SQLite.new()
	DB1.path=DB_NAME
	DB1.verbosity_level =SQLite.QUIET
	DB1.open_db()
	for dic in list:
		DB1.insert_row(TRASH_TABLE,dic)##将删除数据插入到回收表
	DB1.close_db()
	DB.delete_rows(TABLE,"save_id = %s" %str(save_id))##从主表删除
	DB.close_db()
	obj_save_state_enable_all()##暂时失效所有锁
	ui_save_data_controller._pre_save_game()##通知存档设置界面的DataController保存游戏
	EventBus._delete_save(save_id)##存档删除事件
	if current_save_id == save_id:
		update_max_save_id()
		current_save_id = current_max_save_id
	
func _ready() -> void:
	DB = SQLite.new()
	DB.path=DB_NAME
	DB.verbosity_level =SQLite.QUIET
	DB.open_db()
