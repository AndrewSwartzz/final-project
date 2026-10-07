extends CharacterBody2D

var last_direction = "Left"

@export var speed = 75
@export var roll_speed = 125
@export var roll_duration = 0.7
@export var health = 5
@export var catch_duration = 0.4
@export var exit_door : Node

@onready var bug_label = get_tree().get_first_node_in_group("bug_label")
@onready var sprite = $AnimatedSprite2D
@onready var dust = $DustParticles

@onready var net_pivot = $NetPivot
@onready var net_sprite = $NetPivot/NetSprite
@onready var net_hitbox = $NetPivot/NetHitbox

@onready var footstep_sound = $FootstepSound
@onready var swing_sound = $SwingSound
@onready var roll_sound = $RollSound

var rolling = false
var roll_timer = 0.0
var invincible = false
var roll_direction = Vector2.ZERO

var catching = false
var catch_timer = 0.0

var bugs_caught = 0


func _physics_process(delta):

	# Rolling state
	if rolling:
		velocity = roll_direction * roll_speed
		move_and_slide()

		roll_timer -= delta

		if roll_timer <= 0:
			rolling = false
			invincible = false

		return


	# Catching state
	if catching:
		catch_timer -= delta

		if catch_timer <= 0:
			catching = false
			net_hitbox.monitoring = false
			net_sprite.visible = false

		return


	var direction_x = 0
	var direction_y = 0

	if Input.is_action_pressed("ui_right"):
		direction_x = 1
	elif Input.is_action_pressed("ui_left"):
		direction_x = -1

	if Input.is_action_pressed("ui_down"):
		direction_y = 1
	elif Input.is_action_pressed("ui_up"):
		direction_y = -1


	# Roll input
	if Input.is_action_just_pressed("roll") and not catching:
		start_roll(direction_x, direction_y)
		return


	# Catch input
	if Input.is_action_just_pressed("catch") and not rolling:
		start_catch()
		return


	velocity.x = direction_x * speed
	velocity.y = direction_y * speed

	move_and_slide()

	update_animation(direction_x, direction_y)
	handle_footsteps(direction_x, direction_y)


func update_animation(direction_x, direction_y):

	if direction_x == 0 and direction_y == 0:
		var anim = "idle" + last_direction

		if sprite.animation != anim:
			sprite.play(anim)

		return


	if direction_x > 0:
		last_direction = "Right"

		if sprite.animation != "moveRight":
			sprite.play("moveRight")

	elif direction_x < 0:
		last_direction = "Left"

		if sprite.animation != "moveLeft":
			sprite.play("moveLeft")


func start_roll(dx, dy):

	rolling = true
	invincible = true
	roll_timer = roll_duration

	# Stop footsteps during roll
	if footstep_sound.playing:
		footstep_sound.stop()

	# Play roll sound
	if roll_sound:
		roll_sound.play()

	dust.restart()
	dust.emitting = true

	if dx == 0 and dy == 0:
		if last_direction == "Right":
			roll_direction = Vector2.RIGHT
		else:
			roll_direction = Vector2.LEFT
	else:
		roll_direction = Vector2(dx, dy).normalized()


	if roll_direction.x > 0:
		last_direction = "Right"
		sprite.play("rollRight")
	else:
		last_direction = "Left"
		sprite.play("rollLeft")


func start_catch():

	catching = true
	catch_timer = catch_duration

	# Stop footsteps while attacking
	if footstep_sound.playing:
		footstep_sound.stop()

	# Play swing sound
	if swing_sound:
		swing_sound.play()

	net_sprite.visible = true
	net_hitbox.monitoring = true

	if last_direction == "Right":
		net_pivot.position.x = 17
		net_sprite.flip_v = true
	else:
		net_pivot.position.x = -12
		net_sprite.flip_v = false

	net_sprite.play("catchRight")


func _on_net_hitbox_body_entered(body):

	# Catch normal bugs
	if body.is_in_group("bug"):
		body.queue_free()
		bugs_caught += 1

		print("Bugs caught:", bugs_caught)
		update_bug_ui()

		if bugs_caught >= 4:
			if exit_door and exit_door.has_method("unlock"):
				exit_door.unlock()

	# Damage boss/enemies
	elif body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)


func take_damage(amount):

	if invincible:
		return

	invincible = true
	health -= amount

	sprite.modulate = Color(1, 0.3, 0.3)

	await get_tree().create_timer(0.3).timeout

	sprite.modulate = Color(1, 1, 1)
	invincible = false

	if health <= 0:
		die()


func die():
	print("Player died")
	get_tree().reload_current_scene()


func update_bug_ui():
	if bug_label:
		bug_label.text = "Bugs: " + str(bugs_caught)


func handle_footsteps(direction_x, direction_y):

	if rolling or catching:
		if footstep_sound.playing:
			footstep_sound.stop()
		return


	if direction_x != 0 or direction_y != 0:
		if !footstep_sound.playing:
			footstep_sound.play()
	else:
		if footstep_sound.playing:
			footstep_sound.stop()
