extends Node2D

@onready var player:CharacterBody2D = get_node("/root/Core/CoreControl/MVCont/MV/CurrentLevel/Player");
@onready var main_viewport:SubViewport = get_node("/root/Core/CoreControl/MVCont/MV")
@onready var current_level:Level = get_node("/root/Core/CoreControl/MVCont/MV/CurrentLevel")

enum enemies_ids {
	DUMMY = 0,
	
}

enum projectile_ids {
	TEST_PROJECTILE = 0,
	
}

const GRAVITY : int = 80
