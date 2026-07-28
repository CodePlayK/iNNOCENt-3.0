@tool
extends Node
class_name BaseEvents
@export var event:EventConfig
var event_config
var lock:bool = true

func _ready() -> void:
	init()
	event = EventData.get_event_config(event_config)
	event.refer_node_paths.append(get_path())
	event.event_key = event_config
	config()
	import()
	
func import() -> void:
	EventData.add_event(event)
	lock = false

func init():
	pass
	
func config():
	pass

func update_key():
	pass
