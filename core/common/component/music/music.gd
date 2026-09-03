extends Node
## 全局音频管理（Autoload: Music）
## - BGM / SE（一次性） / SE_LOOP（可随场景停止的循环） / Ambient（环境循环）
## - 使用对象池，避免「没有空闲播放器就丢音效」
## - 通过 AudioBus 提供全局音量：背景音乐 / 效果音 / 环境音

const BUS_BGM := "BGM"
const BUS_SE := "SE"
const BUS_AMBIENT := "Ambient"

## 配置结构约定：
## [stream, volume_db=0.0, stop_on_level_change=false, is_ambient=false]
## is_ambient=true 的循环走 Ambient 总线与池

var BGM_dic: Dictionary = {
	"piano_happy": [preload("res://core/common/sound/BGM/daily/piano-happy.mp3")],
	"slowly": [preload("res://core/common/sound/BGM/daily/slowly-129845.mp3")],
	"by_the_side_of_a_spring": [preload("res://core/common/sound/BGM/daily/by_the_side_of_a_spring-131449.mp3")],
}

var SE_dic: Dictionary = {
	"light_switch_off": [preload("res://core/common/sound/SE/light_on.mp3")],
	"light_switch_on": [preload("res://core/common/sound/SE/light_off.mp3")],
	"door_close": [preload("res://core/common/sound/SE/door-opening-and-closing-18398_iCigwa2W.mp3"), -20.0],
	"corridor_door_close": [preload("res://core/common/sound/SE/heavy-mechancial-door-open-6934.mp3")],
	"bubble": [preload("res://core/common/sound/SE/气泡.mp3")],
	"steel_clash": [preload("res://core/common/sound/SE/steelclash.mp3"), -7.0],
	"be_hit_by_body": [preload("res://core/common/sound/SE/behitbybody.mp3"), -10.0],
	"talking": [preload("res://core/common/sound/SE/talking.mp3")],
	"slash1": [preload("res://core/common/sound/SE/slash1.mp3")],
	"slash2": [preload("res://core/common/sound/SE/slash2.mp3")],
	"slash3": [preload("res://core/common/sound/SE/slash3.mp3")],
	"slash4": [preload("res://core/common/sound/SE/slash4.mp3")],
	"slash5": [preload("res://core/common/sound/SE/slash5.mp3")],
	"slash6": [preload("res://core/common/sound/SE/slash6.mp3")],
	"slash7": [preload("res://core/common/sound/SE/slash7.mp3")],
	"punch": [preload("res://core/common/sound/SE/punch.mp3")],
	"cut-body": [preload("res://core/common/sound/SE/cut-body.mp3")],
	"knife-stab": [preload("res://core/common/sound/SE/knife-stab.mp3")],
	"lazer": [preload("res://core/common/sound/SE/lazer.mp3")],
	"foot_step": [preload("res://core/common/sound/SE/footsteps-sneakers-on-tile-running-33003_amTjc1NI.mp3"), -10.0],
	"bare_foot_step": [preload("res://core/common/sound/SE/19-pasos-nina-ver2-29199_qZzBtE62.mp3"), -5.0],
	"stamina_error": [preload("res://core/common/sound/SE/error-llargs.mp3")],
}

## 循环音效（脚步等会随切关停止）；环境音 is_ambient=true
var SE_LOOP_dic: Dictionary = {
	"foot_step": [preload("res://core/common/sound/SE/footsteps-sneakers-on-tile-running-33003_amTjc1NI.mp3"), -10.0, true, false],
	"bare_foot_step": [preload("res://core/common/sound/SE/19-pasos-nina-ver2-29199_qZzBtE62.mp3"), -5.0, true, false],
	"running-in-grass": [preload("res://core/common/sound/SE/loop/running-in-grass.mp3"), -5.0, true, false],
	"forest-ambient": [preload("res://core/common/sound/SE/loop/mystic-forest-ambient.mp3"), -5.0, false, true],
	"wind-in-trees": [preload("res://core/common/sound/SE/loop/wind-in-trees.mp3"), -5.0, false, true],
}

@onready var _bgm_root: Node = $BGM
@onready var _se_root: Node = $SE
@onready var _loop_root: Node = $SE_LOOP
@onready var _ambient_root: Node = $Ambient

## free pools
var _bgm_free: Array[AudioStreamPlayer] = []
var _se_free: Array[AudioStreamPlayer] = []
var _loop_free: Array[AudioStreamPlayer] = []
var _ambient_free: Array[AudioStreamPlayer] = []

