extends BaseDataCollector
@onready var txt_history_box: DialogueHistoryBox = $".."

func on_ready():
	pass
	
func custom_key():
	pass
	
#配置要写入存档的数据
func custom_data():
	save_data_config.data = DialogueState.dialogue_his_dic
	
#载入存档数据
func load_custom_data(data:Dictionary):
	clear_dialogue_his()
	var dic_fin:Dictionary
	var max_i:int = 0
	var last_line:String
	var dialogue_his_dic_fin:Dictionary
	for i in data.keys().size():
		max_i = max(max_i,int(i))
		var dic = data[data.keys()[data.keys().size()-i-1]]
		var k = str(dic["left_side"])+str(dic["talker"])+JSON.stringify(dic["lines"])
		if !dic_fin.has(k):
			dic_fin[k] = data.keys()[data.keys().size()-i-1]
	var index_list:Array
	for fk in dic_fin.keys():
		index_list.append(str(dic_fin[fk]))
	index_list.sort()
	for i in index_list:
		max_i = max(max_i,int(i))
		var dic = data[i]
		dialogue_his_dic_fin[i] = dic
		txt_history_box.add_new_talker_dialogue(int(i),dic)
		for l in dic["lines"].size():
			last_line = dic["lines"][l]
			if l>0:
				txt_history_box.add_current_talker_dialogue(int(i),dic["left_side"],dic["lines"][l])
	DialogueState.current_index = max_i
	DialogueState.last_line = last_line
	DialogueState.dialogue_his_dic = dialogue_his_dic_fin
	
##删除存档事件
func on_delete_save():
	return
	clear_dialogue_his()

func clear_dialogue_his():
	DialogueState.reset_dialogue_his()
	for n in txt_history_box.box.get_children():
		n.hide()
		n.queue_free()	
