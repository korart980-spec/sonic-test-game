extends State

var death_timer: float = 0.0
var death_duration: float = 2.5
var death_position: Vector2 = Vector2.ZERO
var camera_original_parent: Node
var camera_original_position: Vector2

func enter():
	player.is_dead = true
	player.target_animation = "dead"
	
	# Сохраняем позицию смерти для фиксации камеры
	death_position = player.global_position
	
	# БЛОКИРУЕМ КАМЕРУ В ИГРОКЕ
	player.lock_camera()
	
	# ДЕЛАЕМ КАМЕРУ НЕЗАВИСИМОЙ ОТ ИГРОКА
	if player.camera:
		# Сохраняем оригинальные данные камеры
		camera_original_parent = player.camera.get_parent()
		camera_original_position = player.camera.position
		
		# Отключаем камеру у игрока
		player.remove_child(player.camera)
		
		# Добавляем камеру на уровень
		get_tree().current_scene.add_child(player.camera)
		
		# Устанавливаем камеру точно на позицию смерти
		player.camera.global_position = death_position
		player.camera.enabled = true
	
	# ОТЛОЖЕННОЕ отключение коллизий
	player.call_deferred("disable_collisions")
	
	# Подбрасываем вверх
	player.velocity = Vector2(0, -600)
	player.death_timer = 0.0
	
	# Проигрываем звук смерти
	player.get_node("death_sound").play()
	
	# Отключаем управление
	player.set_process_input(false)

func physics_update(delta: float):
	# Применяем гравитацию
	player.velocity.y += player.gravity * delta
	
	death_timer += delta
	
	# После истечения времени показываем соответствующий экран
	if death_timer >= death_duration:
		handle_death_transition()

func handle_death_transition():
	if player.lives <= 0:
		player.emit_signal("show_game_over")
	else:
		get_tree().change_scene_to_file("res://menus/retry/retry_screen.tscn")

func exit():
	# Восстанавливаем коллизии (на случай рестарта)
	player.set_collision_layer_value(1, true)
	player.set_collision_mask_value(1, true)
	player.set_process_input(true)
	player.is_dead = false
	
	# ВОССТАНАВЛИВАЕМ КАМЕРУ ИГРОКУ
	if player.camera and camera_original_parent:
		# Убираем камеру с уровня
		get_tree().current_scene.remove_child(player.camera)
		
		# Возвращаем камеру игроку
		camera_original_parent.add_child(player.camera)
		player.camera.position = camera_original_position
	
	# РАЗБЛОКИРУЕМ КАМЕРУ
	player.unlock_camera()
