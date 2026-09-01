extends Node
@onready var sparks_effector: SparksContainer = $"../../Parallax/ParallaxLayer_4/SparksEffector"

func _ready() -> void:
	EventBus.player_health_damaged.connect(on_player_health_damaged)
	
func on_player_health_damaged():
	sparks_effector.explode_sparks()
