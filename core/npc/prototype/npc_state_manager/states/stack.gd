@icon("res://core/common/resource/icon/FSMStateIntegration.svg")
extends NpcsBaseState
## 可叠加状态。stack 分组节点应勾选 is_group，叶子状态不要勾选。
class_name NpcsStackingState
@export_category("叠加状态配置")
@export_group("音效配置")
## 进入叠加状态时播放的音效配置
@export var sound_config:SoundEffectConfig
