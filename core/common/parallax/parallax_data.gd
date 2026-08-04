extends BaseDataCollector
@onready var parallax: Parallax = $".."

	
func custom_key():
	#save_data_config = save_data_config.duplicate()
	pass
#配置要写入存档的数据
func custom_data():
	var dic:Dictionary
	for layer in parallax.parallax_layers:
		dic[layer.name]=layer.position.x
	dic["pmd"] = parallax.parallax_move_data.dic_layers_move_data
	save_data_config.data = dic
	
#载入存档数据
func load_custom_data(data:Dictionary):
	parallax.parallax_on = false
	for layer in parallax.parallax_layers:
		layer.position.x = data[layer.name]
	parallax.parallax_move_data.dic_layers_move_data = data["pmd"]
	parallax.on_start()
