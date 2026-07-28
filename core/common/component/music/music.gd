extends Node
@onready var BGMPlayer=$BGM/backgroundMusicPlayer
@onready var SE=$SE
@onready var SE_LOOP= $SE_LOOP
@onready var BGM= $BGM
var lock=false
var index = 1
#BGM
var BGM_dic={
 "piano_happy":[preload("res://core/common/sound/BGM/daily/piano-happy.mp3")],
 "slowly":[preload("res://core/common/sound/BGM/daily/slowly-129845.mp3")],
 "by_the_side_of_a_spring":[preload( "res://core/common/sound/BGM/daily/by_the_side_of_a_spring-131449.mp3")],
}
#SE
var SE_dic={
 "light_switch_off":[preload("res://core/common/sound/SE/light_on.mp3")],
 "light_switch_on":[preload("res://core/common/sound/SE/light_off.mp3")],
 "door_close":[preload("res://core/common/sound/SE/door-opening-and-closing-18398_iCigwa2W.mp3"),-20],
 "corridor_door_close":[preload("res://core/common/sound/SE/heavy-mechancial-door-open-6934.mp3")],
 "bubble":[preload("res://core/common/sound/SE/气泡.mp3")],
 "steel_clash":[preload("res://core/common/sound/SE/steelclash.mp3"),-7],
 "be_hit_by_body":[preload("res://core/common/sound/SE/behitbybody.mp3"),-10],
 "talking":[preload("res://core/common/sound/SE/talking.mp3")],
 "slash1":[preload("res://core/common/sound/SE/slash1.mp3")],
 "slash2":[preload("res://core/common/sound/SE/slash2.mp3")],
 "slash3":[preload("res://core/common/sound/SE/slash3.mp3")],
 "slash4":[preload("res://core/common/sound/SE/slash4.mp3")],
 "slash5":[preload("res://core/common/sound/SE/slash5.mp3")],
 "slash6":[preload("res://core/common/sound/SE/slash6.mp3")],
 "slash7":[preload("res://core/common/sound/SE/slash7.mp3")],
 "punch":[preload("res://core/common/sound/SE/punch.mp3")],
 "cut-body":[preload("res://core/common/sound/SE/cut-body.mp3" )],
 "knife-stab":[preload("res://core/common/sound/SE/knife-stab.mp3")],
 "lazer":[preload("res://core/common/sound/SE/lazer.mp3")],
 "foot_step": [preload("res://core/common/sound/SE/footsteps-sneakers-on-tile-running-33003_amTjc1NI.mp3" ),-10,true],
 "bare_foot_step":[preload( "res://core/common/sound/SE/19-pasos-nina-ver2-29199_qZzBtE62.mp3" ),-5,true],
 "forest-ambient":[preload( "res://core/common/sound/SE/loop/mystic-forest-ambient.mp3" ),-5,false],
 "wind-in-trees":[preload( "res://core/common/sound/SE/loop/wind-in-trees.mp3" ),-5,false],
 "running-in-grass":[preload( "res://core/common/sound/SE/loop/running-in-grass.mp3" ),-5,true],
 "stamina_error":[preload("res://core/common/sound/SE/error-llargs.mp3")],

}
#资源，声量，是否在切换场景时停止
var SE_LOOP_dic={
 "foot_step": [preload("res://core/common/sound/SE/footsteps-sneakers-on-tile-running-33003_amTjc1NI.mp3" ),-10,true],
 "bare_foot_step":[preload( "res://core/common/sound/SE/19-pasos-nina-ver2-29199_qZzBtE62.mp3" ),-5,true],
 "forest-ambient":[preload( "res://core/common/sound/SE/loop/mystic-forest-ambient.mp3" ),-5,false],
 "wind-in-trees":[preload( "res://core/common/sound/SE/loop/wind-in-trees.mp3" ),-5,false],
 "running-in-grass":[preload( "res://core/common/sound/SE/loop/running-in-grass.mp3" ),-5,true],
}
var playable_on_transition=["door_close","bubble"]

var SE_player ={}
var SE_LOOP_player ={}
var BGM_player ={}

func _ready():
	EventBus.play_SE.connect(_on_play_SE)
	EventBus.play_SE_LOOP.connect(_on_play_SE_LOOP)
	EventBus.play_BGM.connect(_on_play_BGM)
	EventBus.change_level.connect(_preset)
	for se_player in SE.get_children():
		SE_player[se_player.get_name()]=se_player
	for se_player in SE_LOOP.get_children():
		SE_LOOP_player[se_player.get_name()]=se_player
	for se_player in BGM.get_children():
		BGM_player[se_player.get_name()]=se_player
	pass 
func _preset(room):
	lock=true
	for player in SE_LOOP_player.keys():
		if SE_LOOP_player[player].playing and SE_LOOP_dic[player][2]:
			SE_LOOP_player[player].stop()
			SE_LOOP_player["NA-"+str(player)]=SE_LOOP_player[str(player)]
			SE_LOOP_player.erase(player)
			#Debug.dprintinfo(DebugCT.dp("重置音效:[%s]" %player,self))
	lock=false
func _on_play_BGM_daily(bgm_name):
	BGMPlayer.set_stream(BGM_dic.get(bgm_name))
	BGMPlayer.play()
	
