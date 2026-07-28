extends Component
class_name SoundEffect
@onready var master: Node = %Master

func play_se(sound_config:SoundEffectConfig,obj):
	if !sound_config.start_time == 0.0:
		await get_tree().create_timer(sound_config.start_time).timeout
	#if obj is NpcsBaseState or BaseState:
		#if !master.obj.state_manager.current_state == obj:return
	EventBus._play_SE(sound_config.se_name,sound_config.se_speed,sound_config.se_pitch,str(owner.get_instance_id()+obj.get_instance_id()))
