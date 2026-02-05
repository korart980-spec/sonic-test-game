extends State

func enter():
	player.skid_sound.play()
	player.target_animation = "skid"
	
	# Сохраняем направление торможения
	if player.skid_direction == 0:
		player.skid_direction = sign(player.velocity.x)
	
	player.update_collision_shapes()

func exit():
	player.skid_direction = 0

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	
	# Сильное замедление во время торможения
	player.velocity.x = move_toward(player.velocity.x, 0, player.braking_deceleration * delta * 1.5)
	
	var input_direction = player.get_input_direction()
	var speed = abs(player.velocity.x)
	
	# Проверка условий выхода из торможения
	handle_skid_transition(input_direction, speed)

func handle_skid_transition(input_direction: int, speed: float):
	# Если игрок отпустил клавиши или изменил направление
	if input_direction == 0 or sign(player.velocity.x) == input_direction:
		# Выходим из состояния торможения
		if speed < 50:
			state_machine.change_state("idle")
		else:
			state_machine.change_state("run")
		return
	
	# Если продолжаем удерживать направление, противоположное движению
	if input_direction != 0 and sign(player.velocity.x) != input_direction:
		# Продолжаем торможение - ничего не делаем
		pass
	
	# Проверяем, не остановились ли мы полностью
	if speed < 10:
		state_machine.change_state("idle")
		return
	
	# Прыжок во время торможения
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		player.velocity.y = player.jump_force
		player.jump_time_remaining = player.max_jump_time
		state_machine.change_state("jump")
		return
	
	# Ориентация спрайта в направлении торможения (против движения)
	player.sprite.flip_h = player.skid_direction < 0
	player.update_collision_shapes()
