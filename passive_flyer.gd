extends CharacterBody2D

@export var move_speed = 100
@export var direction_change_time = 0.6
@export var wander_radius = 120

var start_position
var current_direction = Vector2.ZERO
var timer = 0.0

@onready var sprite = $Sprite2D


func _ready():
	start_position = global_position
	pick_new_direction()


func _physics_process(delta):
	timer -= delta

	if timer <= 0:
		pick_new_direction()

	# keep it near spawn area
	var distance_from_home = global_position.distance_to(start_position)

	if distance_from_home > wander_radius:
		current_direction = (start_position - global_position).normalized()

	velocity = current_direction * move_speed
	move_and_slide()

	update_sprite_direction()


func pick_new_direction():
	timer = randf_range(0.3, direction_change_time)

	current_direction = Vector2(
		randf_range(-1, 1),
		randf_range(-1, 1)
	).normalized()


func update_sprite_direction():
	if current_direction.x > 0:
		sprite.flip_h = false
	elif current_direction.x < 0:
		sprite.flip_h = true
