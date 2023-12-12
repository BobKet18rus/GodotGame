extends Node2D
class_name ProjectileComponents

@export_category("Components")

@export var id : g.projectile_ids = 0

enum targets{
	ENEMY = 	0,
	PLAYER = 	1,
	BOTH = 		2,
	NOBODY = 	3,
	
}

@export_range(0.01, 4096) var lifetime : float
@export var target : targets = targets.ENEMY
@export var is_target_piercing : bool
@export var is_defense_piercing : bool
@export var is_falling : bool
@export var is_parriable : bool
@export var damage : int
@export var direction : Vector2
@export var speed : float
@export_node_path("Area2D") var hitbox : NodePath

func _ready() -> void:
	$LifeTime.wait_time = lifetime
	$LifeTime.start()

func _on_life_time_timeout() -> void:
	self.queue_free()
