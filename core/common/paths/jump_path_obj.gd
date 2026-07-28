extends Component
var obj:Npcs

func on_master_ready(master):
	obj = master.obj
	enable = true

func jump_trans_begin():
	obj.state_manager.string2state("lift",self)

func jump_trans_finished():
	obj.state_manager.string2state("patrol",self)

func jump_trans_midway():
	obj.state_manager.string2state("fall",self)
