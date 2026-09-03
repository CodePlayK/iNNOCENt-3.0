extends Label
@onready var timer: Timer = $Timer



func _on_timer_timeout() -> void:
	if int(text) <=0:
		text = "60"
	else:
		if int(text)-1 < 10:
			text = "0" + str(int(text)-1)
		else :
			text = str(int(text)-1)
