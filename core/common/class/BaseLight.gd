extends PointLight2D
class_name BaseLight
@export var level: Levels

func _ready() -> void:
	level = owner
	Global.add_2_level_lights_dic(level.level_id,self)
	
