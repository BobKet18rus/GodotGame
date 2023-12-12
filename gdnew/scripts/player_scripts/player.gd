extends CharacterBody2D

##Default state -> Air
@export var state : sm = sm.AIR : set = _set_state
@export var speed : float = 700
@export var jump_force : int = 1000
@export var health : float = 100

@onready var coyote_timer : Timer = $CoyoteTimer
@onready var actual_position = $ActualPosition.position

const ACCELERATION : float = 0.3
const FRICTION : float = 0.3

var floor_angle : float
var gdelta : float

const max_jump_timer:int = 100
var jump_timer:int

var debug_state : String

signal state_changed(old_state, new_state)

var test_projectile : PackedScene = preload("res://scenes/projectiles/test_projectile.tscn")

enum sm{
	IDLE = 			0,
	MOVE = 			1,
	CROUCH = 		2,
	SNEAK = 		3,
	AIR = 			4,
	MOVE_AIR = 		5,
	JUMP = 			6,
	MOVE_JUMP = 	7,
	JUMP_TO_AIR = 	8,
	COYOTE_TIME = 	9,
	
	SPECTATOR = 	69,
}

func _debug():
	if Input.is_action_just_pressed("DEBUG_MODE"):
		$DebugMod.visible = !$DebugMod.visible
	
	if Input.is_action_just_pressed("GOD_MODE"):
		velocity = Vector2i.ZERO
		$Collision.disabled = !$Collision.disabled
		
		if state == sm.SPECTATOR:
			state = sm.AIR
		else:
			state = sm.SPECTATOR
		
	var fps : String = str(Engine.get_frames_per_second())
	var memory_usage : String = str(OS.get_static_memory_usage() / (1_048_576))
	var memory_usage_max : String = str(OS.get_static_memory_peak_usage() / (1_048_576))
	
	$DebugMod/Monitors/Monitors/FPS/Label.text = "FPS: " + fps
	$DebugMod/Monitors/Monitors/MemoryUsage/Label.text = "MEM: " + memory_usage
	$DebugMod/Monitors/Monitors/MemoryUsageMax/Label.text = "MEM MAX: " + memory_usage_max
	$DebugMod/Monitors/Monitors/Velocity/Label.text = "VELOCITY: " + str(velocity)

func spectator_movement() -> void:
	velocity = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN") * 2000

#region === Main Methods ===========================================================================

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	gdelta = delta

	_debug()
	shoot()
	leveling()
	state_machine()
	#camera_position(0.3)
	actual_position = $ActualPosition.position

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = is_on_floor()
	
	move_and_slide()
	
	if was_on_floor and not(is_on_floor()):
		coyote_timer.start()
#endregion

#region === State Machine ==========================================================================

func state_machine() -> void:
	match state:
		sm.IDLE:
			jump_timer = 0
			idle(1)
			move(0.5, false)
			#jump_buffer()
			jump()
			gravity(1)
		sm.MOVE:
			jump_timer = 0
			move(1, false)
			#jump_buffer()
			jump()
			gravity(1)
		sm.AIR:
			idle(0.5)
			move(0.5, false)
			gravity(1)
		sm.MOVE_AIR:
			move(0.5, false)
			gravity(1)
		sm.JUMP:
			coyote_timer.stop()
			move(0.5, true)
			#jump_buffer()
			jump()
			#gravity(1)
		sm.MOVE_JUMP:
			coyote_timer.stop()
			move(0.5, true)
			#jump_buffer()
			jump()
			#gravity(1)
		sm.COYOTE_TIME:
			move(1, false)
			#jump_buffer()
			jump()
			gravity(1)
		sm.SPECTATOR:
			spectator_movement()
#endregion

#region === Other Methods ==========================================================================

func move(acceleration_multiplier: float, for_jump : bool) -> void:
	if Input.get_axis("LEFT", "RIGHT") != 0:
		velocity.x = lerp(velocity.x, Input.get_axis("LEFT", "RIGHT")*speed, ACCELERATION * acceleration_multiplier)
		if is_on_floor() and state != sm.MOVE:
			state = sm.MOVE
		elif not(is_on_floor()):
			if not(coyote_timer.is_stopped()) and state != sm.COYOTE_TIME:
				state = sm.COYOTE_TIME
			elif state != sm.MOVE_AIR and jump_timer >= max_jump_timer:
				state = sm.MOVE_AIR
	else:
		idle(2)
		
