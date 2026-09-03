extends Component
class_name SoundEffect
@onready var master: Node = %Master

func play_se(sound_config: SoundEffectConfig, obj) -> void:
	if sound_config == null:
		return
	if sound_config.start_time != 0.0:
		await get_tree().create_timer(sound_config.start_time).timeout
	var owner_id := str(owner.get_instance_id() + obj.get_instance_id())
	# EventBus: name, speed(pitch_scale 用 speed), volume_db, owner, state
	# 使用 se_pitch 作为播放速率更符合原字段语义；volume 用 se_volume_db
	var pitch := sound_config.se_pitch if sound_config.se_pitch != 0.0 else sound_config.se_speed
	EventBus._play_SE(sound_config.se_name, pitch, sound_config.se_volume_db, owner_id, true)
