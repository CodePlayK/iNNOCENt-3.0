@icon("res://core/common/resource/icon/anime_icon.svg")
extends Node2D
class_name Anime
signal anime_finished
@onready var master: Node = %Master
@onready var animations: Animations = $".."

@export_group("Anime基础设置")
##基础精灵图
@export var base: Sprite2D
##基础animationPlayer
@export var aniplayer: AnimationPlayer
##附加精灵图
@export var sprite_list: Array[Sprite2D]
##染色精灵图
@export var colored_node_list: Array[Node2D]
##特效节点,会根据特效名获取一级子类,并执行playAFX
@export var anime_fx: Node2D
##当前动画名
@export var current_animation:String
##当前帧
@export var current_frame:int = 0
		
@export_group("Anime详细设置")
##动画配置列表
@export var animes:Array[AnimeConfig]
##动画长度
@export var current_animation_length:float
##fx颜色
@export var fx_color:Color ="ffffff":
	set(c):
		fx_color = c
		on_change_shader()
##随机染色
@export var is_rand_color:bool =false
##随机颜色列表
@export var rand_color:Array[Color]=[Color.AQUA,Color.RED,Color.YELLOW,Color.CHOCOLATE,Color.BLACK,Color.WHITE]
##混合modulate
@export_range(-2.0, 3.0) var mix_modulate_scale:float=2:
	set(f):
		mix_modulate_scale = f
		on_change_shader()
@export_group("Debug")
##打印播放的anime
@export var print_play_anime:bool = false
##打印播放声音
@export var print_sound:bool = false
##打印fx
@export var print_fx:bool = false
##打印hitbox
@export var print_hitbox:bool = false
@export var p_stop_anime:bool = false
##动画字典{状态名:对应animeConfig}
var anime_dic:Dictionary
##缓存
var cache:Dictionary
##默认速度倍率
var base_speed_scale:float
##偏移tween
var offset_tweens:Array
##偏移启用
var offset_enable:bool = false
##当前动画
var animation:Animation
##sprite2D的帧映射到单独动画帧
var ani_frame_dic:Dictionary
##上一帧
var last_base_frame:int
##当前animeConfig
var anime:AnimeConfig
var play_lock:bool = true
##初始化
func import():
	if animes:##获取anime字典
		for anime_config in animes:
			anime_dic[anime_config.state_name] = anime_config
	for ani_name in aniplayer.get_animation_list():
		var ani:Animation = aniplayer.get_animation(ani_name)
		var np = NodePath(str(aniplayer.get_node(aniplayer.root_node).get_path_to(base))+":frame")
		var track = ani.find_track(np,0)
		if track<0:continue
		ani_frame_dic[ani_name] = {}
		ani_frame_dic[ani_name]["tk"]= track
		for ti in ani.track_get_key_count(track):##获取base的frame在各自动画中映射的帧数
			ani_frame_dic[ani_name][ani.track_get_key_value(track,ti)] = ti
##播放初始化
func preset_anime(anime):
	master.obj.hurt_box.enable_hit()
	offset_enable = true
	current_animation = anime.animation_name
	on_change_shader()
	for node in sprite_list:
		node.visible = true
	current_animation_length = 0

##执行动画		
func play_anime(anime_name:String):
	play_lock = true
	if anime_name == "attack2":
		pass
	if print_play_anime:Debug.dprintwarn(DebugCT.dp("[Anime]播放:%s" %[anime_name],self))
	anime = anime_dic[anime_name]
	preset_cache(anime)
	preset_anime(anime)
	if aniplayer.has_animation(current_animation):
		aniplayer.stop()
		animation = aniplayer.get_animation(current_animation)
		aniplayer.speed_scale = anime.speed_scale
		current_animation_length = animation.length/anime.speed_scale
		if anime.state_name==anime.animation_name:
			if anime.loop:
				animation.loop_mode =Animation.LOOP_LINEAR
			else :
				animation.loop_mode =Animation.LOOP_NONE
		if !anime.backward:
			aniplayer.play(current_animation)
			aniplayer.advance(0)
		else :
			aniplayer.play_backwards(current_animation)
			aniplayer.advance(0)
	current_frame = 0
	play_lock = false
##处理帧			
func process() -> void:
	set_fx(anime)
	if current_animation!=aniplayer.current_animation:
		return
	if !anime_dic.has(current_animation):return
	if offset_enable:
		set_offset(anime)
	if master.obj.hit_box:
		set_hitbox(anime)	
	if master.obj.hurt_box:
		set_hurtbox(anime)	
	set_bati(anime)
	
