extends CanvasLayer
@onready var player_camera: Camera2DPlus = %PlayerCamera
@onready var player_collect_marker: Marker = $PlayerCollectMarker
@export var stamina_config:StaminaConfig
@onready var fight_dely_time: Timer = $StateBar/HBC/MarginContainer3/MarginContainer2/FightDelyTime
@onready var stamina_bar: UIbar = $StateBar/HBC/MarginContainer3/MarginContainer2/StaminaBar

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	UiState.player_collect_marker = player_collect_marker
	UiState.canvas = self
	stamina_bar.bar_max_value = stamina_config.max_stamina
	EventBus.player_stamina_recovered.connect(_on_player_stamina_recovered)
	EventBus.player_stamina_damaged.connect(_on_player_stamina_damaged)
	EventBus.player_on_fighting_changed.connect(_on_player_on_fighting_changed)
	EventBus.camera_shake.connect(_on_camera_shake)
	show()
func _on_player_stamina_recovered():
	stamina_bar.bar_grow(stamina_config.current_stamina)
func _on_player_stamina_damaged():
	stamina_bar.bar_decrease(stamina_config.current_stamina)
func _on_player_on_fighting_changed(flag):
	if flag:
		stamina_bar.visible = flag
	else :
		if stamina_bar.visible and fight_dely_time.is_stopped():
			fight_dely_time.start(3)
func _on_camera_shake(strenth,decay):
	player_camera.SHAKE_DECAY = decay
	player_camera.add_shake(strenth)
	
func _on_fight_dely_time_timeout() -> void:
	if stamina_config.current_stamina == stamina_config.max_stamina:
		stamina_bar.hide()
