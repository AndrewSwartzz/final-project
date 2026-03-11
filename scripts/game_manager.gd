extends Node

enum GameState { PLAYING, WIN, GAME_OVER }

var current_state = GameState.PLAYING
var keys_collected = 0
var total_keys = 3

func collect_key():
	keys_collected += 1
	print("Keys:", keys_collected)

func win_game():
	current_state = GameState.WIN
	print("You escaped the dungeon!")
