extends Resource
class_name SoundEffectConfig

@export var start_time: float = 0.0
@export var se_name: String = ""
@export var se_speed: float = 1.0
## 音高（pitch_scale），不是音量
@export var se_pitch: float = 1.0
## 额外音量偏移 dB（0 表示使用字典默认）
@export var se_volume_db: float = 0.0
