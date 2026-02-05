extends State

func enter():
	player.is_crouching = true
	player.crouched = false
	player.is_animation_finished = false
	player.velocity.x = move_toward(player.velocity.x, 0, player.braking_deceleration * get_physics_process_delta_time())
	player.target_animation = "crouch"
	player.update_collision_shapes()
	
	# Подписываемся на завершение анимации
	if player.animation_player.has_animation("crouch"):
		# Отключаем предыдущие подключения, чтобы избежать дублирования
		if player.animation_player.animation_finished.is_connected(_on_crouch_animation_finished):
			player.animation_player.animation_finished.disconnect(_on_crouch_animation_finished)
		player.animation_player.animation_finished.connect(_on_crouch_animation_finished)
	
	# Устанавливаем смещение камеры вниз с задержкой
	await get_tree().create_timer(2).timeout
	if state_machine.current_state == self:
		player.set_camera_offset(Vector2(0, 70))

func exit():
	player.is_crouching = false
	player.crouched = false
	player.is_animation_finished = false
	player.reset_camera_offset()
	
	# Отписываемся от сигнала
	if player.animation_player.has_animation("crouch"):
		player.animation_player.animation_finished.disconnect(_on_crouch_animation_finished)

func _on_crouch_animation_finished(anim_name: String):
	if anim_name == "crouch" and state_machine.current_state == self:
		player.crouched = true
		player.is_animation_finished = true
		# Безопасная остановка анимации на последнем кадре
		if player.animation_player.has_animation("crouch"):
			var anim_length = player.animation_player.get_animation("crouch").length
			player.animation_player.stop(false)
			player.animation_player.seek(anim_length, true)

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	player.velocity.x = move_toward(player.velocity.x, 0, player.braking_deceleration * delta)
	
	# Проверка на отрыв от земли
	if not player.is_on_floor():
		state_machine.change_state("jump")
		return

func handle_input():
	# ВАЖНО: спиндаш должен иметь ВЫСШИЙ ПРИОРИТЕТ
	if Input.is_action_just_pressed("jump"):
		if player.request_state_change("spindash", true):
			return
	
	# Проверка отпускания кнопки приседания
	if Input.is_action_just_released("look_down"):
		if abs(player.velocity.x) > 0:
			state_machine.change_state("run")
		else:
			state_machine.change_state("idle")
		return
