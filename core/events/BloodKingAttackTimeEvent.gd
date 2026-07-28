extends BaseEvents
	
func init() -> void:
	event_config = EventData.EVENTS_CONFIG.BLOODKING_ATTACK_TIME
	
func config():
	event.event_value = 0
	
func add_time(t:int = 1):
	event.event_value+=t
	