## active: key -> player
var _bgm_active: Dictionary = {} # effect_name -> AudioStreamPlayer
var _se_active: Dictionary = {} # owner|effect -> AudioStreamPlayer
var _loop_active: Dictionary = {} # effect_name -> AudioStreamPlayer
var _ambient_active: Dictionary = {} # effect_name -> AudioStreamPlayer

var _level_change_lock: bool = false
var _na_counter: int = 0

## 线性音量缓存 0.0~1.0（供设置 UI 读写）
var bgm_volume_linear: float = 1.0
var se_volume_linear: float = 1.0
var ambient_volume_linear: float = 1.0


func _ready() -> void:
	_collect_pool(_bgm_root, _bgm_free, BUS_BGM)
	_collect_pool(_se_root, _se_free, BUS_SE)
	_collect_pool(_loop_root, _loop_free, BUS_SE)
	_collect_pool(_ambient_root, _ambient_free, BUS_AMBIENT)

	EventBus.play_SE.connect(_on_play_SE)
	EventBus.play_SE_LOOP.connect(_on_play_SE_LOOP)
	EventBus.play_BGM.connect(_on_play_BGM)
	EventBus.change_level.connect(_on_change_level)

	# 确保总线存在（编辑器未同步 layout 时兜底）
	_ensure_bus(BUS_BGM)
	_ensure_bus(BUS_SE)
	_ensure_bus(BUS_AMBIENT)

	set_bgm_volume(bgm_volume_linear)
	set_se_volume(se_volume_linear)
	set_ambient_volume(ambient_volume_linear)


func _collect_pool(root: Node, free_list: Array[AudioStreamPlayer], bus_name: String) -> void:
	for c in root.get_children():
		if c is AudioStreamPlayer:
			var p := c as AudioStreamPlayer
			p.bus = bus_name
			if not p.finished.is_connected(_on_player_finished.bind(p, free_list)):
				# 一次性 SE 播放完回收；循环不依赖 finished
				pass
			free_list.append(p)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")


#region Global volume API（线性 0~1）
func set_bgm_volume(linear: float) -> void:
	bgm_volume_linear = clampf(linear, 0.0, 1.0)
	_set_bus_linear(BUS_BGM, bgm_volume_linear)


func set_se_volume(linear: float) -> void:
	se_volume_linear = clampf(linear, 0.0, 1.0)
	_set_bus_linear(BUS_SE, se_volume_linear)


func set_ambient_volume(linear: float) -> void:
	ambient_volume_linear = clampf(linear, 0.0, 1.0)
	_set_bus_linear(BUS_AMBIENT, ambient_volume_linear)


func get_bgm_volume() -> float:
	return bgm_volume_linear


func get_se_volume() -> float:
	return se_volume_linear


func get_ambient_volume() -> float:
	return ambient_volume_linear


func _set_bus_linear(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(linear, 0.0001)))
	AudioServer.set_bus_mute(idx, linear <= 0.001)
#endregion


func _on_change_level(_room) -> void:
	_level_change_lock = true
	# 停止「切关需停」的循环 SE
	var to_release: Array = []
	for key in _loop_active.keys():
		var cfg = SE_LOOP_dic.get(key)
		if cfg and cfg.size() > 2 and cfg[2]:
			var p: AudioStreamPlayer = _loop_active[key]
			p.stop()
			_loop_free.append(p)
			to_release.append(key)
	for k in to_release:
		_loop_active.erase(k)
	_level_change_lock = false


func _acquire(free_list: Array[AudioStreamPlayer], active: Dictionary, root: Node, bus_name: String) -> AudioStreamPlayer:
	# 1) 空闲池
	while free_list.size() > 0:
		var p: AudioStreamPlayer = free_list.pop_back()
		if is_instance_valid(p):
			return p
	# 2) 回收已停止但仍占 active 的（仅对 SE 有意义）
	var dead_keys: Array = []
	for k in active.keys():
		var ap: AudioStreamPlayer = active[k]
		if not is_instance_valid(ap) or not ap.playing:
			dead_keys.append(k)
			if is_instance_valid(ap):
				free_list.append(ap)
	for k in dead_keys:
		active.erase(k)
	if free_list.size() > 0:
		return free_list.pop_back()
	# 3) 动态扩容，避免丢音效
	var np := AudioStreamPlayer.new()
	np.bus = bus_name
	np.process_mode = Node.PROCESS_MODE_ALWAYS if bus_name != BUS_SE else Node.PROCESS_MODE_INHERIT
	root.add_child(np)
	return np


