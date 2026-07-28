extends Node
@onready var obj: Node = $".."
@onready var master: Master = %Master
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if master:
		master.master_ready.connect(obj.on_master_ready)
	else :
		await master.ready
		master.master_ready.connect(obj.on_master_ready)
