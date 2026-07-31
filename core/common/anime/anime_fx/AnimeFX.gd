@icon("res://core/common/resource/icon/anime_icon.svg")
extends Node2D
class_name AnimeFX
@onready var master: Node = %Master
@export_group("Anime基础设置")
@export var base: AnimatedSprite2D
@export var sprite_list: Array[AnimatedSprite2D]
@export var current_animation:String
@export var playing:bool = true:
	set(f):
		playing = f
		if !base:return
		if f:
			play_anime(current_animation)
		else :
			pause_anime()
@export var current_frame:int = 0
@export_group("Anime详细设置")
@export var animes:Array[AnimeConfig]
@export var current_animation_length:float
@export var is_rand_color:bool =false
@export var fx_color:Color ="ffffff":
	set(c):
		fx_color = c
		on_change_shader()
@export_range(-2.0, 3.0) var mix_modulate_scale:float=2:
	set(f):
		mix_modulate_scale = f
		on_change_shader()
@export_group("Debug")
@export var print_play_anime:bool = false
@export var print_sound:bool = false
@export var print_fx:bool = false
@export var print_hitbox:bool = false
var rand_color=[Color.AQUA,Color.RED,Color.YELLOW,Color.CHOCOLATE,Color.BLACK,Color.WHITE]
var anime_dic:Dictionary
var cache:Dictionary
var base_animation_name_array
@onready var animations: Animations = $".."
var tween
var fx_tween
var offset_enable:bool = false

func import(animes1):
	if animes1:
		for anime_config in animes1:
			anime_dic[anime_config.state_name] = anime_config
	base_animation_name_array = base.sprite_frames.get_animation_names()
	
func play_anime(anime_name:String):
	if anime_name == "behithard":
		pass
	if print_play_anime:Debug.dprintwarn(DebugCT.dp("[%s][Anime]播放:%s" %[master.obj.name.get_path(),anime_name],self))
	var anime:AnimeConfig = anime_dic[anime_name]
	if tween:tween.kill()
	preset_cache(anime)
	offset_enable = true
	current_animation = anime.animation_name
	on_change_shader()
	if base.sprite_frames.has_animation(current_animation):
		current_animation_length = base.sprite_frames.get_frame_count(current_animation) / base.sprite_frames.get_animation_speed(current_animation) / anime.speed_scale
		base.sprite_frames.set_animation_loop(current_animation,anime.loop)
		base.speed_scale = anime.speed_scale
		for sprite in sprite_list:
			if sprite.sprite_frames.has_animation(current_animation):
				sprite.sprite_frames.set_animation_loop(current_animation,anime.loop)
				sprite.speed_scale = anime.speed_scale
		if !anime.backward:
			base.play(current_animation)
			for sprite in sprite_list:
				if sprite.sprite_frames.has_animation(current_animation):
					sprite.play(current_animation)
		else :
			base.play_backwards(current_animation)
			for sprite in sprite_list:
				if sprite.sprite_frames.has_animation(current_animation):
					sprite.play_backwards(current_animation)
					
func _physics_process(delta: float) -> void:
	if !anime_dic.has(current_animation):return
	var anime:AnimeConfig = anime_dic[current_animation]
	current_frame = base.get_frame()
	set_offset(anime)
	if master.obj.hit_box:
		set_hitbox(anime)
		set_fx_hitbox(anime)	
	#if master.obj.hurt_box:
		#set_hurtbox(anime)	
	set_sound(anime)
	#set_fx(anime)
	#set_bati(anime)

func set_fx_hitbox(anime:AnimeConfig):
	for fhc in anime.fx_hitbox_config:
		if current_frame == fhc.start_frame:
			if !check_cache(anime.state_name+str(fhc.start_frame)):break
			cache_off(anime.state_name+str(fhc.start_frame))
			fx_tween = base.create_tween()
			pass

func set_offset(anime:AnimeConfig):
	for offset_config:AnimeOffsetConfig in anime.anime_offset:
		if current_frame == offset_config.start_frame:
			if !check_cache(anime.state_name+str(offset_config.start_frame)):
				break
			#Debug.dprintwarn(DebugCT.dp("[Anime]开始offset",self))
			cache_off(anime.state_name+str(offset_config.start_frame))
			tween = animations.create_tween()
			var time:float
			for i in offset_config.end_frame - offset_config.start_frame:
				time+=base.sprite_frames.get_frame_duration(current_animation,offset_config.start_frame+i)/ (13 * abs(base.get_playing_speed()))
			tween.tween_property(animations,"position",-master.obj.face_left_normalized*offset_config.target_vec2,time)
			tween.parallel().tween_property(master.obj,"position",master.obj.position+master.obj.face_left_normalized*offset_config.target_vec2,time)		
			await tween.finished
			tween.kill()
			cache_on(anime.state_name+str(offset_config.start_frame))
				
