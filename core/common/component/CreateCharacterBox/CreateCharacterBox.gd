extends Component
var obj
@onready var timer: Timer = $Timer
#生成角色box的延迟随机范围
@export var time_rand_range:Vector2 = Vector2(1,3)
func on_master_ready(master:Master):
	timer.start(randf_range(time_rand_range.x,time_rand_range.y))
	obj = master.obj



func _on_timer_timeout() -> void:
	EventBus._create_character_box(obj.character_box_config)
	pass # Replace with function body.
