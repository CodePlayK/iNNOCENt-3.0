extends Area2D
@export var cutscen_runner_name:String
@export var enable:bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _on_body_entered(body: Node2D) -> void:
	if !enable:return
	CutscenerGlobal.cutscener_run.emit("0_0_1")
	enable = false

func _on_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
