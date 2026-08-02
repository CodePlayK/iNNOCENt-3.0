extends Node
class_name GodrayOcclusionController
## TileMapLayer 碰撞遮罩 → Godray 裁剪


@export var source_layer: TileMapLayer
@export var occluder_viewport: SubViewport
@export var occluder_camera: Camera2DPlus
@export var mask_draw: TileMapOcclusionMaskDraw
@export var godray: CanvasItem

@export var use_occlusion: bool = true
@export var sync_viewport_size: bool = true

const MASKED_SHADER: Shader = preload("res://core/common/shader/godrays_masked.gdshader")


func _ready() -> void:
	if mask_draw and source_layer:
		mask_draw.source_layer = source_layer
	#occluder_camera = Global.player_camera
	_sync_viewport_size()
	_bind_mask_to_godray()
	rebuild_mask()

	var vp := get_viewport()
	if vp:
		vp.size_changed.connect(_sync_viewport_size)


func _physics_process(_delta: float) -> void:
	_sync_camera()


func _sync_camera() -> void:
	if occluder_camera == null:
		return
	var main_cam := get_viewport().get_camera_2d()
	if main_cam == null:
		return
	#occluder_camera.global_transform = main_cam.global_transform


func _sync_viewport_size() -> void:
	if not sync_viewport_size or occluder_viewport == null:
		return
	var vp := get_viewport()
	if vp:
		occluder_viewport.size = Vector2i(vp.get_visible_rect().size)


func _bind_mask_to_godray() -> void:
	if godray == null or occluder_viewport == null:
		return

	var mat := godray.material as ShaderMaterial
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = MASKED_SHADER
		godray.material = mat

	mat.set_shader_parameter("occlusion_mask", occluder_viewport.get_texture())
	mat.set_shader_parameter("use_occlusion", use_occlusion)


func rebuild_mask() -> void:
	if mask_draw:
		mask_draw.rebuild()


func set_occlusion_enabled(enabled: bool) -> void:
	use_occlusion = enabled
	if godray and godray.material is ShaderMaterial:
		(godray.material as ShaderMaterial).set_shader_parameter("use_occlusion", enabled)
