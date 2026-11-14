
extends CharacterBody2D

# BASIC PHYSICS
var gravity = 1800.0

# MOVEMENT
var speed = 500.0
var acceleration = 1800.0
var friction = 2200.0

# JUMP
var jump_force = -750.0
var jump_hold_strength = 250.0
var manual_jump_active = false
var bounce_jump_allowed = false

# COFFEE
var coffee_count = 0
var calm_level = 0.0

# BOUNCING
var bounce_enabled = false
var bounce_multiplier = 0.7
var max_bounce_speed = 1400.0
var bounce_min_speed = 100.0
var bounce_energy_loss = 0.65
var bounce_pending = false
var jump_buffer_after_landing = 0.0
var jump_window = 0.15

# WALL BOUNCING
var wall_bounce_strength = 1.0


func _physics_process(delta):
	if jump_buffer_after_landing > 0:
		jump_buffer_after_landing -= delta

	# REMEMBER FLOOR STATE
	var was_on_floor = is_on_floor()
	var jump_pressed = Input.is_action_just_pressed("ui_accept")

	# GRAVITY
	if not was_on_floor:
		velocity.y += gravity * delta

	# MOVEMENT
	var direction = Input.get_axis("move_left", "move_right")

	if direction != 0:
		velocity.x = move_toward(
			velocity.x,
			direction * speed,
			acceleration * delta
		)
	else:
		velocity.x = move_toward(
			velocity.x,
			0,
			friction * delta
		)

	# MANUAL JUMP
	if jump_pressed and (
		was_on_floor
		or jump_buffer_after_landing > 0
	):
		velocity.y = jump_force
		manual_jump_active = true
		bounce_pending = false
		jump_buffer_after_landing = 0.0

	# HOLD SPACE - ONLY FOR MANUAL JUMPS
	if manual_jump_active:
		if Input.is_action_pressed("ui_accept") and velocity.y < 0:
			velocity.y -= jump_hold_strength * delta

	# SAVE VELOCITY BEFORE COLLISIONS
	var impact_velocity = velocity

	move_and_slide()

	# FLOOR LANDING
	if not was_on_floor and is_on_floor():
		jump_buffer_after_landing = jump_window
		manual_jump_active = false

		if bounce_enabled:
			if jump_pressed:
				velocity.y = jump_force
				manual_jump_active = true
				bounce_pending = false
			else:
				var fall_speed = max(impact_velocity.y, 0.0)

				var new_bounce_speed = (
					fall_speed
					* bounce_multiplier
					* bounce_energy_loss
				)

				if new_bounce_speed >= bounce_min_speed:
					velocity.y = -min(
						new_bounce_speed,
						max_bounce_speed
					)
					bounce_pending = true
					bounce_jump_allowed = true
				else:
					velocity.y = 0.0
					bounce_pending = false

	# OTHER COLLISIONS
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var normal = collision.get_normal()

		# CEILING BOUNCE
		if normal.y > 0.7 and impact_velocity.y < 0:
			if bounce_enabled:
				velocity.y = abs(impact_velocity.y)
				bounce_pending = false
				manual_jump_active = false

		# WALL BOUNCE
		if abs(normal.x) > 0.7:
			if impact_velocity.dot(normal) < 0:
				velocity.x = (
					abs(impact_velocity.x)
					* sign(normal.x)
					* wall_bounce_strength
				)


# COLLECTING COFFEE
func collect_coffee():
	coffee_count += 1
	calm_level = min(calm_level + 0.2, 1.0)

	bounce_enabled = true

	# STRONGER MANUAL JUMP
	jump_force = -(750.0 + coffee_count * 180.0)

	# COFFEE INCREASES BOUNCE STRENGTH
	bounce_multiplier = min(
		0.7 + coffee_count * 0.15,
		1.5
	)

	# WALL BOUNCE STRENGTH
	wall_bounce_strength = 1.0 + coffee_count * 0.1

	# FASTER MOVEMENT
	speed = lerp(350.0, 750.0, calm_level)

	# HARDER TO CONTROL
	acceleration = lerp(1800.0, 500.0, calm_level)
	friction = lerp(2200.0, 250.0, calm_level)

	print("Coffee: ", coffee_count)
	print("Jump force: ", jump_force)
	print("Bounce multiplier: ", bounce_multiplier)