func _on_play_SE(effect_name,speed:float=1.0,effect_volume:float=0.0,owner_name:String="NA",state:bool = true):
	if lock:return
	if !SE_dic.has(effect_name):
		#Debug.dprint("未找到该SE_LOOP-%s"%effect_name)
		return
	var k_name = owner_name+"|"+effect_name
	if state:
		if SE_player.has(k_name) :
			if SE_player[k_name].playing:
				set_se_audio_player(effect_name,k_name,speed,effect_volume)	
				#Debug.dprint("播放已有[播放中]音效:%s" %k_name)
			else:
				SE_player[k_name].set_stream(SE_dic.get(effect_name)[0])
				set_se_audio_player(effect_name,k_name,speed,effect_volume)	
				SE_player[k_name].play()
				#Debug.dprint(DebugCT.dp("播放已有[停止中]音效:%s" %k_name,self))
		else:
			for se_key in SE_player.keys():
				if !SE_player[se_key].playing:
					SE_player[k_name]=SE_player[se_key]
					SE_player[k_name].set_stream(SE_dic.get(effect_name)[0])
					set_se_audio_player(effect_name,k_name,speed,effect_volume)	
					SE_player[k_name].play()
					SE_player.erase(se_key)
					#Debug.dprint("播放新音效:%s" %k_name)
					break
		#Debug.dprint("播放循环音效-%s" %effect_name)
	else:
		if SE_player.has(k_name):
			index+=1
			SE_player["NA-"+str(index)]=SE_player[k_name]
			SE_player[k_name].stop()
			SE_player.erase(k_name)
			#Debug.dprint("停止音效:%s" %k_name)
			#Debug.dprint("停止循环音效-%s" %)
		else:
			#Debug.dprint("未找到要停止的SE！-%s" %effect_name)
			pass
	#Debug.dprinterr(str(SE_player.keys()))		
			
			
			
			
			
func _on_play_SE_LOOP(effect_name,state:bool=true,speed:float=1.0,effect_volume:float=0.0):
	if lock:return
	if !SE_LOOP_dic.has(effect_name):
		#Debug.dprint("未找到该SE_LOOP-%s"%effect_name)
		return
	if state:
		if SE_LOOP_player.has(effect_name) :
			if SE_LOOP_player[effect_name].playing:
				set_se_loop_audio_player(effect_name,speed,effect_volume)	
			else:
				SE_LOOP_player[effect_name].set_stream(SE_LOOP_dic.get(effect_name)[0])
				set_se_loop_audio_player(effect_name,speed,effect_volume)	
				SE_LOOP_player[effect_name].play()
		else:
			for se_loop_key in SE_LOOP_player.keys():
				if !SE_LOOP_player[se_loop_key].playing:
					SE_LOOP_player[effect_name]=SE_LOOP_player[se_loop_key]
					SE_LOOP_player[effect_name].set_stream(SE_LOOP_dic.get(effect_name)[0])
					set_se_loop_audio_player(effect_name,speed,effect_volume)	
					SE_LOOP_player[effect_name].play()
					SE_LOOP_player.erase(se_loop_key)
					break
		#Debug.dprint("播放循环音效-%s" %effect_name)
	else:
		if SE_LOOP_player.has(effect_name):
			SE_LOOP_player[effect_name].stop()
			SE_LOOP_player["NA-"+str(effect_name)]=SE_LOOP_player[effect_name]
			SE_LOOP_player.erase(effect_name)
			#Debug.dprint("停止循环音效-%s" %)
		else:
			#Debug.dprint("未找到要停止的SE_LOOP！-%s" %effect_name)
			pass
func _on_play_BGM(effect_name,state:bool=true,speed:float=1.0,effect_volume:float=0.0):
	if !BGM_dic.has(effect_name):
		#Debug.dprint("未找到该BGM-%s" %effect_name)
		return
	if state:
		for BGM_key in BGM_player.keys():
			if !BGM_player[BGM_key].is_playing():
				BGM_player[effect_name]=BGM_player[BGM_key]
				BGM_player[effect_name].set_stream(BGM_dic.get(effect_name)[0])
				BGM_player[effect_name].set_pitch_scale(speed)
				BGM_player[effect_name].set_volume_db(effect_volume)	
				if BGM_dic.get(effect_name).size()>1&&effect_volume==0:
					BGM_player[effect_name].set_volume_db(BGM_dic.get(effect_name)[1])
				BGM_player[effect_name].play()
				#Debug.dprint("播放BGM-%s" %effect_name)
				SE_LOOP_player.erase(BGM_key)
				break

	else:
		if BGM_player.has(effect_name):
			BGM_player[effect_name].stop()
			BGM_player["NA"]=BGM_player[effect_name]
			BGM_player.erase(effect_name)
			#Debug.dprint("停止BGM-%s" %effect_name)
		else:
			#Debug.dprint("未找到要停止的BGM！-%s" %effect_name)
			pass

func set_se_loop_audio_player(effect_name,speed:float=1.0,effect_volume:float=0.0):
	SE_LOOP_player[effect_name].set_pitch_scale(speed)
	SE_LOOP_player[effect_name].set_volume_db(effect_volume)
	if SE_LOOP_dic.get(effect_name).size()>1 and effect_volume==0:
		SE_LOOP_player[effect_name].set_volume_db(SE_LOOP_dic.get(effect_name)[1])	
	pass
func set_se_audio_player(effect_name,k_name,speed:float=1.0,effect_volume:float=0.0):
	SE_player[k_name].set_pitch_scale(speed)
	SE_player[k_name].set_volume_db(effect_volume)
	if SE_dic.get(effect_name).size()>1 and effect_volume==0:
		SE_player[k_name].set_volume_db(SE_dic.get(effect_name)[1])	
	SE_player[k_name].play(0)
