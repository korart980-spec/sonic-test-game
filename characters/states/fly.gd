extends State

# Настройки полета
var fly_max_speed: float = 300.0  # Базовая максимальная скорость
var fly_max_speed_boost: float = 1000.0  # Максимальная скорость с бустом
var fly_acceleration: float = 300.0  # Ускорение в полете
var fly_acceleration_boost: float = 1500.0  # Ускорение при бусте (рывок)
var fly_deceleration: float = 600.0  # Замедление в полете
var fly_gravity_scale: float = 0  # Очень слабая гравитация для парения

# Система кулдауна буста
var boost_cooldown_timer: float = 0.0
var BOOST_COOLDOWN: float = 1.0  # 1 секунда кулдауна
var can_boost: bool = true

func enter():
	player.target_animation = "fly"
	player.update_collision_shapes()
	
	# Включаем хитбокс для полета
	player.hitbox_roll.disabled = false
	player.set_collision_mask_value(3, false)
	
	# Инициализируем скорость для плавного начала
	player.velocity = player.velocity * 0.8
	can_boost = true
	boost_cooldown_timer = 0.0

func physics_update(delta: float):
	# Обновляем таймер кулдауна
	if boost_cooldown_timer > 0:
		boost_cooldown_timer -= delta
		if boost_cooldown_timer <= 0:
			can_boost = true
			boost_cooldown_timer = 0.0
			print("Буст готов к использованию!")
	
	# Получаем ввод по всем направлениям
	var input_vector = Vector2.ZERO
	
	# Горизонтальное управление
	if Input.is_action_pressed("right"):
		input_vector.x += 1
	if Input.is_action_pressed("left"):
		input_vector.x -= 1
	
	# Вертикальное управление
	if Input.is_action_pressed("look_up"):
		input_vector.y -= 1
	if Input.is_action_pressed("look_down"):
		input_vector.y += 1
	
	# Нормализуем вектор, если он не нулевой
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
		# Обновляем направление только если есть горизонтальный ввод
		if input_vector.x != 0:
			player.last_direction = sign(input_vector.x)
	
	# РЫВОК (BOOST) система с кулдауном
	if Input.is_action_just_pressed("boost") and can_boost and input_vector.length() > 0:
		# Применяем рывок (буст) в направлении ввода
		player.velocity = input_vector.normalized() * fly_max_speed_boost
		
		# Активируем кулдаун
		can_boost = false
		boost_cooldown_timer = BOOST_COOLDOWN
		
		# Визуальные и звуковые эффекты
		if player.has_method("apply_boost"):
			player.apply_boost()
		elif player.has_node("speed_chute_sound"):
			player.speed_chute_sound.play()
		
		print("БУСТ-РЫВОК! Направление: ", input_vector.normalized(), " | Кулдаун: 1 сек")
	
	# Вычисляем целевую скорость
	var target_velocity = Vector2.ZERO
	
	if input_vector.length() > 0:
		# Определяем максимальную скорость в зависимости от текущей скорости
		var current_max_speed = fly_max_speed
		
		# Если текущая скорость уже выше базовой (например, после буста), 
		# используем текущую скорость как максимальную для плавного движения
		if player.velocity.length() > fly_max_speed:
			current_max_speed = max(player.velocity.length(), fly_max_speed_boost)
		
		# Направление движения
		target_velocity = input_vector.normalized() * current_max_speed
	else:
		# Если нет ввода, плавно замедляемся
		target_velocity = Vector2.ZERO
	
	# ПЛАВНОЕ ДВИЖЕНИЕ
	
	# Горизонтальное движение
	if abs(target_velocity.x - player.velocity.x) > 1:
		# Определяем ускорение или замедление
		var accel_x = 0.0
		if abs(target_velocity.x) > abs(player.velocity.x) or sign(target_velocity.x) != sign(player.velocity.x):
			# Ускоряемся
			accel_x = fly_acceleration
		else:
			# Замедляемся
			accel_x = fly_deceleration
		
		# Применяем ускорение
		player.velocity.x = move_toward(player.velocity.x, target_velocity.x, accel_x * delta)
	else:
		player.velocity.x = target_velocity.x
	
	# Вертикальное движение (аналогично горизонтальному)
	if abs(target_velocity.y - player.velocity.y) > 1:
		# Определяем ускорение или замедление
		var accel_y = 0.0
		if abs(target_velocity.y) > abs(player.velocity.y) or sign(target_velocity.y) != sign(player.velocity.y):
			# Ускоряемся
			accel_y = fly_acceleration
		else:
			# Замедляемся
			accel_y = fly_deceleration
		
		# Применяем ускорение
		player.velocity.y = move_toward(player.velocity.y, target_velocity.y, accel_y * delta)
	else:
		player.velocity.y = target_velocity.y
	
	# ОЧЕНЬ СЛАБАЯ ГРАВИТАЦИЯ (только если нет вертикального ввода)
	if input_vector.y == 0:
		player.velocity.y += player.gravity * fly_gravity_scale * delta
	
	# Выход из полета
	if Input.is_action_just_pressed("ui_cancel"):
		exit_fly()
		return
	
	# Приземление
	if player.is_on_floor():
		handle_landing()
		return
	
	# Обновляем спрайт и коллизии
	player.sprite.flip_h = player.last_direction < 0
	player.update_collision_shapes()

func exit_fly():
	# Плавный выход из полета
	player.velocity.y = 0
	state_machine.change_state("jump")

func handle_landing():
	var current_speed = abs(player.velocity.x)
	
	if current_speed > 10:
		state_machine.change_state("run")
	else:
		state_machine.change_state("idle")
