
extends Area2D

@export_file("*.tscn") var next_level_path: String

var level_changing = false


func _ready():
	body_entered.connect(_on_body_entered)


func _on_body_entered(body):
	if level_changing:
		return

	if body is CharacterBody2D and body.name == "Player":
		if next_level_path.is_empty():
			print("No next level selected!")
			return

		level_changing = true
		get_tree().call_deferred(
			"change_scene_to_file",
			next_level_path
		)
