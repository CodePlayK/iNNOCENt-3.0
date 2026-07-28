extends BaseEvents
##配置event为Eventdata中的一个
func init():
	event_config = EventData.EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT
##在载入了config之后的操作	
func config():
	if ItemState.current_item_dic.has(EventData.EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT):
		event.event_value =ItemState.current_item_dic[EventData.EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT][0]

func update() -> void:
	if ItemState.current_item_dic.has(EventData.EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT):
		event.event_value=ItemState.current_item_dic[EventData.EVENTS_CONFIG.FLASHLIGHT_COUNT_EVENT][0]
