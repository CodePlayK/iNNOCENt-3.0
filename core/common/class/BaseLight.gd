@icon("res://addons/at-icons/mesh/balloon.svg")

extends PointLight2D
class_name BaseLight
@export var level: Levels
@export var enable_follow_node:bool = false
# 导出目标节点的路径，可以在检查器（Inspector）中直接拖拽目标节点赋值
@export var follow_player: bool = false
@export var target_node: Node2D
@export var rotation_speed: float = 5.0 # 转向速度


func _ready() -> void:
	level = owner
	Global.add_2_level_lights_dic(level.level_id,self)
	if follow_player:target_node = PlayerState.player_player



func _process(delta: float) -> void:
	if is_instance_valid(target_node) and target_node.is_inside_tree():
		# 1. 计算朝向目标的绝对角度
		var target_angle = global_position.angle_to_point(target_node.global_position)
		
		# 2. 核心修正：目标角度减去 90 度弧度，让朝下的贴图正确对准目标
		target_angle -= PI / 2
		
		# 3. 平滑插值旋转
		global_rotation = lerp_angle(global_rotation, target_angle, rotation_speed * delta)
