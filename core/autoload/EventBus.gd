extends Node
## 全局事件总线
##
## 解耦各系统通信。业务侧优先调用以下划线开头的包装方法（如 [method _save_game]），
## 内部再 [code]emit[/code] 对应信号；监听方直接 [code]connect[/code] 信号。


#region Game / 存档
## 请求执行一次完整存档（通知所有 Saver / DataCollector 写入数据）
signal save_game
## 通知所有 Saver 从当前存档载入数据[br]
## 监听方包括：[BaseSaveFileSaver]、[BaseSaver] 等[br]
## TODO: 给玩家单独的 Saver
signal load_game
## 仅通知 [BaseSaveFileSaver] 载入存档文件本身（不触发完整关卡状态刷新）
signal load_save_file
signal load_level
## 删除指定存档（参数：save_id）
signal delete_save
## 当前使用的存档 ID 发生变化（菜单选中 / 新建 / 删除后同步 UI）
signal save_file_id_update
#endregion


#region VFX / 视觉特效
## 从顶部掉落物体（参数：obj 资源名, obj_count 数量）
signal fallen_from_top
## 屏幕震动（过场用，与 [signal camera_shake] 区分）
signal screen_shake

#endregion


#region Cutscene / 过场
## 过场摄像机切换到指定 Marker 集合（参数：dic_markers）
signal cutscene_camera
## 过场摄像机复位到玩家/默认状态
signal cutscene_camera_reset
## 启用/恢复玩家摄像机控制
signal enable_player_camera
## 过场动画播放完成
signal cutscene_finished
## 过场动画正在播放中（可用于锁定输入等）
signal cutscene_is_playing
## 通过 AnimationPlayer 播放指定过场动画（参数：animation_name）
signal play_cutscene_aniplayer
## 播放画面后处理/屏幕特效（参数：e_name 效果名, args 额外参数）
signal play_screen_effect
#endregion


#region Camera / 摄像机
## 摄像机震动（参数：strength 强度, SHAKE_DECAY 衰减）
signal camera_shake
#endregion


#region Level / 关卡
## 请求切换关卡（参数：level_id）
signal change_level
## 关卡已切换完成（参数：fl 原关卡, tl 目标关卡）
signal level_changed
## 关卡节点树退出（卸载前清理）
signal level_tree_exited
## 显示关卡过渡效果（参数：transition_type）
signal transition_show
#endregion


#region Dialogue / 对白
## 对白历史数据载入完毕
signal txt_his_load_fin
#endregion


#region Player / 玩家
## 玩家生命值需要刷新 UI / 逻辑
signal player_health_update
## 玩家属体力需要刷新 UI / 逻辑
signal player_stamina_update
## 请求获取玩家当前位置（监听方回写或响应）
signal get_player_position
## 强制改变玩家位置（参数：通常为 Vector2）
signal change_player_position
## 改变玩家可见性（参数：visible 标志）
signal change_player_visible
## 玩家朝向改为向左（或设置朝向）
signal player_face_left
## 锁定/解锁玩家操作
signal player_control_lock
## 玩家进入/退出战斗状态（参数：flag）
signal player_on_fighting_changed
## 玩家受到伤害
signal player_health_damaged
## 玩家获得治疗
signal player_health_healed
## 玩家属体力消耗
signal player_stamina_damaged
## 玩家属体力恢复
signal player_stamina_recovered
## 玩家朝向发生改变
signal player_face_changed
## 玩家奔跑状态发生改变
signal player_running_changed
signal player_into_lock_state
signal player_load_save_file_pos
signal start_qte
#endregion


#region UI
## 创建角色头像/状态 Box（参数：character_box_config）
signal create_character_box
## 移除指定角色 Box（参数：character_box_config, exist_level 所属关卡）
signal remove_character_box
## 移除全部角色 Box
signal remove_all_character_box
signal create_all_character_box
## 测试层显示/隐藏（调试用，参数：flag）
signal test_layer_visiable
##添加过场到debug层
signal add_debug(d:Node,ysize:Vector2)
## 请求开始心跳复苏 QTE（参数：params 配置字典，可空）
signal start_heartbeat_qte(params: Dictionary)
## 心跳复苏 QTE 结束（参数：result 含 success / hit_count / success_score 等）
signal heartbeat_qte_finished(result: Dictionary)
#endregion
func _add_debug(d:Node,size:Vector2,max_y:float):
	add_debug.emit(d,size,max_y)

#region Sound / 音频
## 播放循环音效（参数：SE_LOOP_name, state 开关, speed 速率, effect_volume 音量偏移）
signal play_SE_LOOP
## 播放一次性音效（参数：SE_name, speed, effect_volume, owner_name, state）
signal play_SE
## 播放/切换 BGM（参数：BGM_name, state, speed, effect_volume）
signal play_BGM
#endregion


