extends CharacterBody2D

@export var speed : float = 50
@export var chase_speed : float = 60
@export var detection_radius : float = 140
@export var damage : int = 1
@export var attack_cooldown : float = 1.0

@export var health : int = 10  # ⭐ MORE HEALTH
@export var knockback_force : float = 250

var direction = Vector2.LEFT
var change_dir_timer = 0.0
var chasing = false
var can_attack = true
var dying = false

var knockback_velocity = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D


func _ready():
	add_to_group("enemy")


func _physics_process(delta):

	if dying:
		return

	var player = get_tree().get_first_node_in_group("player")

	if player:
		var distance = global_position.distance_to(player.global_position)

		if distance < detection_radius:
			chasing = true
			direction = (player.global_position - global_position).normalized()
		else:
			chasing = false

	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
	else:
		if chasing:
			velocity = direction * chase_speed
		else:
			change_dir_timer -= delta

			if change_dir_timer <= 0:
				direction = Vector2(
					randf_range(-1, 1),
					randf_range(-1, 1)
				).normalized()
				change_dir_timer = randf_range(1.0, 3.0)

			velocity = direction * speed

	move_and_slide()

	update_animation()


func update_animation():

	if velocity.length() < 5:
		return

	if velocity.y > 0:
		sprite.play("moveDown")
	else:
		sprite.play("moveUp")


func _on_area_2d_body_entered(body):

	if body.is_in_group("player") and can_attack:
		if body.has_method("take_damage"):
			body.take_damage(damage)

		can_attack = false
		attack_cooldown_timer()


func attack_cooldown_timer():
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true



func take_damage(amount):

	if dying:
		return

	health -= amount

	get_tree().call_group("camera", "shake")

	sprite.modulate = Color(1,0.2,0.2)

	var player = get_tree().get_first_node_in_group("player")
	if player:
		var knock_dir = (global_position - player.global_position).normalized()
		knockback_velocity = knock_dir * knockback_force

	await get_tree().create_timer(0.1).timeout
	sprite.modulate = Color(1,1,1)

	if health <= 0:
		die()


func die():

	dying = true
	velocity = Vector2.ZERO

	for i in range(10):
		sprite.modulate.a -= 0.1
		await get_tree().create_timer(0.05).timeout

	queue_free()
