extends Area2D

@export var dialogue_text : String = "Hello traveler."
@export var npc_texture : Texture2D

var player_near = false

@onready var sprite = $Sprite2D
@onready var dialogue_box = get_tree().get_first_node_in_group("dialogue_box")
@onready var dialogue_label = get_tree().get_first_node_in_group("dialogue_text")


func _ready():
	if npc_texture:
		sprite.texture = npc_texture

	if dialogue_box:
		dialogue_box.visible = false


func _process(delta):
	if player_near and Input.is_action_just_pressed("interact"):
		toggle_dialogue()


func toggle_dialogue():
	dialogue_box.visible = !dialogue_box.visible
	dialogue_label.text = dialogue_text


func _on_body_entered(body):
	if body.is_in_group("player"):
		player_near = true


func _on_body_exited(body):
	if body.is_in_group("player"):
		player_near = false
		dialogue_box.visible = false
