extends Node # 或者 Node2D/Sprite2D 均可
class_name PlayerPos2Mouse
@export var scale:float = 1.0
@export var enable:bool = false

func _process(_delta: float) -> void:
	if !enable or !PlayerState.player_player:
		return
	# 纯脚本核心：直接向底层 Input 获取当前鼠标在视口（Viewport）中的绝对 X 坐标
	var mouse_screen_x: float = Global.player_camera.get_global_mouse_position().x
	PlayerState.player_player.global_position.x = mouse_screen_x*scale
