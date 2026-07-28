extends Component
##[必须挂载于npc对象下] 对象移动到玩家角色附近，并在途中与停止后面朝玩家
class_name Move2Vec2
signal move_finished
var obj
##停止移动的距离玩家距离
@export var distance:int
var temp_v:Vector2
var tween:Tween
var target:Vector2
func on_master_ready(master):
	obj = master.obj

func init_var():
	clazz_name="Move2Vec2"
	FATHER_CLASS_NAME="Npcs"
	
func connect_signal():
	return
	EventBus.move_2_vec2.connect(_move_2_vec2)

func _move_2_vec2(name:String,pos:Vector2,time:float=1):
	if name!=obj.obj_name:return null
	target = pos
	obj.astar.set_taget_position_mode()
	obj.state_manager.string2state("move2vec2",self)
	return
	if name!=obj.name:return null
	obj.anime.play_anime("patrol")
	if pos<obj.global_position :
		EventBus._obj_set_face_left(obj.name,true)
	else :
		EventBus._obj_set_face_left(obj.name,false)
	temp_v=Vector2(pos.x+distance,obj.global_position.y)
	tween=obj.create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(obj,"global_position",temp_v,time)
	await tween.finished
	tween.kill()
	obj.anime.play_anime("idle")
	
func move_2_vec2(pos:Vector2,time:float=1):
	await _move_2_vec2(obj.name,pos,time)
func stop():
	tween.kill()
