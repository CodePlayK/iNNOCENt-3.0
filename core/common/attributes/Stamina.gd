extends Attributes
@export var stamina_config:StaminaConfig

func _physics_process(delta: float) -> void:
	stamina_recover(stamina_config.stamina_recover_speed*delta)
	
func stamina_recover(recover,update:bool = true):
	stamina_config.current_stamina+=recover
	if owner:owner.ui.on_stamina_recovered()
	
func damage_stamina(damage,update:bool = true):
	stamina_config.current_stamina-=damage
	if owner:owner.ui.on_stamina_damaged()

func reset():
	stamina_config.current_stamina = stamina_config.max_stamina
