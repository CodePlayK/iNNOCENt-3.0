@tool
extends Panel
@export var color_normal:Color:
	set(c):
		color_normal = c
		self.modulate = c
@export var color_enable:Color:
	set(c):
		color_enable = c
		self.modulate = c
@export var color_disable:Color:
	set(c):
		color_disable = c
		self.modulate = c
