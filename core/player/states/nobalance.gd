extends CombatState
var to_struggle_state:bool
var waiting_anime_finished:bool

func init_var() -> void:
	player.anime.anime_finished.connect(on_anime_finished)


func load_var() -> void:
	to_struggle_state = false
	waiting_anime_finished = true

func physics_process(delta: float) -> BaseState:
	apply_gravity(delta)
	if move == 0 or is_player_change_moving_direction():
		apply_friction(delta)
	if not move_player():
		return null
	player.velocity = min_jump_force(player.velocity, delta)
	if player.is_on_floor() and player.velocity.x == 0 and !waiting_anime_finished:
		to_struggle_state = true
		return struggle_state
	return null

func on_anime_finished(anime_name):
	waiting_anime_finished = false
