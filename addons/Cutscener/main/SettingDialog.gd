@tool
extends AcceptDialog

func _on_confirmed() -> void:
	CutscenerGlobal.METHOD_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["method_bus"].duplicate()
	CutscenerGlobal.STATE_BUSES = CutscenerGlobal.CONFIG_DATA_DIC["state_bus"].duplicate()
	CutscenerGlobal.load_all_method_state_from_global.emit()

func _on_canceled() -> void:
	# 取消不写入，仅重新刷新 UI 勾选状态
	CutscenerGlobal.refresh_setting_autoload_config.emit()
