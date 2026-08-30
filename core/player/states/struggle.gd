extends CombatState

var _qte: HeartbeatResuscitationQTE


func enter() -> BaseState:
	_qte = player.ui.get_node_or_null("HeartbeatQTE") as HeartbeatResuscitationQTE
	if _qte:
		if not _qte.qte_finished.is_connected(_on_qte_finished):
			_qte.qte_finished.connect(_on_qte_finished)
		_qte.start_qte()
	return null


func exit(_state: BaseState) -> void:
	if _qte:
		if _qte.qte_finished.is_connected(_on_qte_finished):
			_qte.qte_finished.disconnect(_on_qte_finished)
		if _qte.is_running():
			_qte.stop_qte()
	_qte = null


func physics_process(delta: float) -> BaseState:
	apply_gravity(delta)
	apply_friction(delta)
	move_player()
	return null


func _on_qte_finished(_result: Dictionary) -> void:
	pass
