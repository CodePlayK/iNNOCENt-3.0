extends Resource
class_name ItemConfig
##唯一ID
@export var item_id:int
##物品类型
@export var item_type:ItemState.ITEM_TYPE
##物品贴图资源
@export var item_texture_config:ItemTextureConfig
##物品显示名
@export var item_name:String
##物品拾取时显示的文字
@export_multiline var item_txt:String
##物品的完整说明文字
@export_multiline var item_detail_txt:String
