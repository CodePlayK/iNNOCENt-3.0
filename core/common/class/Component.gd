@icon("res://core/common/resource/icon/BTComposite.svg")
extends Node
##工具类
class_name Component
##工具类的自定义类名,储存于[method TreeItem.set_metadata]的元数据中
var clazz_name = "Component"
##父类的类型限定配置
var FATHER_CLASS_NAME:String
var enable:bool=false
var is_ready:bool=false

func _init() -> void:
	init_var()
	set_meta("clazz_name",clazz_name)
	init()
		
func init():
	pass
	
func init_var():
	pass
	
func connect_signal():
	pass
	
func _ready() -> void:
	load_var()
	connect_signal()
	ready()
	is_ready=true

func ready():
	pass
	
func load_var():
	pass

func _physics_process(delta: float) -> void:
	if !is_ready:return
	physics_process(delta)
	
func physics_process(delta: float):
	pass

func _process(delta: float) -> void:
	if !is_ready:return
	process(delta)
		
func process(delta: float):
	pass	
	
##根据[code]FATHER_CLASS_NAME[/code]与[code]clazz_name[/code]判断当前工具类是否正确挂载
func check_father():
	if FATHER_CLASS_NAME=="":
		enable=true
		return
	var parent = get_parent()
	var clazz_name = parent.get_meta("clazz_name")
	if parent.get_class()==FATHER_CLASS_NAME:
		enable=true
		return
	elif clazz_name:
		if clazz_name == FATHER_CLASS_NAME:
			enable=true
		else:
			Debug.dprinterr(DebugCT.dp("[%s]当前组件挂载父类有误!,应为[%s],实际为[%s|%s]" %[self.name,FATHER_CLASS_NAME,parent.get_path(),parent.clazz_name],self,))
	else:
		Debug.dprinterr(DebugCT.dp("[%s]当前组件挂载父类有误!,应为[%s],实际为[%s]" %[self.name,FATHER_CLASS_NAME,parent.get_path()],self,))
