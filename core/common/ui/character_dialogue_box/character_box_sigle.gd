extends VBoxContainer
class_name CharacterBox
@onready var img_box_top_marg: MarginContainer = %ImgBoxTopMarg
@onready var img_box: MarginContainer = %ImgBox
@onready var timer: Timer = $Timer
@onready var texture_rect: TextureRect = $ImgBox/HBoxContainer/VBoxContainer/MarginContainer/TextureRect
@onready var test: Label = %TEST
@onready var delay_timer: Timer = $delay_timer
@onready var panel: PanelContainer = $ImgBox/HBoxContainer/VBoxContainer/MarginContainer/Panel

@export var character_box_config:CharacterBoxConfig:
	set(cbc):
		character_box_config=cbc
@export var is_player:bool = false
@export var health_config:HealthConfig

var box_selected:bool = false
var on_changing:bool = false
var on_showing:bool = false
@export var is_prototype:bool = true
@export var delay_time:Vector2 = Vector2(0.5,1)

## 目标选中状态（true=选中，false=取消）
var _target_selected: bool = false
## 当前正在播放的 tween（用于打断）
var _current_tween: Tween = null
var _current_avatar:String
var enable:bool = false
func _ready() -> void:
	hide()
	img_box.size_flags_stretch_ratio=0
	size_flags_stretch_ratio=0
	img_box_top_marg.size_flags_stretch_ratio=20
	timer.wait_time = character_box_config.drag_time
	modulate = character_box_config.unselect_modulate
	timer.timeout.connect(_on_timer_timeout)
	EventBus.player_health_damaged.connect(on_player_health_damaged)
	EventBus.player_health_healed.connect(on_player_health_healed)
	EventBus.remove_character_box.connect(on_remove_character_box)
	EventBus.remove_all_character_box.connect(on_remove_all_character_box)
	Dialogue.end_dialogue.connect(on_end_dialogue)
	Dialogue.talk_start.connect(on_talk_start)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	if character_box_config.is_player:
		UiState.player_character_box = self


## 根据关键字从指定文件夹加载对应名称的 png 并更换头像
## keyword: 文件名（不含扩展名），例如 "idle"、"sad",为空时则不替换保持上一个表情
## folder: 可选，覆盖默认 avatar_folder；为空则使用 avatar_folder
## 返回是否加载成功
func set_avatar_by_keyword(keyword: String, folder: String = "") -> bool:
	if keyword.is_empty():
		Debug.dprintwarn(DebugCT.dp("set_avatar_by_keyword: keyword 为空", self))
		return false
	if _current_avatar == keyword:
		return false
	_current_avatar = keyword
	var base_path := folder if not folder.is_empty() else character_box_config.avatar_folder
	# 统一处理路径末尾斜杠
	if not base_path.ends_with("/") and not base_path.ends_with("\\"):
		base_path += "/"

	var full_path := base_path + keyword + ".png"

	if not ResourceLoader.exists(full_path):
		Debug.dprintwarn(DebugCT.dp("头像文件不存在: %s" % full_path, self))
		return false

	var tex: Texture2D = load(full_path) as Texture2D
	if not tex:
		Debug.dprintwarn(DebugCT.dp("无法加载头像: %s" % full_path, self))
		return false

	texture_rect.texture = tex
	# 同步更新 config，方便后续逻辑使用
	if character_box_config:
		character_box_config.image = tex

	return true


func set_panel_out_line(color:Color):
	panel.get_theme_stylebox("panel").border_color = color	

func on_level_changed(fl,tl):
	if is_prototype or !enable:return
	on_remove_character_box(character_box_config,character_box_config.level_id)

#卸载角色box事件
func on_remove_character_box(cbc:CharacterBoxConfig,el:LevelState.LEVELS):
	if is_prototype or !enable:return
	if cbc.character_box_id!=character_box_config.character_box_id or el!=character_box_config.level_id:return
	UiState.set_character_box_showing(character_box_config,false,self)
	on_remove_all_character_box()
	
#卸载角色box事件
func on_remove_all_character_box():
	#if character_box_config.is_player:return
	delay_timer.stop()
	anime_dead()
	
#出生动画
func anime_born():
	if is_prototype or !enable:return
	delay_timer.start(randf_range(delay_time.x,delay_time.y))
	return

func anime_dead():
	if is_prototype or !enable:return
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_IN)
	#twn.tween_property(self,"size_flags_stretch_ratio",0,0.5)
	twn.parallel().tween_property(img_box,"size_flags_stretch_ratio",0,0.5)
	twn.parallel().tween_property(img_box_top_marg,"size_flags_stretch_ratio",20,0.5)
	await twn.finished
	twn.kill()
	queue_free()	
	return
#台词事件
func on_talk_start(character:String,dialogue_config:DialogueConfig,dialogue_line:DialogueLine):
	if is_prototype or !enable:return
	#Debug.dprintwarn(DebugCT.dp("台词角色[%s]，characterBox当前角色[%s]" %[character,str(character_box_config.character_names)],self))
	if !character_box_config.character_names.has(character):return
	Debug.dprintwarn(DebugCT.dp("台词角色[%s]，当前表情[%s]" %[character,str(dialogue_line.expression)],self))
	if dialogue_line.expression=="idle" and _current_avatar=="happy":
		pass
	set_avatar_by_keyword(dialogue_line.expression,character_box_config.avatar_folder)
	box_show()

