extends Area2D

@export var target_position : Vector2
@export var starts_locked : bool = false   # ⭐ NEW

var unlocked = false
var player_in_range = false


func _ready():
	unlocked = not starts_locked
	update_state()


func update_state():
	visible = true  # ✅ always visible
	monitoring = unlocked  # only blocks interaction if locked


func unlock():
	unlocked = true
	monitoring = true


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_in_range = true


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_in_range = false


func _process(delta):

	if not unlocked:
		return

	if player_in_range and Input.is_action_just_pressed("interact"):
		teleport_player()


func teleport_player():

	var player = get_tree().get_first_node_in_group("player")

	if player:
		player.global_position = target_position
		player.velocity = Vector2.ZERO
