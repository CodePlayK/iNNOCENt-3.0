## 基础着色层（仅检测与注册）
##
## 挂在需要染色的节点上（例如 ParallaxLayer_x），或直接作为可着色节点。
## 自动解析名称中的数字 id（x），并向场景中唯一名的 BaseColoredController 注册。
## 不负责染色，染色由 Controller 统一处理。
class_name BaseColoredLayer extends Node2D
