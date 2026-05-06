extends CharacterBody2D

var last_direction = "Left"

@export var speed = 75 
@export var roll_speed = 125
@export var roll_duration = 0.7
@export var health = 5
@onready var bug_label = get_tree().get_first_node_in_group("bug_label")
@export var exit_door : Node

var rolling = false
var roll_timer = 0.0
var invincible = false
var roll_direction = Vector2.ZERO

var catching = false
var catch_timer = 0.0
@export var catch_duration = 0.4

var bugs_caught = 0

@onready var sprite = $AnimatedSprite2D
@onready var dust = $DustParticles

@onready var net_pivot = $NetPivot
@onready var net_sprite = $NetPivot/NetSprite
@onready var net_hitbox = $NetPivot/NetHitbox
@onready var tilemap = get_parent().get_node("TileMap")
@export var bug_scene = preload("res://scenes/enemy.tscn")


func _physics_process(delta):

	if rolling:
		velocity = roll_direction * roll_speed
		move_and_slide()

		roll_timer -= delta
		if roll_timer <= 0:
			rolling = false
			invincible = false

		return


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


	if Input.is_action_just_pressed("roll") and not catching:
		start_roll(direction_x, direction_y)
		return


	if Input.is_action_just_pressed("catch") and not rolling:
		start_catch()
		return


	velocity.x = direction_x * speed
	velocity.y = direction_y * speed

	move_and_slide()

	update_animation(direction_x, direction_y)
	
	if Input.is_action_just_pressed("interact"):
		try_interact()



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



func start_catch():

	catching = true
	catch_timer = catch_duration

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

	if body.is_in_group("bug"):
		body.queue_free()
		bugs_caught += 1

		if bugs_caught >= 4:
			if exit_door and exit_door.has_method("unlock"):
				exit_door.unlock()

		update_bug_ui()
		print("Bugs caught:", bugs_caught)


	elif body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(1)

	check_breakable_tile()



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
	

func check_breakable_tile():

	var hit_position = net_hitbox.global_position

	var tile_coords = tilemap.local_to_map(tilemap.to_local(hit_position))
	var tile_data = tilemap.get_cell_tile_data(1, tile_coords) 

	if tile_data and tile_data.get_custom_data("breakable"):

		if tile_data.get_custom_data("spawns_bug"):
			spawn_bug(tile_coords)

		tilemap.erase_cell(1, tile_coords) 
		
func try_interact():

	var tile_size = tilemap.tile_set.tile_size.x

	var directions = [
		Vector2.RIGHT,
		Vector2.LEFT,
		Vector2.UP,
		Vector2.DOWN
	]

	for dir in directions:

		var check_pos = global_position + (dir * tile_size)
		var tile_coords = tilemap.local_to_map(tilemap.to_local(check_pos))

		for layer in range(tilemap.get_layers_count()):

			var tile_data = tilemap.get_cell_tile_data(layer, tile_coords)

			if tile_data and tile_data.get_custom_data("door"):

				var door_id = tile_data.get_custom_data("door_id")
				enter_linked_door(tile_coords, door_id)
				return
				
func enter_linked_door(current_coords, door_id):

	var found_target = false

	for layer in range(tilemap.get_layers_count()):

		var used_cells = tilemap.get_used_cells(layer)

		for coords in used_cells:

			if coords == current_coords:
				continue

			var tile_data = tilemap.get_cell_tile_data(layer, coords)

			if tile_data and tile_data.get_custom_data("door"):

				if tile_data.get_custom_data("door_id") == door_id:

					teleport_to(coords)
					return  
		
func teleport_to(target_coords):

	var world_pos = tilemap.map_to_local(target_coords)

	global_position = world_pos
	velocity = Vector2.ZERO
	
func spawn_bug(tile_coords):

	var world_pos = tilemap.map_to_local(tile_coords)
	var bug = bug_scene.instantiate()
	bug.global_position = world_pos + Vector2(0, -30)

	get_parent().add_child(bug)
	
func update_bug_ui():
	if bug_label:
		bug_label.text = "Bugs: " + str(bugs_caught)
	
	
