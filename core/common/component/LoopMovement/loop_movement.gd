extends Node

@export_category("路径配置")
## 目标状态节点列表。可以是 Node2D 或 Control（UI组件）。
## 父节点会以目标节点的本地坐标空间为准，同步其 position, scale, rotation。
@export var targets: Array[Node] = []

@export_category("时间与等待")
## 每次状态过渡的基础时间 (秒)
@export var base_duration: float = 2.0
## 状态过渡时间的随机范围
@export_range(0.0, 5.0) var duration_randomness: float = 0.0

## 抵达目标状态后的基础等待时间 (秒)
@export var base_wait_time: float = 1.0
## 等待时间的随机范围
@export_range(0.0, 5.0) var wait_randomness: float = 0.0

@export_category("动画曲线")
## 补间动画的过渡类型 (平滑启动/减速等)
@export var transition_type: Tween.TransitionType = Tween.TRANS_QUAD
## 补间动画的缓动方式
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT

# 内部变量
var current_index: int = 0
var direction: int = 1
var parent_node: Node

func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	parent_node = get_parent()
	if not parent_node:
		return
		
	# 过滤掉列表中未分配或失效的空节点
	targets = targets.filter(func(t): return is_instance_valid(t))
	
	if targets.size() < 2:
		push_warning("LocalPatrolTween: 请在列表中至少分配 2 个有效的目标节点！")
		return
		
	# 【修复 Bug】这里传入 targets[0] 而不是整个数组 targets
	_sync_node_state(parent_node, targets[0])
	
	# 从第二个目标状态开始过渡
	current_index = 1
	direction = 1
	
	_start_next_move()

## 获取随机值
func _get_randomized_value(base: float, randomness: float) -> float:
	var offset = randf_range(-randomness, randomness)
	return max(0.0, base + offset)

## 核心状态过渡控制
func _start_next_move() -> void:
	if not is_instance_valid(parent_node) or targets.size() < 2:
		return

	var target_node = targets[current_index]
	var current_duration = _get_randomized_value(base_duration, duration_randomness)
	
	# 创建一个并行 Tween（让相对位置、缩放、旋转同时发生动画）
	var tween = create_tween().set_parallel(true)
	tween.set_trans(transition_type)
	tween.set_ease(ease_type)
	
	# 自动兼容并跨属性插值
	_tween_node_state(tween, parent_node, target_node, current_duration)
	
	# 当并行的所有动画都播完后，执行回调
	tween.chain().finished.connect(func():
		var current_wait = _get_randomized_value(base_wait_time, wait_randomness)
		_update_next_index()
		
		if current_wait > 0:
			get_tree().create_timer(current_wait).timeout.connect(_start_next_move)
		else:
			_start_next_move()
	)

## 计算倒序循环索引
func _update_next_index() -> void:
	if current_index == targets.size() - 1 and direction == 1:
		direction = -1
	elif current_index == 0 and direction == -1:
		direction = 1
	current_index += direction

## 游戏开始时强制同步本地（相对）状态
func _sync_node_state(from_node: Node, to_node: Node) -> void:
	if (from_node is Node2D and to_node is Node2D) or (from_node is Control and to_node is Control):
		from_node.position = to_node.position
		from_node.rotation = to_node.rotation
		from_node.scale = to_node.scale

## 运行中用 Tween 对本地属性进行并行插值
func _tween_node_state(tween: Tween, from_node: Node, to_node: Node, duration: float) -> void:
	if (from_node is Node2D and to_node is Node2D) or (from_node is Control and to_node is Control):
		tween.tween_property(from_node, "position", to_node.position, duration)
		tween.tween_property(from_node, "rotation", to_node.rotation, duration)
		tween.tween_property(from_node, "scale", to_node.scale, duration)
