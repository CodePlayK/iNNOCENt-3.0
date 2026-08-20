extends HBoxContainer

@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player: Player = %Player
@onready var in_game_debug_layer: CanvasLayer = $"../../../InGameDebugLayer"



@export_category("过场设置")
@export var cutscener_trigger: Area2D = $"../../Parallax/ParallaxLayer_6/CutsceneTrigger/CutscenerTrigger"
func _on_cutscene_runner_pressed() -> void:
	CutscenerGlobal.cutscener_run.emit("NA")


func _on_but_0_pressed() -> void:
	in_game_debug_layer.visible = !in_game_debug_layer.visible