func on_end_dialogue():
	box_deselect()

func on_character_box_config_upate():
	return

func box_show():
	if is_prototype:return
	_target_selected = true
	_start_or_update_select_anim()

func _on_mouse_entered() -> void:
	box_select()

func _on_mouse_exited() -> void:
	box_deselect()
	
func box_select():
	_target_selected = true
	_start_or_update_select_anim()

func box_deselect():
	_target_selected = false
	_start_or_update_select_anim()
	##在收起时重置为默认表情
	set_avatar_by_keyword(character_box_config.current_default_expression,character_box_config.avatar_folder)

## 统一入口：根据最新目标启动/打断动画
func _start_or_update_select_anim() -> void:
	# 已经是目标状态且没在动画 → 直接返回
	if box_selected == _target_selected and not on_changing:
		return

	# 打断旧动画
	if _current_tween and _current_tween.is_valid():
		_current_tween.kill()
		_current_tween = null

	on_changing = true
	timer.stop()   # 选中计时器也要停

	var twn := create_tween()
	_current_tween = twn
	twn.set_trans(Tween.TRANS_CUBIC)
	twn.set_ease(Tween.EASE_OUT)

	if _target_selected:
		# 选中动画
		twn.tween_property(img_box_top_marg, "size_flags_stretch_ratio",
			character_box_config.img_box_top_marg_show,
			character_box_config.animation_time)
		twn.parallel().tween_property(self, "size_flags_stretch_ratio",
			character_box_config.wide_marg_show,
			character_box_config.animation_time)
		twn.parallel().tween_property(self, "modulate",
			character_box_config.selected_modulate,
			character_box_config.animation_time)
	else:
		# 取消选中动画
		twn.tween_property(img_box_top_marg, "size_flags_stretch_ratio",
			character_box_config.img_box_top_marg_hide,
			character_box_config.animation_time)
		twn.parallel().tween_property(self, "modulate",
			character_box_config.unselect_modulate,
			character_box_config.animation_time)
		twn.parallel().tween_property(self, "size_flags_stretch_ratio",
			character_box_config.wide_marg_hide,
			character_box_config.animation_time)

	twn.finished.connect(_on_select_anim_finished.bind(_target_selected), CONNECT_ONE_SHOT)

func _on_select_anim_finished(final_selected: bool) -> void:
	_current_tween = null
	box_selected = final_selected
	on_changing = false
	on_showing = final_selected   # 与原来逻辑保持一致

	# 如果动画过程中目标又变了，立刻再播一次
	if box_selected != _target_selected:
		_start_or_update_select_anim()
		return

	# 选中完成且鼠标还在 → 启动原有的拖拽检测计时器
	if box_selected and check_has_mouse():
		timer.start()

func _on_timer_timeout() -> void:
	#Debug.dprintwarn(DebugCT.dp("检查flag[%s][%s][%s]" %[box_selected,on_showing,on_changing],self))
	if !box_selected or on_showing or on_changing:
		return
	if !check_has_mouse():
		_on_mouse_exited()

		
func check_has_mouse():
	#Debug.dprintwarn(DebugCT.dp("检查数遍是否悬空[%s][%s]" %[Rect2(position,size),get_local_mouse_position()],self))
	return get_global_rect().has_point(get_global_mouse_position())


func _on_img_box_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("uiselect"):
		if !UiState.state_box.showing:
			UiState.state_box.show_box()
		else :
			UiState.state_box.hide_box()

func on_player_health_damaged():
	if is_prototype or !enable:return
	
func on_player_health_healed():
	if is_prototype or !enable:return


func _on_gui_input(event: InputEvent) -> void:
	if is_prototype or !enable:return
	if !character_box_config.is_player:return
	if event.is_action_pressed("uiselect"):
		if !UiState.state_box.showing:
			UiState.state_box.show_box()
		else :
			UiState.state_box.hide_box()


func _on_delay_timer_timeout() -> void:
	test.text=character_box_config.character_box_id
	texture_rect.texture = character_box_config.image
	img_box.size_flags_stretch_ratio=0
	size_flags_stretch_ratio=0
	img_box_top_marg.size_flags_stretch_ratio=20
	modulate=character_box_config.unselect_modulate
	set_avatar_by_keyword(character_box_config.current_default_expression,character_box_config.avatar_folder)
	show()
	var twn = create_tween()
	twn.set_trans(Tween.TRANS_SPRING)
	twn.set_ease(Tween.EASE_OUT)
	twn.tween_property(self,"size_flags_stretch_ratio",character_box_config.wide_marg_hide,0.5)
	twn.parallel().tween_property(img_box,"size_flags_stretch_ratio",20,0.3)
	twn.parallel().tween_property(img_box_top_marg,"size_flags_stretch_ratio",character_box_config.img_box_top_marg_hide,0.5)
	await twn.finished
	UiState.set_character_box_showing(character_box_config,true,self)
	twn.kill()	
