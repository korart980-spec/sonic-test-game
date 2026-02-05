extends Node

var character_scenes: Dictionary = {
	"sonic": preload("res://characters/sonic/sonic.tscn"),
	"exetior": preload("res://characters/exetior/exetior.tscn")
}

var selected_character_id: String = ""

func select_character(character_id: String):
	selected_character_id = character_id

func get_selected_character_scene() -> PackedScene:
	return character_scenes.get(selected_character_id)
