extends State

var can_charge: bool = true
var charge_cooldown: float = 0.0
var is_launching: bool = false

func enter():
	player.spindash_charge_sound.play()
	player.spindash_charge_level = 0
	player.velocity.x = 0
	player.is_crouching = true
	can_charge = true
	is_launching = false
	
	player.target_animation = "spindash"
	player.update_collision_shapes()

func exit():
	player.spindash_charge_level = 0
	player.spindash_charge_sound.pitch_scale = 1.0
	player.spindash_charge_sound.stop()
	player.is_crouching = false

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	
	# Очень медленное замедление
	player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.1)
	
	# Проверка на отрыв от земли
	if not player.is_on_floor():
		state_machine.change_state("jump")
		return

func handle_input():
	if is_launching:
		return
	
	# Зарядка спиндаша - ВЫСШИЙ ПРИОРИТЕТ
	if Input.is_action_just_pressed("jump") and can_charge:
		charge_spindash()
		return
	
	# Запуск спиндаша - ИСПРАВЛЕННАЯ ЛОГИКА
	if Input.is_action_just_released("look_down") or (player.spindash_charge_level > 0 and not Input.is_action_pressed("look_down")):
		launch_spindash()
		return
	
	# Отмена спиндаша если отпустили приседание без заряда
	if not Input.is_action_pressed("look_down") and player.spindash_charge_level == 0:
		state_machine.change_state("crouch")
		return

func charge_spindash():
	if not can_charge:
		return
	
	player.spindash_charge_level = min(player.spindash_charge_level + 1, player.max_spindash_levels)
	
	player.animation_player.play("spindash")
	
	# Меняем высоту тона звука
	var pitch_levels = [1.0, 1.0, 1.1, 1.25, 1.4, 1.6]
	if player.spindash_charge_level < pitch_levels.size():
		player.spindash_charge_sound.pitch_scale = pitch_levels[player.spindash_charge_level]
	else:
		player.spindash_charge_sound.pitch_scale = pitch_levels[-1]
	
	player.spindash_charge_sound.play()
	
	# Короткая блокировка следующего заряда
	can_charge = false
	await get_tree().create_timer(charge_cooldown).timeout
	can_charge = true

func launch_spindash():
	if is_launching:
		return
		
	is_launching = true
	
	# Минимальный заряд если не заряжали
	if player.spindash_charge_level == 0:
		player.spindash_charge_level = 1
	
	var launch_power = player.base_spindash_speed + (player.spindash_charge_level * player.spindash_speed_per_level)
	player.velocity.x = player.last_direction * launch_power
	
	# Немедленный переход в roll
	state_machine.change_state("roll")
