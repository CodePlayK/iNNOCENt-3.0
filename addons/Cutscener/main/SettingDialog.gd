@tool
extends AcceptDialog

func _on_confirmed() -> void:
	CutscenerGlobal.METHOD_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["method_bus"]
	CutscenerGlobal.STATE_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["state_bus"]
	CutscenerGlobal.request_reload_methods()

func _on_canceled() -> void:
	_on_confirmed()
