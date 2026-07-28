extends Component
@onready var player_camera: Camera2D = %PlayerCamera

func _ready() -> void:
	EventBus.cutscene_camera.connect(_on_cutscene_camera)
	EventBus.cutscene_camera_reset.connect(_on_cutscene_camera_reset)
	
func _on_cutscene_camera(dic_markers:Dictionary):
	if !dic_markers or dic_markers.size()==0:
		Debug.dprinterr(DebugCT.dp("镜头数据有误!"+str(dic_markers),self,))
	var tween=player_camera.create_tween()
	for marker in dic_markers.keys():
		tween.chain().tween_property(player_camera,"global_position",marker.global_position,dic_markers[marker])
	await tween.finished
	tween.kill()
	
func _on_cutscene_camera_reset():
	player_camera.position=Vector2.ZERO
