extends Node
@onready var mc = $MC
@onready var debug_box: HBoxContainer = $MC/VBoxContainer/DebugBox
@onready var debug_printer: RichTextLabel = $MC/VBoxContainer/DebugBox/DebugPrinter
@export var print_cutscener:bool = true
var time:String
func _ready():
	debug_printer.get_v_scroll_bar().hide()
	CutscenerGlobal.log_change.connect(on_cutscener_log_change)
	
func on_cutscener_log_change(s):
	dprintcutscener(DebugCT.dp(s,CutscenerGlobal))
	
func dprintcutscener(t):
	if !print_cutscener:return
	time = str(Time.get_ticks_msec())
	var text = "[color=757575][%s][%s] \n[color=ffff00]%s" %[DebugCT.from_node,time,DebugCT.text]
	debug_printer.append_text("\n"+text)
	
func dprint(t):
	time = str(Time.get_ticks_msec())
	var text = "[color=757575][%s][%s] \n[color=ffffff] - %s" %[DebugCT.from_node,time,DebugCT.text]
	print_rich(text)
	debug_printer.append_text("\n"+text)
	
func dprinterr(t):
	time = str(Time.get_ticks_msec())
	var text = "[color=757575][%s][%s] \n[color=ff241ae5] - %s" %[DebugCT.from_node,time,DebugCT.text]
	print_rich(text)
	debug_printer.append_text("\n"+text)
	
func dprintwarn(t):
	time = str(Time.get_ticks_msec())
	var text = "[color=757575][%s][%s] \n[color=ffff19] - %s" %[DebugCT.from_node,time,DebugCT.text]
	print_rich(text)
	debug_printer.append_text("\n"+text)
		
func dprintinfo(t):
	time = str(Time.get_ticks_msec())
	var text = "[color=757575][%s][%s] \n[color=1ee6d2] - %s" %[DebugCT.from_node,time,DebugCT.text]
	print_rich(text)
	debug_printer.append_text("\n"+text)
	
func _on_printer_mouse_entered():
	debug_printer.grab_focus()
	debug_box.size_flags_stretch_ratio = 10
	debug_printer.get_v_scroll_bar().show()
	
func _on_printer_mouse_exited():
	debug_printer.release_focus()
	debug_box.size_flags_stretch_ratio = 0
	await RenderingServer.frame_post_draw
	debug_printer.scroll_to_line(debug_printer.get_line_count())
	debug_printer.get_v_scroll_bar().hide()

func _on_button_pressed():
	debug_printer.get_v_scroll_bar().hide()
