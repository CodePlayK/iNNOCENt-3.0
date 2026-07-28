extends Camera2D
# How quickly to move through the noise
@export var NOISE_SHAKE_SPEED: float = 0
@export var NOISE_SWAY_SPEED: float = .05
# Noise returns values in the range (-1, 1)
# So this is how much to multiply the returned value by
@export var NOISE_SHAKE_STRENGTH: float = 1
@export var NOISE_SWAY_STRENGTH: float = 3
# The starting range of possible offsets using random values
# Multiplier for lerping the shake strength to zero
@export var SHAKE_DECAY_RATE: float = 3.0
@export var enable: bool = true
var shake_state:bool=false
var ScreenShakeType:String
@onready var noise = FastNoiseLite.new()
# Used to keep track of where we are in the noise
# so that we can smoothly move through it
var noise_i: float = 0.0
@onready var rand = RandomNumberGenerator.new()
var shake_type: int
var shake_strength: float = 0.0
var last_player_face:bool
var base_offset:float
func _ready() -> void:
	EventBus.screen_shake.connect(_on_screen_shake)
	EventBus.enable_player_camera.connect(_enable_player_camera)
	rand.randomize()
	# Randomize the generated noise
	noise.seed = rand.randi()
	# Period affects how quickly the noise changes values
	noise.frequency = 1
	_on_screen_shake(Global.ScreenShakeType.SWAY,true)
	base_offset=abs(self.get_drag_horizontal_offset())
	last_player_face=!PlayerState.face_left
	make_current()
	
func apply_noise_shake() -> void:
	shake_strength = NOISE_SHAKE_STRENGTH
	
func apply_noise_sway() -> void:
	shake_strength = NOISE_SWAY_STRENGTH
	pass
	
func _process(delta: float) -> void:
	if last_player_face!=PlayerState.face_left:
		if PlayerState.face_left:
			self.set_drag_horizontal_offset(-base_offset)
		else:
			self.set_drag_horizontal_offset(base_offset)
		last_player_face=PlayerState.face_left
	if !enable:return
	# Fade out the intensity over time
	shake_strength = lerp(shake_strength, 0.0, SHAKE_DECAY_RATE * delta)
	var shake_offset: Vector2
	match shake_type:
		Global.ScreenShakeType.NOISE:
			shake_offset = get_noise_offset(delta, NOISE_SHAKE_SPEED, shake_strength)
		Global.ScreenShakeType.SWAY:
			shake_offset = get_noise_offset(delta, NOISE_SWAY_SPEED, NOISE_SWAY_STRENGTH)
	# Shake by adjusting camera.offset so we can move the camera around the level via it's position
	self.offset = shake_offset
func get_noise_offset(delta: float, speed: float, strength: float) -> Vector2:
	noise_i += delta * speed
	# Set the x values of each call to 'get_noise_2d' to a different value
	# so that our x and y vectors will be reading from unrelated areas of noise
	return Vector2(
		noise.get_noise_2d(1, noise_i) * strength,
		noise.get_noise_2d(50, noise_i) * strength
	)
func _on_screen_shake(screen_shake_type:int,state):
	if !enable:return
	if state:
		shake_state=true
		match screen_shake_type:
			Global.ScreenShakeType.NOISE:
				apply_noise_shake()
			Global.ScreenShakeType.SWAY:
				apply_noise_sway()
		shake_type=screen_shake_type
	else:
		shake_state=false

func _on_camera_timer_timeout():
	EventBus.emit_signal("screen_shake",Global.ScreenShakeType.SWAY,true)
	pass 

func _enable_player_camera(flag:bool=true):
	self.enabled=flag
	self.make_current()
	pass 
