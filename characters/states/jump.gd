extends State

var previous_speed: float = 0.0

func enter():
	if player.was_on_floor:
		player.jump_sound.play()
	
	# Сохраняем скорость перед прыжком
	previous_speed = abs(player.velocity.x)
	
	player.target_animation = "jump"
	player.update_collision_shapes()

func physics_update(delta: float):
	# Управление высотой прыжка
	if player.jump_time_remaining > 0 and Input.is_action_pressed("jump"):
		player.velocity.y += player.gravity * 0.45 * delta
		player.jump_time_remaining -= delta
	else:
		player.jump_time_remaining = 0
		player.velocity.y += player.gravity * delta
	
	# Управление движением в воздухе - УПРОЩЕННАЯ СИСТЕМА КАК В СТАРОМ КОДЕ
	var input_direction = player.get_input_direction()
	var speed = abs(player.velocity.x)
	
	if input_direction != 0:
		player.last_direction = input_direction
		
		# Определяем, происходит ли торможение (движение в противоположную сторону)
		var is_braking = sign(player.velocity.x) != 0 and sign(player.velocity.x) != input_direction
		
		if is_braking:
			# Торможение в воздухе - более сильное
			player.velocity.x = move_toward(player.velocity.x, input_direction * player.max_speed, player.braking_deceleration * delta * 0.5)
		else:
			# Обычное ускорение в воздухе - слабее, чем на земле
			player.velocity.x = move_toward(player.velocity.x, input_direction * player.max_speed, player.acceleration * delta * 0.4)
	else:
		# Замедление в воздухе при отсутствии ввода
		player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.1)
	
	# Если приземлились
	if player.is_on_floor():
		handle_landing()
		return
		
	# ИСПРАВЛЕННАЯ СТРОКА - добавлена проверка player.can_fly
	if Input.is_action_just_pressed("jump") and not player.is_on_floor() and player.can_fly:
		# Проверяем, что мы не в начале прыжка (чтобы избежать мгновенной активации)
		state_machine.change_state("fly")
		return
	
	


	
	player.sprite.flip_h = player.last_direction < 0
	player.update_collision_shapes()

func handle_landing():
	var current_speed = abs(player.velocity.x)
	
	# Если сохранили достаточную скорость и удерживаем look_down - возврат в roll
	if current_speed > 100 and Input.is_action_pressed("look_down"):
		state_machine.change_state("roll")
		return
	
	# Стандартная логика
	if current_speed > 10:
		state_machine.change_state("run")
	else:
		state_machine.change_state("idle")
