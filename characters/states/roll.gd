extends State

var roll_speed_threshold: float = 200.0
var was_in_air: bool = false

func enter():
	if player.previous_state and player.previous_state.name.to_lower() == "spindash":
		player.spindash_roll_sound.play()
		player.spindash_charge_sound.stop()
	else:
		player.roll_sound.play()
	
	player.target_animation = "roll"
	player.update_collision_shapes()
	
	# Инициализируем отслеживание пребывания в воздухе
	was_in_air = not player.is_on_floor()

func physics_update(delta: float):
	# Применяем гравитацию
	player.velocity.y += player.gravity * delta
	
	# Проверяем переходы
	handle_state_transitions(delta)
	
	if Input.is_action_just_pressed("jump") and not player.is_on_floor():
		# Проверяем, что мы не в начале прыжка (чтобы избежать мгновенной активации)
		state_machine.change_state("fly")
		return
	
	# ЗАМЕДЛЕНИЕ - как в старом коде
	player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.5)
	
	player.sprite.flip_h = player.velocity.x < 0
	player.update_collision_shapes()

func handle_state_transitions(delta: float):
	# Проверка на приземление из воздуха
	if was_in_air and player.is_on_floor():
		# Если мы были в воздухе и теперь на земле - приземлились
		state_machine.change_state("run")
		return
	
	# Обновляем отслеживание пребывания в воздухе
	was_in_air = not player.is_on_floor()
	
	# Прыжок из качения
	if Input.is_action_just_pressed("jump") and player.is_on_floor():
		var jump_power = player.jump_force
		var speed = abs(player.velocity.x)
		
		if speed > roll_speed_threshold:
			jump_power *= 1.1
		
		player.velocity.y = jump_power
		player.jump_time_remaining = player.max_jump_time
		state_machine.change_state("jump")
		return
	
	# Переход в idle при замедлении ниже порога
	if abs(player.velocity.x) < 50 and player.is_on_floor():
		state_machine.change_state("idle")
		return
