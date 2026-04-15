extends CharacterBody2D

@export var speed : float = 60
@export var flee_speed : float = 100
@export var detection_radius : float = 80

var direction = Vector2.LEFT
var change_dir_timer = 0.0
var fleeing = false
var caught = false

@onready var sprite = $Sprite2D


func _ready():
	add_to_group("bug")


func _physics_process(delta):

	if caught:
		return

	var player = get_tree().get_first_node_in_group("player")

	# Flee from player
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < detection_radius:
			fleeing = true
			direction = (global_position - player.global_position).normalized()
		else:
			fleeing = false

	# Movement
	if fleeing:
		velocity = direction * flee_speed
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


# ✅ ONLY UP / DOWN ANIMATION
func update_animation():

	if velocity.length() < 5:
		return

	if velocity.y > 0:
		if sprite.animation != "moveDown":
			sprite.play("moveDown")
	else:
		if sprite.animation != "moveUp":
			sprite.play("moveUp")


# ⭐ CATCH FUNCTION
func get_caught():

	if caught:
		return

	caught = true
	velocity = Vector2.ZERO

	# Fade out
	for i in range(8):
		sprite.modulate.a -= 0.125
		await get_tree().create_timer(0.05).timeout

	queue_free()
