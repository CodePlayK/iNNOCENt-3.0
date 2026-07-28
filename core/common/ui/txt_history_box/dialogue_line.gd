extends HBoxContainer
class_name DialogueHistory
@onready var right_talker_name: RichTextLabel = $MC/VC/HC/RightTalkerName
@onready var left_talker_name: RichTextLabel = $MC/VC/HC/LeftTalkerName
@onready var hc: HBoxContainer = $MC/VC/HC
@onready var line: RichTextLabel = $MC/VC/MC/MC/Line
@onready var line_back_color: ColorRect = $MC/VC/MC/LineBackColor
@onready var v_separator: HSeparator = $MC/VC/HC/MC/VSeparator

var my_talker:String
static var current_color

func init(txt:String,talker:String = "",left_side:bool = true) -> void:
	if !txt:
		return
	if !talker:
		hc.hide()
		hc.queue_free()
	if talker and left_side:
		my_talker = talker
		right_talker_name.hide()
		left_talker_name.text = "[b]%s[/b]" %talker
		left_talker_name.show()
		if DialogueState.talker_color.has(talker):
			current_color = DialogueState.talker_color[talker].to_html()
			line.text ="[color=%s] - %s[/color]" %[current_color,txt]
			#left_talker_name.text ="[color=%s][%s][/color]" %[current_color,talker]
		else :
			current_color = null
			line.text =" - %s" %[txt]
	elif !left_side:
		left_talker_name.hide()
		right_talker_name.text = "[b]%s[/b]" %DialogueState.player_name[0]
		right_talker_name.show()
		current_color = DialogueState.talker_color[DialogueState.player_name[0]]
		line.text = "[right][color=%s] - %s[/color][/right]" %[DialogueState.talker_color[DialogueState.player_name[0]].to_html(),txt]
	else :
		line.text ="[color=%s] - %s[/color]" %[current_color,txt]

func _on_mc_mouse_entered() -> void:
	line_back_color.show()


func _on_mc_mouse_exited() -> void:
	line_back_color.hide()
