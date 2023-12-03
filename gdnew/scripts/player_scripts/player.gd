extends CharacterBody2D

@export var speed: float = 700
@export var jump_force: int = 1000
const ACCELERATION: float = 0.3
const FRICTION: float = 0.3
const max_jump_timer:int = 100
var gdelta:float

var jump_timer:int

var state: int = sm.AIR : set = _set_state

signal state_changed(a, b)

@onready var coyote_timer = $CoyoteTimer

enum sm{
	IDLE = 0,
	MOVE = 1,
	CROUCH = 2,
	SNEAK = 3,
	AIR = 4,
	MAIR = 5,
	JUMP = 6,
	MJUMP = 7,
	CTIME = 8,
	GODMODE = 69
}

var direction : int


func _debug():
	if Input.is_action_just_pressed("DEBUG_MODE"):
		$DebugMod.visible = !$DebugMod.visible
	
	if Input.is_action_just_pressed("GOD_MODE"):
		velocity = Vector2i.ZERO
		$Collision.disabled = !$Collision.disabled
		
		if state == sm.GODMODE:
			state = sm.AIR
		else:
			state = sm.GODMODE
		
	var fps : String = str(Engine.get_frames_per_second())
	var memory_usage : String = str(OS.get_static_memory_usage() / (1_048_576))
	var memory_usage_max : String = str(OS.get_static_memory_peak_usage() / (1_048_576))
	
	$DebugMod/Monitors/Monitors/FPS/Label.text = "FPS: " + fps
	$DebugMod/Monitors/Monitors/MemoryUsage/Label.text = "MEM: " + memory_usage
	$DebugMod/Monitors/Monitors/MemoryUsageMax/Label.text = "MEM MAX: " + memory_usage_max
	$DebugMod/Monitors/Monitors/Velocity/Label.text = "VELOCITY: " + str(velocity)
	$DebugMod/Monitors/Monitors/State/Label.text = "STATE: " + str(state)

# Main Methods =====================================================================================
func state_machine() -> void:
	match state:
		sm.IDLE:
			idle(1)
			move(1)
			jump_buffer()
			jump()
			gravity(1)
		sm.MOVE:
			move(1)
			jump_buffer()
			jump()
			gravity(1)
		sm.AIR:
			jump_timer = 0
			idle(0.5)
			move(0.5)
			gravity(1)
		sm.MAIR:
			jump_timer = 0
			move(0.5)
			gravity(1)
		sm.JUMP:
			coyote_timer.stop()
			move(0.5)
			jump_buffer()
			jump()
			#gravity(1)
		sm.MJUMP:
			coyote_timer.stop()
			move(0.5)
			jump_buffer()
			jump()
			#gravity(1)
		sm.CTIME:
			move(1)
			jump_buffer()
			jump()
			gravity(1)
		sm.GODMODE:
			gm_movement()

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	gdelta = delta
	_debug()

func _physics_process(delta: float) -> void:
	state_machine()
	#gravity()
	
	var was_on_floor: bool = is_on_floor()
	
	move_and_slide()
	
	if was_on_floor and not(is_on_floor()):
		coyote_timer.start()

# Constructor Methods ==============================================================================

func move(acceleration_multiplier: float) -> void:
	if Input.get_axis("LEFT", "RIGHT") != 0:
		velocity.x = lerp(velocity.x, Input.get_axis("LEFT", "RIGHT")*speed, ACCELERATION * acceleration_multiplier)
		if is_on_floor():
			state = sm.MOVE
		elif not(is_on_floor()):
			if not(coyote_timer.is_stopped()):
				state = sm.CTIME
			else:
				state = sm.MAIR
	else:
		idle(2)
		
func idle(friction_multiplier: float) -> void:
	if is_on_floor():
		velocity.x = lerpf(velocity.x, 0.0, FRICTION * friction_multiplier)
		
	if not(Input.get_axis("LEFT", "RIGHT")):
		if is_on_floor():
			state = sm.IDLE
		elif not(is_on_floor()):
			state = sm.AIR
		
func jump_buffer() -> void:
	if Input.is_action_pressed("JUMP"):
		jump_timer += 400*gdelta
	else:
		jump_timer = 0
	
func jump() -> void:
	if Input.is_action_pressed("JUMP") and jump_timer < max_jump_timer:
		if Input.get_axis("LEFT", "RIGHT"):
			state = sm.MJUMP
		else:
			state = sm.JUMP
		velocity.y = -jump_force

func gravity(gravity_multiplier: float) -> void:
	if is_on_floor():
		velocity.y += 100
	else:
		velocity.y += g.GRAVITY * gravity_multiplier

#GODMODE============================================================================================
func gm_movement() -> void:
	velocity = Input.get_vector("LEFT", "RIGHT", "UP", "DOWN") * 2000
	

#SETTERS/GETTERS====================================================================================
func _set_state(new_value: int) -> void:
	var old_value: int = state
	state = new_value
	state_changed.emit(old_value, new_value)

func _on_check_button_button_down() -> void:
	$DebugMod/ShownPanels.visible = !$DebugMod/ShownPanels.visible

func _on_monitors_button_down() -> void:
	$DebugMod/Monitors.visible = !$DebugMod/Monitors.visible

func _on_state_changed(old_value, new_value) -> void:
	
		print(str(old_value)+", "+str(new_value))