func set_bati(anime:AnimeConfig):
	for bati_config:AnimeBatiConfig in anime.bati_config:
		if current_frame == bati_config.bati_start_frame:
			bati_config.bating = true
		elif current_frame == bati_config.bati_end_frame:
			bati_config.bating = false
			
func set_hitbox(anime):
	if master.obj.hit_box:
		for hc:AnimeHitBoxConfig in anime.hitbox_config:
			if !anime.backward:
				if hc.hit_start_frame == current_frame:
					if !check_cache(hc.collision_index+1):continue
					if print_hitbox:Debug.dprinterr(DebugCT.dp("[%s]Anime设置hitbox[%s][%s]" %[master.obj.name.get_path(),current_animation,hc.collision_index],self))
					master.obj.hit_box.damage = hc.damage
					master.obj.hit_box.set_enable(true,hc.collision_index)
					cache_off(hc.collision_index+1)
				elif hc.hit_end_frame == current_frame:
					if !check_cache(hc.collision_index-1):continue
					if print_hitbox:Debug.dprinterr(DebugCT.dp("[%s]Anime取消hitbox[%s][%s]" %[master.obj.name.get_path(),current_animation,hc.collision_index],self))
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
func dis_all_hitbox(hitbox_config:AnimeHitBoxConfig):
	if print_hitbox:Debug.dprinterr(DebugCT.dp("[%s]Anime禁用hitbox[%s][%s]" %[master.obj.name.get_path(),current_animation,hitbox_config.collision_index],self))
	master.obj.hit_box.set_enable(false,hitbox_config.collision_index)
func set_sound(anime:AnimeConfig):
	for se in anime.sound_config:
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
func set_fx(anime:AnimeConfig):
	if !master.obj.launche_fx:return
	for fx in anime.fx_config:
		if !fx.launch_obj_name:continue
		if fx.start_frame == current_frame:
			if check_cache(fx.launch_obj_name) == false:continue
			if print_fx:Debug.dprinterr(DebugCT.dp("[%s]Anime发射FX[%s][%s]" %[master.obj.name.get_path(),current_animation,fx.launch_obj_name],self))
			master.obj.launche_fx.launch_obj(fx.launch_obj_name)
			cache[fx.launch_obj_name] = false
func play_se(sound_config:AnimeSoundConfig):
	if check_cache(sound_config.sound_obj_prefix+sound_config.se_name) == false:return
	EventBus._play_SE(sound_config.se_name,sound_config.se_speed,sound_config.se_pitch,sound_config.sound_obj_prefix)
	if print_sound:Debug.dprinterr(DebugCT.dp("[%s]Anime播放[%s][%s]" %[master.obj.name.get_path(),current_animation,sound_config.se_name],self))
	cache_off(sound_config.sound_obj_prefix+sound_config.se_name)
func stop_sound(sound_config:AnimeSoundConfig):
	EventBus._play_SE(sound_config.se_name,sound_config.se_speed,sound_config.se_pitch,sound_config.sound_obj_prefix,false)	
	if print_sound:Debug.dprinterr(DebugCT.dp("[%s]Anime停止[%s][%s]" %[master.obj.name.get_path(),current_animation,sound_config.se_name],self))
	cache_off(sound_config.sound_obj_prefix+sound_config.se_name)		
#region cache
func preset_cache(anime:AnimeConfig):
	for fx in anime.fx_config:
		cache[fx.launch_obj_name] = true	
	for se in anime.sound_config:
		cache[se.sound_obj_prefix+se.se_name] = true	
	for ht in anime.hitbox_config:
		cache[ht.collision_index+1] = true	
		cache[ht.collision_index-1] = true	
	for oc in anime.anime_offset:
		cache[anime.state_name+str(oc.start_frame)] = true
	for ic in anime.invincible_config:
		cache["icf"+str(ic.start_frame)] = true
		cache["ic"+str(ic.start_frame)] = true
		
func cache_on(key):
	cache[key] = true
func cache_off(key):
	cache[key] = false
func check_cache(key):
	if cache.has(key):return cache[key]
	cache[key] = true
	return cache[key]
#endregion
func stop_anime():
	offset_enable= false
	base.stop()
	for sprite in sprite_list:
		sprite.stop()
	if tween:tween.kill()
	master.obj.animations.position = Vector2.ZERO
func pause_anime():
	offset_enable= false
	base.pause()
	for sprite in sprite_list:
		sprite.pause()
	master.obj.animations.position = Vector2.ZERO
	if tween:tween.kill()
func on_change_shader():
	for sprite in sprite_list:
		set_shader(sprite,fx_color,mix_modulate_scale)
func set_shader(base,color,mix_scale):
	if is_rand_color:
		randomize()
		rand_color.shuffle()
		base.material.set_shader_parameter("color",rand_color[0])
	else :
		base.material.set_shader_parameter("color",fx_color)
	base.material.set_shader_parameter("mix_modulate_strength",mix_scale)

func set_speed_scale(speed_scale):
	base.speed_scale = speed_scale
	for sprite in sprite_list:
		sprite.speed_scale = speed_scale
