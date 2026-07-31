extends Component
@export var target_level:LevelState.LEVELS = 0
@onready var area: Area2D = $Area2D

func _ready() -> void:
	area.body_entered.connect(on_player_enter)

func on_player_enter(body):
	EventBus._change_level(target_level)
