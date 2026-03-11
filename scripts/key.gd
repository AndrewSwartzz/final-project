extends Area2D

func _on_body_entered(body):

	if body.name == "Player":

		var gm = get_tree().get_first_node_in_group("game_manager")
		gm.collect_key()

		call_deferred("queue_free")
