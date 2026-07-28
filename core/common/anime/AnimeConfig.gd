extends Resource
class_name AnimeConfig
@export var state_name:String = "NA"
@export_group("动画配置")
@export var animation_name:String = "NA"
var has_animation:bool = true
@export var speed_scale:float = 1
@export var speed_scale_curve:Curve
@export var backward:bool = false
@export var loop:bool = false
@export var anime_offset:Array[AnimeOffsetConfig]
@export_group("音效配置")
@export var sound_config:Array[AnimeSoundConfig]
@export_group("战斗配置")
@export_subgroup("hitbox配置")
@export var hitbox_config:Array[AnimeHitBoxConfig]
@export var fx_hitbox_config:Array[AnimeFxHitboxConfig]
@export_subgroup("霸体配置")
@export var bati_config:Array[AnimeBatiConfig]
@export_subgroup("无敌配置")
@export var invincible_config:Array[AnimeInvincibleConfig]
@export_subgroup("FX配置")
@export var fx_config:Array[AnimeFxConfig]
