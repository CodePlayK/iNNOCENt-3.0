extends BaseEvents
##配置event为Eventdata中的一个
func init():
	event_config = EventData.EVENTS_CONFIG.PLAYER_DENSE_SUC_TIME_EVENT
	pass
##在载入了config之后的操作	
func config():
	event.event_value = 0
	
##更新操作,仅占位,不写无作用
func add_time(t:int = 1):
	event.event_value += t
