extends Resource
class_name BalanceConfig
@export var max_balance:float = 200
@export var last_balance:float = 200
##能量条恢复速度
@export var balance_recover_speed:float =10
##能量条
@export var current_balance:float = 200:
	set(h):
		var e = clamp(h,0,max_balance)
		if e == max_balance:
			current_balance = e
			return
		last_balance = current_balance
		current_balance = e
