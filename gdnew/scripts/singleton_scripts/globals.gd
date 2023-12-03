extends Node2D

@onready var player:CharacterBody2D = get_node("/root/Core/CoreControl/MVCont/MV/CurrentLevel/Player");
@onready var main_viewport:SubViewport = get_node("/root/Core/CoreControl/MVCont/MV")
@onready var current_level:Level2D = get_node("/root/Core/CoreControl/MVCont/MV/CurrentLevel")

const GRAVITY : int = 80

func buffered_is_action_just_released(_inputAction : String, _timeInSeconds : float):
	if Input.is_action_just_released(_inputAction):
		var buffer_timer:Timer = Timer.new()
		buffer_timer.start(_timeInSeconds)
		if not(buffer_timer.is_stopped()):
			return true
		else:
			buffer_timer.queue_free()
	else:
		return false