#region Obj / NPC / 物体
## 设置指定物体朝向是否向左（参数：name, left_flag）
signal obj_set_face_left
## NPC 受到重击（参数：obj）
signal npc_behit_hard
## 让指定节点在时间内移动到目标位置（参数：name, pos, time）
signal move_2_vec2
## NPC 跟随/取消跟随玩家（参数：npc_name, flag）
signal npc_following_player
#endregion


#region Emit Wrappers — Game / 存档
## 发射 [signal save_game]
func _save_game() -> void:
	save_game.emit()


## 发射 [signal load_game]
func _load_game() -> void:
	load_game.emit()


## 发射 [signal load_save_file]
func _load_save_file(update_current_save_id:bool) -> void:
	load_save_file.emit(update_current_save_id)


## 发射 [signal delete_save]
## [param save_id] 要删除的存档 ID
func _delete_save(save_id: int) -> void:
	delete_save.emit(save_id)


## 发射 [signal save_file_id_update]
func _save_file_id_update() -> void:
	save_file_id_update.emit()
#endregion


#region Emit Wrappers — VFX
## 发射 [signal fallen_from_top]
## [param obj] 掉落物标识/资源名
## [param obj_count] 数量
func _fallen_from_top(obj: String, obj_count: int) -> void:
	fallen_from_top.emit(obj, obj_count)


## 发射 [signal screen_shake]
func _screen_shake() -> void:
	screen_shake.emit()
#endregion


#region Emit Wrappers — Cutscene
## 发射 [signal cutscene_camera]
## [param dic_markers] Marker 名称到节点/位置的映射
func _cutscene_camera(dic_markers: Dictionary) -> void:
	cutscene_camera.emit(dic_markers)


## 发射 [signal cutscene_camera_reset]
func _cutscene_camera_reset() -> void:
	cutscene_camera_reset.emit()


## 发射 [signal enable_player_camera]
func _enable_player_camera() -> void:
	enable_player_camera.emit()


## 发射 [signal cutscene_finished]
func _cutscene_finished() -> void:
	cutscene_finished.emit()


## 发射 [signal cutscene_is_playing]
func _cutscene_is_playing() -> void:
	cutscene_is_playing.emit()


## 发射 [signal play_cutscene_aniplayer]
## [param animation_name] 动画名
func _play_cutscene_aniplayer(animation_name: String) -> void:
	play_cutscene_aniplayer.emit(animation_name)


## 发射 [signal play_screen_effect]
## [param e_name] 效果名称
## [param args] 额外参数列表
func _play_screen_effect(e_name: String, args: Array = []) -> void:
	play_screen_effect.emit(e_name, args)
#endregion


#region Emit Wrappers — Camera
## 发射 [signal camera_shake]
## [param strength] 震动强度
## [param SHAKE_DECAY] 衰减速度
func _camera_shake(strength: float, SHAKE_DECAY: float) -> void:
	camera_shake.emit(strength, SHAKE_DECAY)
#endregion


#region Emit Wrappers — Level
## 发射 [signal change_level]
## [param level_id] 目标关卡枚举
func _change_level(level_id: LevelState.LEVELS,source:Node) -> void:
	Debug.dprintwarn(DebugCT.dp("信号: 开始切换Level - [%s]" %[level_id],source))
	change_level.emit(level_id)


## 发射 [signal level_changed]
## [param fl] 切换前关卡
## [param tl] 切换后关卡
func _level_changed(fl: LevelState.LEVELS, tl: LevelState.LEVELS,source:Node2D) -> void:
	Debug.dprintwarn(DebugCT.dp("信号: Level切换完成 [%s] - [%s]" %[fl,tl],source))
	level_changed.emit(fl, tl)


## 发射 [signal level_tree_exited]
func _level_tree_exited() -> void:
	level_tree_exited.emit()


## 发射 [signal transition_show]
## [param transition_type] 过渡类型
func _transition_show(transition_type) -> void:
	transition_show.emit(transition_type)
#endregion


#region Emit Wrappers — Dialogue
## 发射 [signal txt_his_load_fin]
func _txt_his_load_fin() -> void:
	txt_his_load_fin.emit()
#endregion


#region Emit Wrappers — Player
## 发射 [signal player_health_update]
func _player_health_update() -> void:
	player_health_update.emit()


## 发射 [signal player_stamina_update]
func _player_stamina_update() -> void:
	player_stamina_update.emit()


## 发射 [signal get_player_position]
func _get_player_position() -> void:
	get_player_position.emit()


## 发射 [signal change_player_position]
func _change_player_position(pos: Vector2) -> void:
	change_player_position.emit(pos)


## 发射 [signal change_player_visible]
## [param visible] 是否可见
func _change_player_visible(visible: bool) -> void:
	change_player_visible.emit(visible)


## 发射 [signal player_face_left]
## [param left] 是否朝左
func _player_face_left(left: bool = true) -> void:
	player_face_left.emit(left)


