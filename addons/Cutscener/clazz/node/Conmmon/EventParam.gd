@tool
extends OptionButton
signal param_selected
func _on_item_selected(index: int) -> void:
	param_selected.emit(index,self)

func _init() -> void:
	CutscenerGlobal.load_global.connect(on_load_global)#全局脚本载入完毕事件
	
func on_load_global():
	var cv = get_item_text(selected)
	clear()
	for ec in EventData.EVENTS_CONFIG.values():
		add_item(str(ec)+"."+EventData.events_dic[ec][0].event_key_txt,ec)	
	select_by_name(self,cv)
	
	##根据下拉选项的内容选定			
func select_by_name(paratype_node,t_name):
	for a in paratype_node.get_item_count():
		if paratype_node.get_item_text(a) == t_name:
			paratype_node.select(a)
			break
