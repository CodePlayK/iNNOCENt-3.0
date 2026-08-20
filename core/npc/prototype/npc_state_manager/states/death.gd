extends NpcsCombatState


func enter():
	super.enter()
	var create_character_box = npc.get_node_or_null("Components/CreateCharacterBox")
	if create_character_box:
		create_character_box.remove_character_box()
	npc.light.change_vfx_bright(.1, npc.anime.current_animation_length)
	await get_tree().create_timer(npc.anime.current_animation_length).timeout
	npc.hide()
	return


func exit(_state: NpcsBaseState):
	return
