extends NpcsCombatState
@onready var create_character_box: Component = $"../../../../Components/CreateCharacterBox"


func enter():
	super.enter()
	create_character_box.remove_character_box()
	npc.light.change_vfx_bright(.1,npc.anime.current_animation_length)
	await get_tree().create_timer(npc.anime.current_animation_length).timeout
	npc.hide()
	return
func exit(state:NpcsBaseState):
	return
