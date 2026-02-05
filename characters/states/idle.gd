extends State

func enter():
	player.jump_time_remaining = 0
	player.is_crouching = false
	player.target_animation = "idle"

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta)
	
	# Проверка на look_down в воздухе должна быть ПЕРВОЙ
	if Input.is_action_just_pressed("look_down") and not player.is_on_floor():
		print("Look_down нажат в воздухе - переходим в jump")
		state_machine.change_state("jump")
		return
	
	if not player.is_on_floor():
		return
	
	# Код ниже выполняется только если персонаж на земле
	var input_direction = player.get_input_direction()
	if input_direction != 0:
		state_machine.change_state("run")
		return
		
	if Input.is_action_just_pressed("jump"):
		player.velocity.y = player.jump_force
		player.jump_time_remaining = player.max_jump_time
		state_machine.change_state("jump")
		return
		
	# Переход в crouch только при УДЕРЖАНИИ look_down на земле
	if Input.is_action_pressed("look_down"):
		state_machine.change_state("crouch")
		return
		
	if Input.is_action_pressed("look_up"):
		state_machine.change_state("lookup")
		return
