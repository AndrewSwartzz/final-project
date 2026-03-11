extends Area2D

func _on_body_entered(body):

	if body.name == "Player":

		var gm = get_tree().get_first_node_in_group("game_manager")

		if gm.keys_collected >= gm.total_keys:
			gm.win_game()
