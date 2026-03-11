extends CharacterBody2D

var last_direction = "Left"

@export var speed = 75
@export var roll_speed = 125
@export var roll_duration = 0.7
@export var health = 5

var rolling = false
var roll_timer = 0.0
var invincible = false
var roll_direction = Vector2.ZERO

var attacking = false
var attack_timer = 0.0
@export var attack_duration = 0.4

@onready var sprite = $AnimatedSprite2D
@onready var dust = $DustParticles

@onready var sword_pivot = $SwordPivot
@onready var sword_sprite = $SwordPivot/SwordSprite
@onready var sword_hitbox = $SwordPivot/SwordHitbox


func _physics_process(delta):

	if rolling:
		velocity = roll_direction * roll_speed
		move_and_slide()

		roll_timer -= delta
		if roll_timer <= 0:
			rolling = false
			invincible = false

		return


	if attacking:
		attack_timer -= delta

		if attack_timer <= 0:
			attacking = false
			sword_hitbox.monitoring = false
			sword_sprite.visible = false

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


	if Input.is_action_just_pressed("roll") and not attacking:
		start_roll(direction_x, direction_y)
		return


	if Input.is_action_just_pressed("attack") and not rolling:
		start_attack()
		return


	velocity.x = direction_x * speed
	velocity.y = direction_y * speed

	move_and_slide()

	update_animation(direction_x, direction_y)



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



func start_attack():

	attacking = true
	attack_timer = attack_duration

	sword_sprite.visible = true
	sword_hitbox.monitoring = true

	if last_direction == "Right":
		sword_pivot.position.x = 10
		sword_sprite.rotation_degrees = 90
	else:
		sword_pivot.position.x = -18
		sword_sprite.rotation_degrees = -90

	sword_sprite.play("attackRight")



func _on_sword_hitbox_body_entered(body):

	if body.is_in_group("enemy"):
		body.take_damage(1)



func take_damage(amount):

	if invincible:
		return

	invincible = true
	health -= amount

	sprite.modulate = Color(1,0.3,0.3)

	await get_tree().create_timer(0.3).timeout

	sprite.modulate = Color(1,1,1)
	invincible = false

	if health <= 0:
		die()


func die():
	print("Player died")
	get_tree().reload_current_scene()