func idle(friction_multiplier: float) -> void:
	if is_on_floor():
		velocity.x = lerpf(velocity.x, 0.0, FRICTION * friction_multiplier)
		
	if not(Input.get_axis("LEFT", "RIGHT")):
		if is_on_floor() and state != sm.IDLE:
			state = sm.IDLE
		elif not(is_on_floor()) and state != sm.AIR and jump_timer >= max_jump_timer:
			state = sm.AIR
	
func jump_buffer():
	if Input.is_action_pressed("JUMP"):
		jump_timer += 400 * gdelta
	else:
		jump_timer = max_jump_timer
	
func jump() -> void:
	if Input.is_action_pressed("JUMP") and jump_timer < max_jump_timer:
		jump_buffer()
		if Input.get_axis("LEFT", "RIGHT"):
			state = sm.MOVE_JUMP
		else:
			state = sm.JUMP
		velocity.y = -jump_force
	elif not(is_on_floor()):
		state = sm.AIR

func gravity(gravity_multiplier: float) -> void:
	if is_on_floor():
		velocity.y += 100
	else:
		velocity.y += g.GRAVITY * gravity_multiplier
	
func leveling() -> void:
	floor_angle = Vector2.UP.angle_to(get_floor_normal())
	
	if is_on_floor():
		$Sprite.rotation = lerp_angle($Sprite.rotation, floor_angle, 0.3)
		
	else:
		$Sprite.rotation = lerp_angle($Sprite.rotation, 0.0, 0.1)
	
func shoot():
	if Input.is_action_just_pressed("SHOOT"):
		var projectile_instance : Node2D = test_projectile.instantiate()
		projectile_instance.position = self.position + Vector2(0, -64)
		projectile_instance.look_at(get_global_mouse_position())
		get_parent().add_child(projectile_instance)

func camera_position(camera_position_multiplier):
	if state == sm.MOVE or sm.MOVE_AIR or sm.MOVE_JUMP:
		$Camera.position.x = lerpf($Camera.position.x, velocity.x * camera_position_multiplier, 0.2)
		
	else:
		$Camera.position.x = lerpf($Camera.position.x, 0.0, 0.4)

func _set_state(new_value: int) -> void:
	var old_value: int = state
	state = new_value
	
	if old_value != new_value:
		state_changed.emit(old_value, new_value)

func _on_state_changed(old_value, new_value) -> void:
	var old_debug_state : String
	var new_debug_state : String
	
	match old_value:
		
		sm.IDLE: old_debug_state = "Idle"
		sm.MOVE: old_debug_state = "Move"
		sm.AIR: old_debug_state = "Air(Fall)"
		sm.MOVE_AIR: old_debug_state = "Move Air(Fall)"
		sm.JUMP: old_debug_state = "Jump"
		sm.MOVE_JUMP: old_debug_state = "Move Jump"
		sm.JUMP_TO_AIR: old_debug_state = "Transition from J to A"
		sm.COYOTE_TIME: old_debug_state = "Coyote Time"
		sm.SPECTATOR: old_debug_state = "Spectator"
		
	match new_value:
		
		sm.IDLE: new_debug_state = "Idle"
		sm.MOVE: new_debug_state = "Move"
		sm.AIR: new_debug_state = "Air(Fall)"
		sm.MOVE_AIR: new_debug_state = "Move Air(Fall)"
		sm.JUMP: new_debug_state = "Jump"
		sm.MOVE_JUMP: new_debug_state = "Move Jump"
		sm.JUMP_TO_AIR: new_debug_state = "Transition from J to A"
		sm.COYOTE_TIME: new_debug_state = "Coyote Time"
		sm.SPECTATOR: new_debug_state = "Spectator"

	if $DebugMod/StateHistory.visible == true:
		#print(" Old state: "+str(old_debug_state)+", New state: "+str(new_debug_state))
		$DebugMod/StateHistory/StateHistory/StateHistory.text = str(old_debug_state)+" -> "+str(new_debug_state)+"
" + $DebugMod/StateHistory/StateHistory/StateHistory.text

func _on_check_button_button_down() -> void:
	$DebugMod/ShownPanels.visible = !$DebugMod/ShownPanels.visible

func _on_monitors_button_down() -> void:
	$DebugMod/Monitors.visible = !$DebugMod/Monitors.visible

func _on_history_button_down() -> void:
	$DebugMod/StateHistory.visible = !$DebugMod/StateHistory.visible
	$DebugMod/CleanHistoryButton.visible = !$DebugMod/CleanHistoryButton.visible

func _on_clean_history_button_button_down() -> void:
	$DebugMod/StateHistory/StateHistory/StateHistory.text = ""
#endregion
