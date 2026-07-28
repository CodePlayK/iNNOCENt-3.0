extends HBoxContainer
@onready var enemy_timer: Timer = $VBoxContainer/HBoxContainer/enemy/enemyTimer
@onready var patrol_left: Marker = $"../../Parallax/ParallaxLayer_6/Marks/PatrolLeft"
@onready var patrol_right: Marker = $"../../Parallax/ParallaxLayer_6/Marks/PatrolRight"
@onready var npcs: Node2D = $"../../Parallax/ParallaxLayer_6/Npcs"
@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player: Player = %Player


@export_category("心里测试")
@export var dialogue_mind_config:DialogueConfig
@export_category("通用测试")
@export var print_control_focus_obj:bool = false
@export_category("敌人测试配置")
@export var astar:AStarMap
@export var enemy_max_count:int = 10
@export_category("相机测试配置")
@export var camera_shake_add:float
@export var enemy:ENEMY = ENEMY.BLOOD_KING
@export var prototype:Node2D
@export_group("寻路设置")
@export var enable_ray_path_finding:bool = false
@export var range_r:float
@export var test_vec2:Vector2
@export var chase_speed:float = 500
@export var npc_name:String
@export var target_node:Node2D

var target_flag:bool = false
var enemy_dic={
	ENEMY.NPC:preload("res://core/npc/prototype/npc.tscn"),
	ENEMY.BLOOD_KING:preload("res://core/npc/blood_king/blooad_king.tscn"),
}
enum ENEMY {
	NPC,
	BLOOD_KING,
}

func _on_enemy_pressed() -> void:
	pass # Replace with function body.


func generate_enemy():
	var sen = enemy_dic[enemy].instantiate()
	sen.hide()
	sen.global_position.x=randf_range(patrol_left.global_position.x,patrol_right.global_position.x)
	sen.global_position.y = prototype.global_position.y
	npcs.add_child(sen)
	sen.init_config(NpcInitConfig.new(prototype.patrol_left,prototype.patrol_right))
	var material = prototype.base.material.duplicate()
	sen.base.material=material
	var materialv = prototype.base_fx.material.duplicate()
	sen.base_fx.material=materialv
	sen.show()
	await RenderingServer.frame_post_draw

func _on_enemy_timer_timeout() -> void:
	if npcs.get_child_count()<enemy_max_count+1:
		generate_enemy()


func _on_enemy_toggled(toggled_on: bool) -> void:
	if toggled_on:
		enemy_timer.start()
	else :
		enemy_timer.stop()

func _on_cam_shake_pressed() -> void:
	player_camera.add_shake(camera_shake_add)

func _input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var c = get_viewport().gui_get_focus_owner()
		if c:
			if print_control_focus_obj:Debug.dprintwarn(DebugCT.dp("[当前焦点]%s" %[c.get_path()],self))
		pass
	var c = get_viewport().gui_get_hovered_control()
	if c:
		var e = c.get_mouse_filter_with_override() 
		if e!=0:return 
		var f = c.get_path().get_concatenated_names()
		var g ="[当前焦点]:"+f+"-"+ str(e)
		if print_control_focus_obj:Debug.dprintwarn(DebugCT.dp(g ,self))

	
func _ready() -> void:	
	pass

func _process(delta: float) -> void:
	pass

	#await get_tree().create_timer(.2).timeout
func _physics_process(delta: float) -> void:
	pass

func _on_move_to_node_pressed() -> void:
	target_flag=!target_flag
	if target_flag:
		EventBus._move_2_vec2(npc_name,target_node.global_position,1)
	else :
		var t = target_node.global_position - Vector2(1000,0)
		EventBus._move_2_vec2(npc_name,t,1)

func _on_show_astar_pressed() -> void:
	astar.enabel_ui = !astar.enabel_ui
@onready var player_camera_aniplayer: AnimationPlayer = $"../../Setting/PlayerCamera/PlayerCameraAniplayer"
func _on_show_mind_box_pressed() -> void:
	player_camera_aniplayer.play("0_0_0")
@export_category("过场设置")
@export var cutscener_trigger: Area2D = $"../../Parallax/ParallaxLayer_6/CutsceneTrigger/CutscenerTrigger"
func _on_cutscene_runner_pressed() -> void:
	cutscener_trigger.enable=true
	CutscenerGlobal.cutscener_run.emit("NA")

@onready var eyes: TextureRect = $"../../ScreenEffect/Eyes"
var flag:bool = true
func _on_eyeseffect_pressed() -> void:
	EventBus._blood_splash()
	return


func _on_mouse_entered() -> void:
	pass # Replace with function body.
