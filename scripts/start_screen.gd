extends Control

func _ready():
	get_tree().paused = false

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://scenes/dungeon_game.tscn")