## 发射 [signal player_control_lock]
## [param locked] 是否锁定操作
func _player_control_lock(locked: bool = true) -> void:
	player_control_lock.emit(locked)


## 发射 [signal player_on_fighting_changed]
## [param flag] 是否处于战斗
func _player_on_fighting_changed(flag: bool = false) -> void:
	player_on_fighting_changed.emit(flag)


## 发射 [signal player_health_damaged]
func _player_health_damaged() -> void:
	player_health_damaged.emit()


## 发射 [signal player_health_healed]
func _player_health_healed() -> void:
	player_health_healed.emit()


## 发射 [signal player_stamina_damaged]
func _player_stamina_damaged() -> void:
	player_stamina_damaged.emit()


## 发射 [signal player_stamina_recovered]
func _player_stamina_recovered() -> void:
	player_stamina_recovered.emit()


## 发射 [signal player_face_changed]
func _player_face_changed() -> void:
	player_face_changed.emit()


## 发射 [signal player_running_changed]
func _player_running_changed() -> void:
	player_running_changed.emit()
#endregion


#region Emit Wrappers — UI
## 发射 [signal create_character_box]
## [param character_box_config] 角色 Box 配置资源
func _create_character_box(character_box_config: CharacterBoxConfig) -> void:
	create_character_box.emit(character_box_config)


## 发射 [signal remove_character_box]
## [param character_box_config] 要移除的配置
## [param exist_level] 该 Box 所属关卡
func _remove_character_box(character_box_config: CharacterBoxConfig, exist_level: LevelState.LEVELS) -> void:
	remove_character_box.emit(character_box_config, exist_level)


## 发射 [signal remove_all_character_box]
func _remove_all_character_box(source:Node) -> void:
	Debug.dprintinfo(DebugCT.dp("信号: 移除所有角色box",source))
	remove_all_character_box.emit()


## 发射 [signal test_layer_visiable]
## [param flag] 是否显示测试层
func _test_layer_visiable(flag: bool) -> void:
	test_layer_visiable.emit(flag)


## 发射 [signal start_heartbeat_qte]
## [param params] QTE 配置覆盖（duration / heartbeat_count / required_hits / required_success 等）
func _start_heartbeat_qte(params: Dictionary = {}) -> void:
	start_heartbeat_qte.emit(params)
#endregion


#region Emit Wrappers — Sound
## 发射 [signal play_SE_LOOP]
## [param SE_LOOP_name] 循环音效名
## [param state] 播放/停止
## [param speed] 播放速率
## [param effect_volume] 音量偏移（dB）
func _play_SE_LOOP(SE_LOOP_name, state: bool = true, speed: float = 1.0, effect_volume: float = 0.0) -> void:
	play_SE_LOOP.emit(SE_LOOP_name, state, speed, effect_volume)


## 发射 [signal play_SE]
## [param SE_name] 音效名
## [param speed] 播放速率
## [param effect_volume] 音量偏移
## [param owner_name] 来源标识（用于去重/停止）
## [param state] 播放/停止
func _play_SE(SE_name, speed: float = 1.0, effect_volume: float = 0.0, owner_name: String = "NA", state: bool = true) -> void:
	play_SE.emit(SE_name, speed, effect_volume, owner_name, state)


## 发射 [signal play_BGM]
## [param BGM_name] BGM 名
## [param state] 播放/停止
## [param speed] 播放速率
## [param effect_volume] 音量偏移
func _play_BGM(BGM_name, state: bool = true, speed: float = 1.0, effect_volume: float = 0.0) -> void:
	play_BGM.emit(BGM_name, state, speed, effect_volume)
#endregion


#region Emit Wrappers — Obj / NPC
## 发射 [signal obj_set_face_left]
## [param name] 物体/节点名
## [param left_flag] 是否朝左
func _obj_set_face_left(name, left_flag: bool) -> void:
	obj_set_face_left.emit(name, left_flag)


## 发射 [signal npc_behit_hard]
## [param obj] 受击对象
func _npc_behit_hard(obj) -> void:
	npc_behit_hard.emit(obj)


## 发射 [signal move_2_vec2]
## [param name] 目标节点名
## [param pos] 目标世界/本地坐标
## [param time] 移动耗时（秒）
func _move_2_vec2(name: String, pos: Vector2, time: float = 1.0) -> void:
	move_2_vec2.emit(name, pos, time)


## 发射 [signal npc_following_player]
## [param npc_name] NPC 名
## [param flag] 是否跟随
func _npc_following_player(npc_name: String, flag: bool) -> void:
	npc_following_player.emit(npc_name, flag)
#endregion

func _player_into_lock_state():
	player_into_lock_state.emit()
	
func _player_load_save_file_pos(li:LevelState.LEVELS,source:Node):
	player_load_save_file_pos.emit(li)
	Debug.dprintwarn(DebugCT.dp("信号: 收到关卡载入通知 -> level_%s" %li,source))

func _create_all_character_box():
	create_all_character_box.emit()
