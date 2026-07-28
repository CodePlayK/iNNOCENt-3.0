extends PlayerInteractiveObj
var base_sprite:Sprite2D
@onready var highlight_out_line: Node = $HighlightOutLine
@export var dialogue_config:DialogueConfig
func _ready() -> void:
	for node in get_children():
		if node is Sprite2D:
			base_sprite = node
			break
	var outline:Sprite2D = base_sprite.duplicate()
	outline.material = base_sprite.material
	base_sprite.material = null
	add_child(outline)
	highlight_out_line.init(outline)
	var dialogue
	for n in get_children():
		if n is DialogueContect or n is DialogueMouse:
			dialogue = n
			break
	if dialogue:dialogue.init(self)
