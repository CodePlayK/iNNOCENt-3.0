extends Node
const LEVEL_0_PATH="res://core/level/level_0_地下室/level_0_地下室.tscn"
const LEVEL_1_PATH="res://core/level/level_1_大堂/level_1_大堂.tscn"
const LEVEL_2_PATH="res://core/level/level_2_决斗/level_2_决斗.tscn"
const LEVEL_TEST_PATH="res://core/level/level_Test/level_Test.tscn"

##当前关卡
var current_save_id:int=-99999
var current_level:LEVELS=LEVELS.LEVEL_CURRENT
##储存当前载入过的所有关卡{ [enum LEVELS] : [Levels] }
var level_dic:Dictionary
var current_level_node:Levels
var changing_level:bool = false

##目标关卡所在方向
enum TRANS_DIRCTS {
	UP=0,
	DOWN=1
}
var current_trans_direct:TRANS_DIRCTS


var doors_locked:bool=false
func set_doors_locked(flag:bool,source):
	doors_locked = flag
	Debug.dprintinfo(DebugCT.dp("设置房间门锁定状态 - [%s]" %flag, source))

	
##上一关卡
var last_level:int=LEVELS.LEVEL_1
##当前的主视差层,即该层的视差速度为0
var current_main_layer:Node2D
var level_transition:Dictionary={}
var playing_transition:bool=false

##储存所有关卡的存档载入状态,是否待载入:[br]
##- true:当前关卡需要载入存档里的数据并更新关卡状态[br]
##- false:不需要载入存档状态,代表该关卡已载入玩存档,只是处在[member Node.ProcessMode.PROCESS_MODE_DISABLED][br]
var level_waiting_2_load_dic:Dictionary[LevelState.LEVELS,bool]

## 获取指定关卡是否在等待加载
func is_level_waiting_to_load(level: LevelState.LEVELS) -> bool:
	return level_waiting_2_load_dic.get(level, false)
## 设置指定关卡的等待加载状态
func set_level_waiting_to_load(level: LevelState.LEVELS, waiting: bool = true) -> void:
	level_waiting_2_load_dic[level] = waiting
## 删除指定关卡的等待加载记录
func remove_level_waiting_to_load(level: LevelState.LEVELS) -> void:
	level_waiting_2_load_dic.erase(level)
## 清空所有等待加载的关卡记录
func clear_level_waiting_to_load() -> void:
	level_waiting_2_load_dic.clear()
			
enum LEVELS
{	
	LEVEL_ALL=-2,##所有关卡
	LEVEL_CURRENT=-1,##当前关卡
	LEVEL_0=0,
	LEVEL_1=1,
	LEVEL_2=2,
	LEVEL_TEST=999,
}
