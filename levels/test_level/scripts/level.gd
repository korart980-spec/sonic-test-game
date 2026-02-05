extends Node2D

@onready var spawn_point = $SpawnPoint

func _ready():
	print("=== ЗАГРУЗКА УРОВНЯ ===")
	print("Выбранный ID: '", Global.selected_character_id, "'")
	spawn_player()
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.show_game_over.connect(_on_player_game_over)

func spawn_player():
	var character_scene = Global.get_selected_character_scene()
	
	if character_scene:
		var player = character_scene.instantiate()
		add_child(player)
		player.global_position = spawn_point.global_position
		print("Персонаж добавлен на сцену: ", player.name)
	else:
		print("ОШИБКА: Сцена персонажа не найдена!")
		# Пытаемся загрузить соника по умолчанию
		var default_scene = preload("res://characters/sonic/sonic.tscn")
		if default_scene:
			var player = default_scene.instantiate()
			add_child(player)
			player.global_position = spawn_point.global_position
			print("Загружен персонаж по умолчанию")

func _on_player_game_over():
	#var game_over_scene = preload("res://screens/GameOverScreen.gd")
	#var game_over_instance = game_over_scene.instantiate()
	#add_child(game_over_instance)
	pass
	
func _on_player_retry_screen():
	var retry_scene = preload("res://menus/retry/retry_screen.tscn")
	var retry_instance = retry_scene.instantiate()
	add_child(retry_instance)
