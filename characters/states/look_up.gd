extends State

func enter():
	player.looked_up = false
	player.is_animation_finished = false
	player.target_animation = "look_up"
	player.update_collision_shapes()
	
	# Подписываемся на завершение анимации
	if player.animation_player.has_animation("look_up"):
		# Отключаем предыдущие подключения, чтобы избежать дублирования
		if player.animation_player.animation_finished.is_connected(_on_lookup_animation_finished):
			player.animation_player.animation_finished.disconnect(_on_lookup_animation_finished)
		player.animation_player.animation_finished.connect(_on_lookup_animation_finished)
	
	# Устанавливаем смещение камеры вверх с задержкой
	await get_tree().create_timer(2).timeout
	if state_machine.current_state == self:
		player.set_camera_offset(Vector2(0, -70))

func exit():
	player.looked_up = false
	player.is_animation_finished = false
	player.reset_camera_offset()
	
	# Отписываемся от сигнала
	if player.animation_player.has_animation("look_up"):
		player.animation_player.animation_finished.disconnect(_on_lookup_animation_finished)

func _on_lookup_animation_finished(anim_name: String):
	if anim_name == "look_up" and state_machine.current_state == self:
		player.looked_up = true
		player.is_animation_finished = true
		# Безопасная остановка анимации на последнем кадре
		if player.animation_player.has_animation("look_up"):
			var anim_length = player.animation_player.get_animation("look_up").length
			player.animation_player.stop(false)
			player.animation_player.seek(anim_length, true)

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	
	# Проверка на отрыв от земли
	if not player.is_on_floor():
		state_machine.change_state("jump")
		return

func handle_input():
	# Проверка отпускания кнопки поднятия головы
	if Input.is_action_just_released("look_up"):
		if abs(player.velocity.x) > 0:
			state_machine.change_state("run")
		else:
			state_machine.change_state("idle")
		return
