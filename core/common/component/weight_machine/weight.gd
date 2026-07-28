@icon("res://core/common/resource/icon/weight.svg")
extends Node
##权重
class_name Weight
##权重缩放比例
@export var custom_weight_scale:float = 1
##权重值
var weight:float
##真权重值
@export var confirmed_weight:float
##假权重值
@export var impossible_weight:float
@onready var weight_machine: WeightMachine = $"../.."
##执行
func process(obj) -> void:
	pass
##执行后
func after_process(obj) -> void:
	pass
##退出
func exit(obj):
	pass
