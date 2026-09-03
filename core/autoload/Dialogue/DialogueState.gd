extends Node
var dialogue_his_line = preload("res://core/common/ui/txt_history_box/dialogue_line.tscn")
const DIALOGUE_FILE_PATH = "res://core/dialogue/dialogues/"

##{index:"talker":"player","left":true,"lines":["line0","line2"]}
var dialogue_his_dic:Dictionary
##{index:box}
var dialogue_his_box_dic:Dictionary
##对白文件dic<场景名:[class DialogueResource]>
var dialogue_file_res:Dictionary
##每个场景中包含的title汇总<场景名:[title1,title2...]>
var dialogue_title_dic:Dictionary
var current_index:int = -1
var last_line:String

func _init() -> void:
	add_dialogue_file()
	
##获取当前场景的上一个有该title的场景名
func get_latest_cutscene_contain_title(title:String)->String:
	var c = CutsceneState.current_cutscene
	var t
	while !dialogue_title_dic[c].has(title):
		t = get_last_cutscene(c)
		if t == c:
			break
		c = t 
	return c

##获取上一个场景index
func get_last_cutscene(cn:String)->String:
	var a = cn.split("_")
	if a.size()==3:
		if CutsceneState.cutscene_index_dic.keys().has(int(a[2])-1):
			return CutsceneState.cutscene_index_dic[int(a[2])-1]
	return cn

func reset_dialogue_his():
	dialogue_his_dic = {}
	current_index = 0
	last_line = ""
##添加到对白历史
func add_dialogue_history(talker:String,line:String):
	var left_side = true
	if DialogueState.player_name.has(talker) or UiState.mind_txt_box.talker_name.has(talker):
		left_side = false
	if !dialogue_his_dic.has(current_index) or dialogue_his_dic[current_index]["talker"] != talker:
		current_index += 1
		dialogue_his_dic[current_index] = {
			"talker" = talker,
			"left_side" = left_side,
			"lines"= [line],
		}
		last_line = line
		if UiState.dialogue_history_box:
			UiState.dialogue_history_box.add_new_talker_dialogue(current_index,dialogue_his_dic[current_index])
	else :
		if line==last_line:return
		dialogue_his_dic[current_index]["lines"].append(line)
		last_line = line
		if  UiState.dialogue_history_box:
			UiState.dialogue_history_box.add_current_talker_dialogue(current_index,left_side,line)		
##玩家可能的talker名
var player_name:Array[String] = ["我","M","P"]
##talker的颜色
var talker_color:Dictionary={
	"我":Color.AQUA,
	"NPC":Color.WHITE,
	"bloodking":Color.SKY_BLUE,
	"bloodking2":Color.CORAL,
}
#新增场景对应的对白路径信息
func add_dialogue_file():
	# 打开目录
	var dir = DirAccess.open(DIALOGUE_FILE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name!="":
		# 跳过 . 和 .. 两个系统目录项
			if file_name == "." or file_name == "..":
				continue
		# 判断是否是文件（排除文件夹）
			if dir.file_exists(file_name) and file_name.ends_with(".dialogue"):
				# 完整路径 = 目录 + 文件名
				var full_path = DIALOGUE_FILE_PATH.path_join(file_name)
				dialogue_file_res[file_name.get_basename()]=load(full_path)
				if file_name.get_basename().split("_").size()==3:
					dialogue_title_dic[file_name.get_basename()] = dialogue_file_res[file_name.get_basename()].titles.keys()
					CutsceneState.cutscene_index_dic[int(file_name.get_basename().split("_")[2])] = file_name.get_basename()
		# dir.dir_exists(filename) → 这一项是文件夹
			file_name = dir.get_next()
	else: 
		print("目录不存在或无法访问：", DIALOGUE_FILE_PATH)
	return 