func _release_to_pool(player: AudioStreamPlayer, free_list: Array[AudioStreamPlayer], active: Dictionary, key) -> void:
	if active.has(key) and active[key] == player:
		active.erase(key)
	player.stop()
	player.stream = null
	if not free_list.has(player):
		free_list.append(player)


func _default_volume_db(cfg: Array, override_db: float) -> float:
	if override_db != 0.0:
		return override_db
	if cfg.size() > 1 and typeof(cfg[1]) in [TYPE_FLOAT, TYPE_INT]:
		return float(cfg[1])
	return 0.0


func _apply_playback(player: AudioStreamPlayer, stream: AudioStream, pitch: float, vol_db: float) -> void:
	player.stream = stream
	player.pitch_scale = pitch
	player.volume_db = vol_db
	player.play()


#region BGM
func _on_play_BGM(effect_name: String, state: bool = true, speed: float = 1.0, effect_volume: float = 0.0) -> void:
	if not BGM_dic.has(effect_name):
		return
	if state:
		if _bgm_active.has(effect_name):
			var p: AudioStreamPlayer = _bgm_active[effect_name]
			if p.playing:
				p.pitch_scale = speed
				p.volume_db = _default_volume_db(BGM_dic[effect_name], effect_volume)
				return
			_apply_playback(p, BGM_dic[effect_name][0], speed, _default_volume_db(BGM_dic[effect_name], effect_volume))
			return
		var player := _acquire(_bgm_free, _bgm_active, _bgm_root, BUS_BGM)
		_bgm_active[effect_name] = player
		_apply_playback(player, BGM_dic[effect_name][0], speed, _default_volume_db(BGM_dic[effect_name], effect_volume))
	else:
		if _bgm_active.has(effect_name):
			_release_to_pool(_bgm_active[effect_name], _bgm_free, _bgm_active, effect_name)
#endregion


#region SE one-shot
func _on_play_SE(effect_name: String, speed: float = 1.0, effect_volume: float = 0.0, owner_name: String = "NA", state: bool = true) -> void:
	if _level_change_lock:
		return
	if not SE_dic.has(effect_name):
		return
	var k_name := "%s|%s" % [owner_name, effect_name]
	if state:
		var player: AudioStreamPlayer
		if _se_active.has(k_name) and is_instance_valid(_se_active[k_name]):
			player = _se_active[k_name]
		else:
			player = _acquire(_se_free, _se_active, _se_root, BUS_SE)
			_se_active[k_name] = player
			# 播完自动回收（避免池枯竭）
			if not player.finished.is_connected(_on_se_finished):
				player.finished.connect(_on_se_finished.bind(player, k_name))
		_apply_playback(player, SE_dic[effect_name][0], speed, _default_volume_db(SE_dic[effect_name], effect_volume))
	else:
		if _se_active.has(k_name):
			_release_to_pool(_se_active[k_name], _se_free, _se_active, k_name)


func _on_se_finished(player: AudioStreamPlayer, k_name: String) -> void:
	if _se_active.get(k_name) == player:
		_se_active.erase(k_name)
		if not _se_free.has(player):
			_se_free.append(player)
#endregion


#region SE_LOOP / Ambient
func _on_play_SE_LOOP(effect_name: String, state: bool = true, speed: float = 1.0, effect_volume: float = 0.0) -> void:
	if _level_change_lock:
		return
	if not SE_LOOP_dic.has(effect_name):
		return
	var cfg: Array = SE_LOOP_dic[effect_name]
	var is_ambient: bool = cfg.size() > 3 and bool(cfg[3])
	var free_list := _ambient_free if is_ambient else _loop_free
	var active := _ambient_active if is_ambient else _loop_active
	var root := _ambient_root if is_ambient else _loop_root
	var bus_name := BUS_AMBIENT if is_ambient else BUS_SE

	if state:
		if active.has(effect_name) and is_instance_valid(active[effect_name]):
			var p: AudioStreamPlayer = active[effect_name]
			p.pitch_scale = speed
			p.volume_db = _default_volume_db(cfg, effect_volume)
			if not p.playing:
				p.stream = cfg[0]
				p.play()
			return
		var player := _acquire(free_list, active, root, bus_name)
		active[effect_name] = player
		_apply_playback(player, cfg[0], speed, _default_volume_db(cfg, effect_volume))
	else:
		if active.has(effect_name):
			_release_to_pool(active[effect_name], free_list, active, effect_name)
#endregion
