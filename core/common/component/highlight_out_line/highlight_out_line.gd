extends Node
@onready var obj = $".."
var outline
#物体高亮边缘
#要求高亮sprite名称为「Outline」，放于一层子类
func _ready():
	obj.mouse_entered.connect(_highlight_on)
	obj.mouse_exited.connect(_highlight_off)

func _highlight_on():
	outline.show()
	
func _highlight_off():
	outline.hide()

func init(sprite):
	outline = sprite
	outline.hide()
