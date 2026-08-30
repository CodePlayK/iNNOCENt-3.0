extends Node
@export var balance_config:BalanceConfig
@export var notify_nodes:Array[Node]

func _physics_process(delta: float) -> void:
	balance_recover(balance_config.balance_recover_speed*delta)
	
func balance_recover(recover,update:bool = true):
	balance_config.current_balance+=recover
	
func damage_balance(damage,update:bool = true):
	if balance_config.current_balance-damage<0:
		for n in notify_nodes:
			n.on_balance_empty(balance_config)
	balance_config.current_balance-=damage
	
