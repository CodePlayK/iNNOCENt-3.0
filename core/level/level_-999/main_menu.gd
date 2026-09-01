extends VBoxContainer
@onready var menu_1r: MarginContainer = %menu1R
@onready var menu_2: UIMenuTab = %menu2
@onready var menu_3: VBoxContainer = %menu3
@onready var menu_1: VBoxContainer = %menu1
@onready var color_back: ColorRect = %ColorBack
@onready var menu_dof: ColorRect = $MarginContainer/MenuDOF
@onready var exit: Button = $MarginContainer/Menu/menu1/Exit
@onready var hide_menu: Button = $MarginContainer/Menu/menu1/HideMenu
@onready var continue_game: Button = $MarginContainer/Menu/menu1/ContinueGame
@onready var back_2_main_menu: Button = $MarginContainer/Menu/menu1/Back2MainMenu
@onready var new_gmae: Button = $MarginContainer/Menu/menu1/NewGmae
@onready var quick_save_game: Button = $MarginContainer/Menu/menu1/QuickSaveGame
@onready var save_save_file: Button = $MarginContainer/Menu/menu3/SaveSaveFile


func _ready() -> void:
	default_view()
	EventBus.on_esc_pressed.connect(on_esc_pressed)
	EventBus.old_level_hide_complete.connect(on_old_level_hide_complete)

func on_old_level_hide_complete():
	hide()

func on_esc_pressed():
	if LevelState.current_level == LevelState.LEVELS.LEVEL_MAIN_SCREEN:
		return
	if LevelState.changing_level:
		return
	visible = !visible
	if visible:
		pop_view()
	
	
func _on_read_save_pressed() -> void:
	save_file_view()
	pass # Replace with function body.

func _on_back_2_main_pressed() -> void:
	if LevelState.current_level == LevelState.LEVELS.LEVEL_MAIN_SCREEN:
		default_view()	
	else:
		pop_view()	

##主界面时的默认状态
func default_view():
	color_back.hide()
	menu_2.hide()
	menu_1r.show()
	new_gmae.show()
	menu_3.hide()	
	menu_1.show()
	continue_game.show()
	hide_menu.hide()
	exit.show()
	back_2_main_menu.hide()
	quick_save_game.hide()
	if LevelState.current_level==LevelState.LEVELS.LEVEL_MAIN_SCREEN:
		save_save_file.hide()
	else :
		save_save_file.show()
	
func pop_view():
	default_view()
	color_back.show()
	quick_save_game.show()
	back_2_main_menu.show()
	exit.hide()
	hide_menu.show()	
	continue_game.hide()	
	new_gmae.hide()	
	
##存档界面的状态
func save_file_view():
	menu_2.show()
	menu_3.show()
	menu_1r.hide()
	menu_1.hide()


func _on_save_save_file_pressed() -> void:
	pass # Replace with function body.


func _on_hide_pressed() -> void:
	hide()


func _on_back_2_main_menu_pressed() -> void:
	PlayerState.current_player_born_position = LevelState.main_scrren_player_pos
	EventBus._change_level(LevelState.LEVELS.LEVEL_MAIN_SCREEN,self)


func _on_new_save_file_pressed() -> void:
	
	pass # Replace with function body.


func _on_new_gmae_pressed() -> void:
	Global.everythingeverywhere42.reset_all_levels()
	CutsceneState.current_cutscene = "0_0_0"
	EventBus._change_level(LevelState.LEVELS.LEVEL_0,self)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_visibility_changed() -> void:
	DataState.current_screenshot = ImageTexture.create_from_image(get_viewport().get_texture().get_image())##更新截图
	pass # Replace with function body.
