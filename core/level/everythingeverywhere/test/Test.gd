extends HBoxContainer

@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player: Player = %Player
@onready var in_game_debug_layer: CanvasLayer = $"../../../InGameDebugLayer"




func _on_but_0_pressed() -> void:
	in_game_debug_layer.visible = !in_game_debug_layer.visible
##播放指定过场画
@export var cutscene_name:String = "NA"
##播放当前保存的默认过场
@export var play_NA:bool = true
func _on_but_1_pressed() -> void:
	CutscenerGlobal.cutscener_run.emit("NA")
	pass # Replace with function body.