##设置偏移量
func set_offset(anime:AnimeConfig):
	for offset_config:AnimeOffsetConfig in anime.anime_offset:
		if current_frame == offset_config.start_frame and aniplayer.current_animation == anime.animation_name:
			cache_off(anime.state_name+str(offset_config.start_frame))
			var time:float
			time = get_frame2frame_time(offset_config.start_frame,offset_config.end_frame)/aniplayer.speed_scale
			var tween = animations.create_tween()
			offset_tweens.append(tween)
			tween.tween_property(animations,"position",animations.position-Vector2(master.obj.face_left_normalozed*offset_config.target_vec2.x,offset_config.target_vec2.y),time)
			tween.parallel().tween_property(master.obj,"position",master.obj.position+Vector2(master.obj.face_left_normalozed*offset_config.target_vec2.x,offset_config.target_vec2.y),time)		
			await tween.finished
			tween.kill()
			cache_on(anime.state_name+str(offset_config.start_frame))
##设置霸体帧			
func set_bati(anime:AnimeConfig):
	for bati_config:AnimeBatiConfig in anime.bati_config:
		if current_frame == bati_config.bati_start_frame:
			bati_config.bating = true
		elif current_frame == bati_config.bati_end_frame:
			bati_config.bating = false
##设置hurtbox帧			
func set_hurtbox(anime:AnimeConfig):
	for ic:AnimeInvincibleConfig in anime.invincible_config:
		if !anime.backward:
			if ic.start_frame == current_frame:
				if !check_cache("ic"+str(ic.start_frame)):continue
				if print_hitbox:Debug.dprinterr(DebugCT.dp("Anime设置无敌帧[%s][%s]" %[current_animation,ic.start_frame],self))
				master.obj.hurt_box.disable_hit()
				cache_off("ic"+str(ic.start_frame))
			elif ic.end_frame == current_frame:
				if !check_cache("icf"+str(ic.start_frame)):continue
				if print_hitbox:Debug.dprinterr(DebugCT.dp("Anime取消无敌帧[%s][%s]" %[current_animation,ic.end_frame],self))
				master.obj.hurt_box.enable_hit()
				cache_off("icf"+str(ic.start_frame))
		else :
			if ic.start_frame == current_frame:
				if !check_cache("ic"+str(ic.start_frame)):continue
				master.obj.hurt_box.enable_hit()
				cache_off("ic"+str(ic.start_frame))
			elif ic.end_frame == current_frame:
				if !check_cache("icf"+str(ic.start_frame)):continue
				master.obj.hurt_box.disable_hit()
				cache_off("icf"+str(ic.start_frame))
##设置hitbox帧
func set_hitbox(anime):
	if master.obj.hit_box:
		for hc:AnimeHitBoxConfig in anime.hitbox_config:
			if !anime.backward:
				if hc.hit_start_frame == current_frame:
					if !check_cache(hc.collision_index+1):continue
					if print_hitbox:Debug.dprinterr(DebugCT.dp("Anime设置hitbox[%s][%s]" %[current_animation,hc.collision_index],self))
					master.obj.hit_box.damage = hc.damage
					master.obj.hit_box.set_enable(true,hc.collision_index)
					cache_off(hc.collision_index+1)
				elif hc.hit_end_frame == current_frame:
					if !check_cache(hc.collision_index-1):continue
					if print_hitbox:Debug.dprinterr(DebugCT.dp("Anime取消hitbox[%s][%s]" %[current_animation,hc.collision_index],self))
					master.obj.hit_box.damage = 0
					master.obj.hit_box.set_enable(false,hc.collision_index)
					cache_off(hc.collision_index-1)
			else :
				if hc.hit_start_frame == current_frame:
					if !check_cache(hc.collision_index-1):continue
					master.obj.hit_box.damage = 0
					master.obj.hit_box.set_enable(false,hc.collision_index)
					cache_off(hc.collision_index+1)
				elif hc.hit_end_frame == current_frame:
					if !check_cache(hc.collision_index-1):continue
					master.obj.hit_box.damage = hc.damage
					master.obj.hit_box.set_enable(true,hc.collision_index)
					cache_off(hc.collision_index-1)
##设置声音帧
func set_sound(anime:AnimeConfig):
	if !anime:return
	for se in anime.sound_config:
		if se.se_name == "knife-stab":
			pass
		if !anime.backward:
			if se.start_frame == current_frame or !anime.has_animation:
				play_se(se)
			elif se.end_frame > se.start_frame and se.end_frame == current_frame:
				stop_sound(se)
		else :
			if se.start_frame == current_frame:
				stop_sound(se)
			elif se.end_frame > se.start_frame and se.end_frame == current_frame or (se.end_frame == 0 and current_frame == base.sprite_frames.get_frame_count(current_animation)-1) :
				play_se(se)	
