extends CharacterBody2D

@export var speed : float = 80
@export var health : int = 3
@export var knockback_force : float = 200

var direction = Vector2.LEFT
var knockback_velocity = Vector2.ZERO
var dying = false

@onready var sprite = $Sprite2D


func _physics_process(delta):

	if dying:
		return

	# Apply knockback
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 600 * delta)
	else:
		velocity = direction * speed

	move_and_slide()

	if is_on_wall():
		direction *= -1


func take_damage(amount):

	if dying:
		return

	health -= amount

	# Flash red
	sprite.modulate = Color(1,0.2,0.2)

	# Knockback
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var knock_dir = (global_position - player.global_position).normalized()
		knockback_velocity = knock_dir * knockback_force

	flash_reset()

	if health <= 0:
		die()


func flash_reset():
	await get_tree().create_timer(0.12).timeout
	sprite.modulate = Color(1,1,1)


func die():

	dying = true
	velocity = Vector2.ZERO

	# Fade out
	for i in range(10):
		sprite.modulate.a -= 0.1
		await get_tree().create_timer(0.04).timeout

	queue_free()
	
func _on_area_2d_body_entered(body):

	if body.is_in_group("player"):
		body.take_damage(1)
