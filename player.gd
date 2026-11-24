extends CharacterBody2D

@export var SPEED := 150.0
@export var ACCELERATION := 220.0
@export var DECELERATION := 200.0
@export var JUMP_FORCE := 270.0
@export var GRAVITY := 950.0
@export var Jump_Buffer_Time: float = 0.1
@export var COYOTE_TIME: float = 0.12

#slidehop
@export var SLIDE_BOOST := 75.0
@export var MAX_BHOP_SPEED := 480.0
@export var SLIDE_FRICTION := 220.0
@export var AIR_ACCEL := 450.0

#sfx
@onready var sfx_jump = $sfx_jump

var Jump_Buffer: bool = false
var jump_available: bool = true
var coyote_timer: float = 0.0
var was_on_floor: bool = false

var is_sliding: bool = false
var slide_direction: float = 0.0

var was_airborne: bool = false

func respawn():
	self.global_position = Vector2(246,470)


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis("left", "right")
	var holding_down := Input.is_action_pressed("down")

	#start slide
	if holding_down and is_on_floor() and not is_sliding:
		var move_dir: float = direction if direction != 0.0 else signf(velocity.x)
		if move_dir != 0.0:
			start_slide(move_dir)

	#stop slide
	if is_sliding and (not holding_down or not is_on_floor()):
		is_sliding = false

	# acc&dec
	if is_sliding:
		velocity.x = move_toward(velocity.x, 0.0, SLIDE_FRICTION * delta)
		if absf(velocity.x) < SPEED * 0.8:
			is_sliding = false
		# slide animation
	elif is_on_floor():
		if direction != 0.0:
			var rate := ACCELERATION if absf(velocity.x) <= SPEED else DECELERATION * 0.5
			velocity.x = move_toward(velocity.x, direction * SPEED, rate * delta)
			# run animation
		else:
			# Decelerate to a stop when no input is pressed
			velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)
			# idle animation
	else:
		if direction != 0.0:
			if signf(velocity.x) != signf(direction) or absf(velocity.x) < SPEED:
				velocity.x = move_toward(velocity.x, direction * SPEED, AIR_ACCEL * delta)

	#Flip sprite
	if direction == 1.0:
		$Sprite2D.flip_h = false
	elif direction == -1.0:
		$Sprite2D.flip_h = true

	#Gravity
	if is_on_floor():
		if was_airborne:
			was_airborne = false
			$Sprite2D.scale = Vector2(0.15,0.19)
	else:
		velocity.y += GRAVITY * delta
		if velocity.y > 0.0:
			pass
			# fall animation
		was_airborne = true

	#Coyote time tracking
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		jump_available = true
	else:
		if was_on_floor and velocity.y >= 0.0:
			coyote_timer = COYOTE_TIME
		elif coyote_timer > 0.0:
			coyote_timer -= delta

	#Jump buffer input
	if Input.is_action_just_pressed("jump"):
		if can_jump():
			jump()
		else:
			Jump_Buffer = true
			get_tree().create_timer(Jump_Buffer_Time).timeout.connect(onjumpbuffer_timeout)

	if Jump_Buffer and can_jump():
		jump()
		Jump_Buffer = false

	# Variable jump height
	if velocity.y < 0.0 and Input.is_action_just_released("jump"):
		velocity.y *= 0.8

	was_on_floor = is_on_floor()
	move_and_slide()
	
	$Sprite2D.scale.x = move_toward($Sprite2D.scale.x, 0.2, 0.2 *delta)
	$Sprite2D.scale.y = move_toward($Sprite2D.scale.y, 0.2, 0.2 *delta)

func start_slide(dir: float) -> void:
	is_sliding = true
	slide_direction = signf(dir)
	$Sprite2D.flip_h = slide_direction < 0.0

	var current_speed := absf(velocity.x)
	var target_speed := clampf(maxf(current_speed, SPEED) + SLIDE_BOOST, SPEED, MAX_BHOP_SPEED)
	velocity.x = slide_direction * target_speed

func can_jump() -> bool:
	return jump_available and (is_on_floor() or coyote_timer > 0.0)

func jump() -> void:
	is_sliding = false
	velocity.y = -JUMP_FORCE
	$Sprite2D.scale = Vector2(0.1, 0.21)
	sfx_jump.play()
	# jump animation
	jump_available = false
	coyote_timer = 0.0

func onjumpbuffer_timeout() -> void:
	Jump_Buffer = false
	
