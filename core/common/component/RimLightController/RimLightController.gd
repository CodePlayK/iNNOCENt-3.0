@tool
class_name RimLightController
extends Node

## 根据目标节点位置，实时驱动 Sprite 的轮廓背光强度与方向
## 会自动处理 flip_h / flip_v 镜像

@export_group("目标与主体")
## 作为「光源」的目标节点（用它的全局位置计算方向和距离）
@export var target: Node2D

## 要施加背光的 Sprite2D。留空则自动尝试使用父节点
@export var sprite: Sprite2D

@export_group("距离衰减")
## 开始衰减的距离（像素）
@export var min_distance: float = 50.0

## 完全衰减到 0 的距离（像素）
@export var max_distance: float = 400.0

## 距离越近强度越高时的曲线（1 = 线性，>1 更靠近时更亮）
@export_range(0.2, 3.0, 0.05) var falloff_curve: float = 1.2

## 最大强度倍率（距离为 0 时的 strength）
@export_range(0.0, 3.0, 0.05) var max_strength: float = 1.6

@export_group("Shader 参数同步")
## 是否每帧更新（关闭后可手动调用 update_rim()）
@export var auto_update: bool = true

var _material: ShaderMaterial


func _ready() -> void:
	if sprite == null:
		var p = get_parent()
		if p is Sprite2D:
			sprite = p
	
	_ensure_material()
	
	update_rim()


func _process(_delta: float) -> void:
	if auto_update and Engine.is_editor_hint() == false:
		update_rim()
	elif auto_update and Engine.is_editor_hint():
		# 编辑器里也实时预览
		update_rim()


func _ensure_material() -> void:
	if sprite == null:
		return
	
	if sprite.material is ShaderMaterial:
		_material = sprite.material
	else:
		# 如果还没有材质，提示用户手动赋值（避免覆盖已有材质）
		push_warning("RimLightController: Sprite 上没有 ShaderMaterial，请先把背光 Shader 赋给 Sprite。")


## 手动强制更新一次（也可在动画关键帧调用）
func update_rim() -> void:
	if sprite == null or target == null or _material == null:
		return
	
	if not is_instance_valid(sprite) or not is_instance_valid(target):
		return
	
	# 1. 计算世界空间方向（从 Sprite 指向目标）
	var sprite_pos = sprite.global_position
	var target_pos = target.global_position
	var world_dir = (target_pos - sprite_pos)
	
	var distance = world_dir.length()
	
	# 2. 距离衰减
	var strength = 0.0
	if distance <= min_distance:
		strength = max_strength
	elif distance >= max_distance:
		strength = 0.0
	else:
		var t = (distance - min_distance) / (max_distance - min_distance)
		t = pow(1.0 - t, falloff_curve)		# 越近越强
		strength = t * max_strength
	
	# 3. 把方向转换到 Sprite 本地空间，并处理 flip
	var local_dir = world_dir.normalized()
	
	# 如果 Sprite 有旋转，先转回本地
	local_dir = sprite.global_transform.basis_xform_inv(local_dir)
	
	# 处理 flip_h / flip_v（镜像后 UV 方向相反）
	if sprite.flip_h:
		local_dir.x = -local_dir.x
	if sprite.flip_v:
		local_dir.y = -local_dir.y
	
	# 4. 传给 Shader（注意：Shader 里用这个方向向外采样）
	_material.set_shader_parameter("light_dir", local_dir)
	_material.set_shader_parameter("distance_strength", strength)


## 运行时更换目标
func set_target(new_target: Node2D) -> void:
	target = new_target
	update_rim()
