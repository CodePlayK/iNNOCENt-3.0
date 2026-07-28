extends Node
##技能
enum ABTS {
	LIGHT = 0,
	DENSE = 1,
	DASH = 2,
}
##技能配置在字典ARRAY中的index
const ABT_CONFIG_INDEX = 0
##技能的UI配置在字典ARRAY中的index
const ABT_UI_CONFIG_INDEX = 1
var ABT_dic:Dictionary = {
	ABTS.LIGHT:["res://core/player/attributes/ABT_light_config.tres","res://core/common/ui/state_box/ABTState/ABT_resource/ABTLightConfig.tres"],
	ABTS.DENSE:["res://core/player/attributes/ABT_dense_config.tres","res://core/player/attributes/PlayerABTDenseConfig.gd"],
	ABTS.DASH:["res://core/player/attributes/ABT_dash_config.tres","res://core/common/ui/state_box/ABTState/ABT_resource/ABTDashConfig.tres"],
}
##获取技能的UI配置
func get_ABT_ui_config(a:ABTS):
	return ResourceLoader.load(ABT_dic[a][ABT_UI_CONFIG_INDEX])
##获取技能的配置
func get_ABT_config(a:ABTS):
	return ResourceLoader.load(ABT_dic[a][ABT_CONFIG_INDEX])
