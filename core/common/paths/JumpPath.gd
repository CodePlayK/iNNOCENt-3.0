@tool
extends Path2D
@onready var right_contect: Area2D = $RightContect
@onready var left_contect: Area2D = $LeftContect
@onready var update_timer: Timer = $UpdateTimer
@onready var path_follow: PathFollow2D = $PathFollow
@onready var trans: RemoteTransform2D = $PathFollow/Trans
@onready var player: Player = %Player

@export var time:float = 1
@export var begin_side:BeginSide =BeginSide.LEFT
@export var end_type:EndType = EndType.MID
@export var end_type_margin:float=10
enum BeginSide{
	LEFT,
	RIGHT,
}
enum EndType{
	UP,
	MID,
	DOWN,
}
var on_trans:bool
var area
var mid_flag:bool = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_timer.start()
	if begin_side == BeginSide.LEFT:
		path_follow.progress_ratio = 0
	elif begin_side == BeginSide.RIGHT:
		path_follow.progress_ratio = 1
		
func _on_update_timer_timeout() -> void:
	left_contect.position = curve.get_point_position(0)
	right_contect.position = curve.get_point_position(2)

func _on_left_contect_area_entered(area1: Area2D) -> void:
	if end_type==EndType.UP:
		pass
	var tp =get_player_pos_type(right_contect.global_position)
	if end_type !=tp:
		Debug.dprintwarn(DebugCT.dp("目标类型[%s]" %tp,self))
		return
	if area1.enable and begin_side==BeginSide.LEFT:
		Debug.dprintwarn(DebugCT.dp("激活左侧跳跃",self))
		path_follow.progress_ratio = 0
		area = area1
		trans.remote_path=trans.get_path_to(area1.obj)
		area1.jump_trans_begin()
		on_trans = true
		var tween = path_follow.create_tween()
		tween.tween_property(path_follow,"progress_ratio",1,time)
		await tween.finished
		await RenderingServer.frame_post_draw
		tween.kill()
		on_trans = false
		mid_flag = true
		trans.remote_path = ""
		path_follow.progress_ratio = 0
		area1.jump_trans_finished()
		
func _on_right_contect_area_entered(area1: Area2D) -> void:
	var tp =get_player_pos_type(right_contect.global_position)
	if end_type !=tp:
		Debug.dprintwarn(DebugCT.dp("目标类型[%s]" %tp,self))
		return
	if area1.enable and begin_side==BeginSide.RIGHT:
		Debug.dprintwarn(DebugCT.dp("激活右侧跳跃",self))
		path_follow.progress_ratio =1
		area = area1
		trans.remote_path=trans.get_path_to(area1.obj)
		area1.jump_trans_begin()
		on_trans = true
		var tween = path_follow.create_tween()
		tween.tween_property(path_follow,"progress_ratio",0,time)
		await tween.finished
		await RenderingServer.frame_post_draw
		tween.kill()
		on_trans = false
		mid_flag = true
		trans.remote_path = ""
		area1.jump_trans_finished()	
		path_follow.progress_ratio =1
		pass # Replace with function body.

func _physics_process(delta: float) -> void:
	if on_trans:
		var cx = curve.get_point_position(1).x
		var px = path_follow.position.x
		if begin_side == BeginSide.LEFT:
			if mid_flag and cx <= px:
				mid_flag = false
				area.jump_trans_midway()
		elif begin_side == BeginSide.RIGHT:
			if mid_flag and cx >= px:
				mid_flag = false
				area.jump_trans_midway()

func get_player_pos_type(pos):
	Debug.dprintwarn(DebugCT.dp("判断type[%s]->[%s]" %[player.global_position.y,pos.y],self))
	if player.global_position.y + end_type_margin < pos.y:
		return EndType.UP
	elif player.global_position.y - end_type_margin > pos.y:
		return EndType.DOWN
	else :
		return EndType.MID
