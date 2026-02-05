extends Node2D

func _on_sonic_play_pressed() -> void:
	Global.select_character("sonic")
	print("Выбран персонаж: sonic")
	get_tree().change_scene_to_file("res://levels/test_level/level.tscn")

func _on_exetior_play_pressed() -> void:
	Global.select_character("exetior")
	print("Выбран персонаж: exetior")
	get_tree().change_scene_to_file("res://levels/test_level/level.tscn")
