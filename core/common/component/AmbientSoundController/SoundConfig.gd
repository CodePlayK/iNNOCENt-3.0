extends Resource
class_name SoundConfig
@export var audio_res:AudioStream
@export_enum("Effect","Ambient","Music","UI") var play_type:String = "Effect"
@export var crossfade_duration:float = 0.1
@export var volume:float = 1
