extends Node
##当前关卡
var current_level:int=LEVELS.LEVEL_1
##上一关卡
var last_level:int=LEVELS.LEVEL_1
##当前的主视差层,即该层的视差速度为0
var current_main_layer:Node2D
var level_transition:Dictionary={}
var playing_transition:bool=false
##关卡
enum LEVELS
{	
	LEVEL_ALL=-2,##所有关卡
	LEVEL_CURRENT=-1,##当前关卡
	LEVEL_0=0,
	LEVEL_1=1,
	LEVEL_2=2,
}
