extends PlayerSaveDataCollector
@onready var test_label: Label = %TestLabel

#配置要写入存档的数据
func custom_data():
	if test_label.text.is_empty():test_label.text = "0"
	dic_save_data["test"]=test_label.text
	pass
	
func custom_column_data(c_data:Dictionary):
	pass
		
#载入存档数据
func load_custom_data():
	test_label.text=dic_save_data["test"]
	pass
