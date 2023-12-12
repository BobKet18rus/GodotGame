extends Node2D
class_name EnemyComponents

@export_category("Components")

@export var id : g.enemies_ids = 0

@export_group("Health Components")
@export var is_immortal : bool
@export var health : float = 0 : set = _set_health
@export_range(0, 1, 0.05) var defense : float

@export_group("Other Components")
@export var damage : int
@export var speed : float
@export_node_path("Area2D") var hitbox : NodePath

signal taking_damage(old_health, new_health)
signal death

func _ready() -> void:
	$Hitbox.area_entered.connect(_on_hitbox_area_entered)

func _set_health(new_value):
	var old_value = health
	health = new_value
	taking_damage.emit(old_value, new_value)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.get_parent() is ProjectileComponents:
		var components = area.get_parent()
		var projectile = components.get_parent()
		var is_defense_piercing = components.is_defense_piercing

		match components.target:
			components.targets.ENEMY:
				if is_defense_piercing:
					self.health -= components.damage
				else:
					self.health -= components.damage * (1 - self.defense)
				
		if not(components.is_target_piercing):
			projectile.queue_free()

func _on_taking_damage(old_health: Variant, new_health: Variant) -> void:
	if old_health != 0:
		print("Old HP: ", old_health, " -> New HP: ", new_health)
	if self.health <= 0:
		death.emit()

func _on_death() -> void:
	get_parent().queue_free()
	print("здох")
