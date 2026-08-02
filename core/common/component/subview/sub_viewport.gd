extends SubViewport
class_name SyncSubViewport
## 将 SubViewport 与主窗口/主视口同步（尺寸 + 可选相机）

@onready var texture_rect: TextureRect = $"../../TextureRect"

@export_group("尺寸")
## 与主视口可见区域尺寸同步
@export var sync_size: bool = true
## 为 true 时用窗口像素尺寸；false 用 get_visible_rect().size
@export var use_window_size: bool = false

@export_group("相机")
## 本 Viewport 内的 Camera2D（留空则尝试子节点 $Camera2D）
@export var local_camera: Camera2D
## 为 true 时每帧同步主场景 Camera2D 的 transform
@export var sync_camera: bool = true
## 指定主相机；留空则 get_viewport().get_camera_2d()
@export var main_camera: Camera2D

@export_group("其它")
## 同步时强制 transparent_bg（遮罩用可开）
@export var force_transparent_bg: bool = false


func _ready() -> void:
	if local_camera == null:
		local_camera = get_node_or_null("Camera2D") as Camera2D

	if force_transparent_bg:
		transparent_bg = true

	_apply_size()

	var root_vp := get_tree().root
	if root_vp:
		root_vp.size_changed.connect(_apply_size)

	# 部分情况下还需要听当前 viewport
	var parent_vp := get_viewport()
	if parent_vp and parent_vp != root_vp:
		parent_vp.size_changed.connect(_apply_size)


func _physics_process(_delta: float) -> void:
	if sync_camera:
		_apply_camera()
	texture_rect.texture=get_texture()

func _apply_size() -> void:
	if not sync_size:
		return

	var target: Vector2
	if use_window_size:
		target = Vector2(DisplayServer.window_get_size())
	else:
		var vp := get_tree().root
		target = vp.get_visible_rect().size if vp else Vector2.ZERO

	if target.x < 1.0 or target.y < 1.0:
		return

	size = Vector2i(target)


func _apply_camera() -> void:
	if local_camera == null:
		return

	var src: Camera2D = main_camera
	if src == null:
		# 注意：SubViewport 内 get_camera_2d 可能指到自己，要从树根取
		src = get_tree().root.get_camera_2d()

	if src == null or src == local_camera:
		return

	local_camera.global_transform = src.global_transform
	# 可选：同步缩放/限制等
	local_camera.zoom = src.zoom
	local_camera.offset = src.offset
	local_camera.ignore_rotation = src.ignore_rotation