##设置fx
func set_fx(anime:AnimeConfig):
	if !anime_fx:return
	for fx in anime.fx_config:
		if !anime_fx.has_node(fx.fx_node_name):continue
		if fx.start_frame == current_frame:
			if !check_cache(fx.fx_node_name):continue
			if print_fx:Debug.dprinterr(DebugCT.dp("Anime发射FX[%s][%s]" %[current_animation,fx.fx_node_name],self))
			anime_fx.get_node(fx.fx_node_name).playAFX()
			cache[fx.fx_node_name] = false
##播放声音			
func play_se(sound_config:AnimeSoundConfig):
	if check_cache(sound_config.sound_obj_prefix+sound_config.se_name) == false:return
	EventBus._play_SE(sound_config.se_name,sound_config.se_speed,sound_config.se_pitch,sound_config.sound_obj_prefix)
	if print_sound:Debug.dprinterr(DebugCT.dp("Anime播放[%s][%s]" %[current_animation,sound_config.se_name],self))
	cache_off(sound_config.sound_obj_prefix+sound_config.se_name)
##停止声音
func stop_sound(sound_config:AnimeSoundConfig):
	EventBus._play_SE(sound_config.se_name,sound_config.se_speed,sound_config.se_pitch,sound_config.sound_obj_prefix,false)	
	if print_sound:Debug.dprinterr(DebugCT.dp("Anime停止[%s][%s]" %[current_animation,sound_config.se_name],self))
	cache_off(sound_config.sound_obj_prefix+sound_config.se_name)		
#region cache
##初始化缓存
func preset_cache(anime:AnimeConfig):
	for fx in anime.fx_config:
		cache[fx.fx_node_name] = true	
	for se in anime.sound_config:
		cache[se.sound_obj_prefix+se.se_name] = true	
	for ht in anime.hitbox_config:
		cache[ht.collision_index+1] = true	
		cache[ht.collision_index-1] = true	
	for oc in anime.anime_offset:
		cache[anime.state_name+str(oc.start_frame)] = true
		cache[anime.state_name+"cv"+str(oc.start_frame)] = true
	for ic in anime.invincible_config:
		cache["icf"+str(ic.start_frame)] = true
		cache["ic"+str(ic.start_frame)] = true
##启用缓存
func cache_on(key):
	cache[key] = true
##失效缓存
func cache_off(key):
	cache[key] = false
##检测缓存
func check_cache(key):
	if cache.has(key):return cache[key]
	cache[key] = true
	return cache[key]
#endregion
##停止动画
func stop_anime():
	if p_stop_anime:Debug.dprinterr(DebugCT.dp("Anime停止动画[%s][%s]" %[current_animation,aniplayer.get_path()],self))	
	aniplayer.stop()
	for t in offset_tweens:
		t.kill()
	offset_tweens.clear()
	offset_enable= false
	master.obj.animations.position = Vector2.ZERO
##暂停动画
func pause_anime():
	offset_enable= false
	aniplayer.pause()
	master.obj.animations.position = Vector2.ZERO
	for t in offset_tweens:
		t.kill()
##更新shader
func on_change_shader():
	for sprite in colored_node_list:
		set_shader(sprite,fx_color,mix_modulate_scale)
##设置shader
func set_shader(base,color,mix_scale):
	if is_rand_color:
		randomize()
		rand_color.shuffle()
		base.material.set_shader_parameter("to_color",rand_color[0])
	else :
		base.material.set_shader_parameter("to_color",fx_color)
	base.material.set_shader_parameter("mix_modulate_strength",mix_scale)
##物理帧处理
func _physics_process(delta: float) -> void:
	if play_lock:return
	var a = aniplayer.current_animation
	set_sound(anime)
	if !anime_dic.has(current_animation):
		return
	if last_base_frame!=base.frame:
		last_base_frame = base.frame
		process()
		update_frame()
##更新帧
func update_frame():
	if ani_frame_dic.has(current_animation):
		if ani_frame_dic[current_animation].has(last_base_frame):
			current_frame = ani_frame_dic[current_animation][last_base_frame]
	else :
		current_frame = -1
##获取两帧之间的时长		
func get_frame2frame_time(start_frame:int,end_frame:int):
	var s_time =aniplayer.get_animation(current_animation).track_get_key_time(ani_frame_dic[current_animation]["tk"],start_frame)
	var e_time = aniplayer.get_animation(current_animation).track_get_key_time(ani_frame_dic[current_animation]["tk"],end_frame)
	return e_time - s_time
func set_speed_scale(s:float=1):
	aniplayer.speed_scale = s

func _on_aniplayer_animation_finished(anim_name: StringName) -> void:
	anime_finished.emit()
