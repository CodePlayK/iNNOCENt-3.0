## 基础着色层（仅检测与注册）
##
## 挂在需要染色的节点上（例如 ParallaxLayer_x），或直接作为可着色节点。
## 自动解析名称中的数字 id（x），并向场景中唯一名的 BaseColoredController 注册。
## 不负责染色，染色由 Controller 统一处理。
class_name BaseColoredLayer extends Node2D

## 解析得到的层 id（ParallaxLayer_3 → 3）
var layer_id: int = -1

## 通过唯一名直接获取控制器（场景中把 BaseColoredController 勾选 Unique Name）
@onready var controller: BaseColoredController = %BaseColoredController

func _ready() -> void:
	_parse_layer_id()
	controller.register_layer(self)

## 从自身或父节点名解析数字 id
## 支持：ParallaxLayer_0、ParallaxLayer_3 等带下划线数字的命名
func _parse_layer_id() -> void:
	var node_name: String = str(name)
	var parent := get_parent()
	if parent:
		node_name = str(parent.name)

	var regex := RegEx.new()
	regex.compile("_(\\d+)$")
	var result := regex.search(node_name)
	if result:
		layer_id = result.get_string(1).to_int()
	else:
		if node_name.is_valid_int():
			layer_id = node_name.to_int()
		else:
			push_warning("[%s] 无法从名称 [%s] 解析数字 id" % [name, node_name])
			layer_id = 0
