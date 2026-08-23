extends Node2D
class_name LevelTransation

@onready var falling_box: ColorRect = $FALLING_BOX

enum TRANSITION_NAME {
	FALLING_BOX
}

enum TRANSITION_TYPE {
	IN,
	OUT
}

func _ready() -> void:
	falling_box.item_rect_changed.connect(_update_shader_size)
	reset()

func reset():
	falling_box.hide()
	_update_shader_size()
	_set_shader_progress(0.0)

func _update_shader_size() -> void:
	if falling_box and falling_box.material:
		falling_box.material.set_shader_parameter("rect_size", falling_box.size)

func _set_shader_progress(val: float) -> void:
	if falling_box and falling_box.material:
		falling_box.material.set_shader_parameter("progress", val)

# --- 核心新增：每次播放前随机刷新 Shader 的种子 ---
func _randomize_shader_seed() -> void:
	if falling_box and falling_box.material:
		# 生成一个 0 到 1000 之间的随机浮点数作为种子
		var random_seed = randf_range(0.0, 1000.0)
		falling_box.material.set_shader_parameter("seed", random_seed)

func play_transition(trans_name: TRANSITION_NAME, trans_type: TRANSITION_TYPE, duration: float):
	_update_shader_size()
	
	# 【核心】：只要是启动新动画（无论是进入还是退出），都刷新一次位置和速度的随机组合
	_randomize_shader_seed()
	
	var tw = create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	
	match trans_type:
		TRANSITION_TYPE.IN:
			reset()
			# 重新刷新一次，确保 reset 后的种子也是全新的
			_randomize_shader_seed() 
			falling_box.show()
			
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_method(_set_shader_progress, 0.0, 1.0, duration)
			await tw.finished
			
		TRANSITION_TYPE.OUT:
			falling_box.show()
			
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_method(_set_shader_progress, 1.0, 0.0, duration)
			await tw.finished
			falling_box.hide()
