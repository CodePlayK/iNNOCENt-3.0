extends NpcsCombatState
class_name NpcBehitState
var tween:Tween
@export var back_distance:float
@export var stiff_time:float = .2
@export var froze_time:float = 0
@export var protect_time:float = .2
@export var hurt_fx_name:String
@onready var protect_timer: Timer = $ProtectTimer
@onready var bati_protect_timer: Timer = $BatiProtectTimer
@export var be_hit_time_max_2_bati: int = 0
var enable:bool = true
		
func pre_enter() -> bool:
	return true
	
func enter():
	super.enter()
	npc.being_hit = false
	if !npc.bating :
		npc.be_hit_times+=1
	npc.blood_surface.blood_splash()
	enable = false
	npc.health.damage(state_manager.current_damage)
	npc.hurt_fx.play_fx(hurt_fx_name)
	var npc_global_position_x:float=npc.global_position.x
	tween=npc.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(npc,"global_position",Vector2(npc_global_position_x-back_distance*get_relative_position_x_2_player(),npc.global_position.y),stiff_time)
	if npc.health.current_health<=0:
		tween.chain().tween_interval(.5)
		await tween.finished
		tween.kill()
		return death_state
	tween.chain().tween_interval(froze_time)
	await tween.finished
	tween.kill()
	if !npc.bating and npc.be_hit_times >= be_hit_time_max_2_bati:
		npc.bating = true
		bati_protect_timer.start()
	return chase_state
	
func exit(state:NpcsBaseState):
	enable = true
	state_manager.current_damage = 0
	tween.kill()

func _on_protect_timer_timeout() -> void:
	enable = true


func _on_bati_protect_timer_timeout() -> void:
	if state_manager.current_state.anime_config:
		for bati in state_manager.current_state.anime_config.bati_config:
			npc.bating = bati.bating
