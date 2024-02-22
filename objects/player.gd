class_name Player extends CharacterBody2D

## Maximum speed the player can move
const SPEED_MAX:float = 80.0
## How quickly the player gets to max speed
const ACCELERATION:float = 480.0
## Force the player jumps
const JUMP_FORCE:float = 128.0
## Gravity's default force
const GRAVITY:float = 256.0
## The default strength of gravity
const GRAVITY_STRENGTH_DEFAULT:float = 1.0

## Used to multiply the strength of gravity
var gravityStrength:float = 1.0

# Stores the horizontal input
var moveInput:float
# Stores the jump input
var jumpPressed:bool

# Reference to our animation player
@onready var animPlayer:AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Disable processes if not the multiplayer authority
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)

func _process(delta:float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Get player input
	moveInput = Input.get_axis("move_left", "move_right")
	jumpPressed = Input.is_action_just_pressed("jump")

func _physics_process(delta:float) -> void:
	if not is_multiplayer_authority():
		return
	
	# Apply gravity
	velocity.y += GRAVITY * gravityStrength * delta
	
	# Simple jumping
	if jumpPressed and is_on_floor():
		velocity.y = -JUMP_FORCE
		jumpPressed = false
	
	# Apply friction only if on the floor
	if is_on_floor():
		velocity.x = move_toward(velocity.x, moveInput * SPEED_MAX, ACCELERATION * delta)
	else:
		if moveInput:
			velocity.x = move_toward(velocity.x, moveInput * SPEED_MAX, ACCELERATION * delta)
	
	# Update our players movement
	move_and_slide()
