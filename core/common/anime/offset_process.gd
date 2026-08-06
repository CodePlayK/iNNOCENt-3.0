extends Node2D
class_name OffsetProcess
@onready var anime_controller: Anime = $".."
@export var nodes_following_anime:Array[Node2D]
@export var anime_following_node:Array[Node2D]
var enable:bool = false:
	set(e):
		enable = e
		set_physics_process(e)


func _physics_process(delta: float) -> void:
	for offset_config:AnimeOffsetConfig in anime_controller.anime.anime_offset:
			if anime_controller.current_frame == offset_config.start_frame and anime_controller.aniplayer.current_animation == anime_controller.anime.animation_name :
				if anime_controller.check_cache(anime_controller.anime.state_name+"offset"+str(offset_config.start_frame)):
					continue
				if !offset_config.anime_following_obj:
					Debug.dprintwarn(DebugCT.dp("进入帧:[%s] - cache状态:[%s:%s]" %[anime_controller.current_frame,anime_controller.anime.state_name+"offset"+str(offset_config.start_frame),anime_controller.cache[anime_controller.anime.state_name+"offset"+str(offset_config.start_frame)]],self))
					anime_controller.cache_on(anime_controller.anime.state_name+"offset"+str(offset_config.start_frame))
					var time:float
					time = anime_controller.get_frame2frame_time(offset_config.start_frame,offset_config.end_frame)/anime_controller.aniplayer.speed_scale
					var tween = anime_controller.create_tween()
					anime_controller.offset_tweens.append(tween)
					for n in nodes_following_anime:
						#tween.parallel().tween_property(anime_controller.animations,"position",anime_controller.animations.position-Vector2(anime_controller.master.obj.face_left_normalized*offset_config.target_vec2.x,offset_config.target_vec2.y),time)
						tween.parallel().tween_property(n,"position",Vector2(anime_controller.master.obj.face_left_normalized*offset_config.target_vec2.x,offset_config.target_vec2.y),time)		
					await tween.finished
				else :
					Debug.dprintwarn(DebugCT.dp("进入帧:[%s] - cache状态:[%s:%s]" %[anime_controller.current_frame,anime_controller.anime.state_name+"offset"+str(offset_config.start_frame),anime_controller.cache[anime_controller.anime.state_name+"offset"+str(offset_config.start_frame)]],self))
					anime_controller.cache_on(anime_controller.anime.state_name+"offset"+str(offset_config.start_frame))
					var time:float
					time = anime_controller.get_frame2frame_time(offset_config.start_frame,offset_config.end_frame)/anime_controller.aniplayer.speed_scale
					var tween = anime_controller.create_tween()
					anime_controller.offset_tweens.append(tween)
					tween.parallel().tween_property(anime_controller.animations,"position",anime_controller.animations.position - Vector2(anime_controller.master.obj.face_left_normalized*offset_config.target_vec2.x,offset_config.target_vec2.y),time)
					tween.parallel().tween_property(anime_controller.master.obj,"position",anime_controller.master.obj.position + Vector2(anime_controller.master.obj.face_left_normalized*offset_config.target_vec2.x,offset_config.target_vec2.y),time)		
					await tween.finished
										
