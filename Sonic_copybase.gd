extends CharacterBody2D

# ===== СОСТОЯНИЯ (STATE) =====
enum State { IDLE, WALK, RUN, JUMP, ROLL, SPINDASH, CROUCH, HURT, SKID, DEAD }
var current_state: State = State.IDLE
var previous_state: State

# ===== ЭКСПОРТИРУЕМЫЕ ПАРАМЕТРЫ =====
@export_category("Movement Properties")
@export var max_speed: float = 450.0
@export var acceleration: float = 400.0
@export var deceleration: float = 400.0
@export var braking_deceleration: float = 1200.0  # Более быстрое торможение при смене направления

@export_category("Ring Properties")
@export var max_rings: int = 999
@export var ring_scatter_force: float = 300.0
@export var ring_scatter_count: int = 50
@export var invulnerability_time: float = 1.5

@export_category("Player Properties")
@export var max_lives: int = 3
var lives: int = max_lives

var rings: int = 0
var is_invulnerable: bool = false
var invulnerability_timer: Timer

@export_category("Jump Properties")
@export var jump_force: float = -420.0
@export var max_jump_time: float = 0.3
@export var gravity: float = 1000.0

@export_category("Ring Loss Settings")
@export var max_scattered_rings: int = 40  # Максимум разбрасываемых колец
@export var lose_all_rings: bool = true    # true = терять все, false = терять до лимита

@export_category("Spindash Properties")
@export var base_spindash_speed: float = 300.0
@export var spindash_speed_per_level: float = 120.0
@export var max_spindash_levels: int = 5

# Айди персонажа
@export var character_id: String = "sonic" # Уникальный ID для каждого персонажа

# ===== ВНУТРЕННИЕ ПЕРЕМЕННЫЕ =====
var last_direction: int = 1
var jump_time_remaining: float = 0.0

var spindash_charge_level: int = 0

var is_crouching: bool = false

var skid_direction: int = 0  # Направление, в котором произошло торможение
var min_skid_speed: float = 200.0  # Минимальная скорость для активации торможения

# Для анимаций
var current_animation: String = ""
var target_animation: String = ""
var animation_transition_speed: float = 10.0
var animation_blend: float = 0.0

# Для звуковых эффектов
@onready var jump_sound = $Jump_sound
@onready var spindash_roll_sound = $spindash_roll_sound
@onready var spindash_charge_sound = $spindash_charge_sound
@onready var roll_sound = $roll_sound
@onready var skid_sound = $skid_sound


# для коллизии
var was_on_floor: bool = false

# ===== ССЫЛКИ НОД =====
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_stand = $Hitbox_Stand
@onready var hitbox_stand_left = $Hitbox_standLeft
@onready var hitbox_roll = $Hitbox_roll

# Добавим переменные для системы смерти
var is_dead: bool = false
var death_velocity: Vector2 = Vector2.ZERO
var camera_initial_position: Vector2 = Vector2.ZERO
signal show_game_over()


# Для счетчиков на экране
signal rings_changed(rings_count)

# ===== ФУНКЦИИ ОСНОВНОГО ЦИКЛА =====
func _ready():
	change_state(State.IDLE)
	add_to_group("player")
	
	# Таймер неуязвимости
	invulnerability_timer = Timer.new()
	add_child(invulnerability_timer)
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	
	# Инициализируем жизни
	lives = max_lives

func _physics_process(delta):
	if current_state == State.HURT:
		physics_hurt(delta)  # Используем отдельную функцию для физики
		move_and_slide()
		return
	if current_state == State.DEAD:
		physics_dead(delta)
		return
	
	match current_state:
		State.IDLE:
			physics_idle(delta)
		State.RUN:
			physics_run(delta)
		State.JUMP:
			physics_jump(delta)
		State.ROLL:
			physics_roll(delta)
		State.SPINDASH:
			physics_spindash(delta)
		State.CROUCH:
			physics_crouch(delta)
		State.HURT:
			physics_hurt(delta)
		State.SKID:  
			physics_skid(delta)
	
	was_on_floor = is_on_floor()
	
	update_collision_shapes()
	
	handle_animations(delta)
	
	move_and_slide()
	

func handle_hazard_collision(hazard):
	if is_invulnerable:
		return
		
	# Проверяем, является ли hazard врагом
	if hazard.is_in_group("enemies"):
		# Дополнительная логика для врагов
		pass
		
	# Остальная логика обработки урона
	if rings > 0:
		var rings_to_lose = min(rings, 10)
		lose_rings(rings_to_lose)
	else:
		take_damage()

func update_collision_shapes():
# Сначала отключаем все хитбоксы
	hitbox_stand.disabled = true
	hitbox_stand_left.disabled = true
	hitbox_roll.disabled = true

# Включаем нужный хитбокс в зависимости от состояния и направления
	match current_state:
		State.JUMP, State.ROLL:
			hitbox_roll.disabled = false
		_:
			if sprite.flip_h:  # Если смотрит влево
				hitbox_stand_left.disabled = false
			else:  # Если смотрит вправо
				hitbox_stand.disabled = false
			# Включаем коллизию с one-way платформами
				set_collision_mask_value(3, true)
		_:
			# Отключаем коллизию с one-way платформами
			set_collision_mask_value(3, false)



# ===== ФУНКЦИЯ СМЕНЫ СОСТОЯНИЯ =====
func change_state(new_state: State):
	
	var old_state = current_state
	# Выходные процедуры для текущего состояния
	match current_state:
		State.SPINDASH:
			spindash_charge_level = 0
			spindash_charge_sound.pitch_scale = 1.0
		State.HURT:
			pass
	
	# Входные процедуры для нового состояния
	match new_state:
		State.IDLE:
			jump_time_remaining = 0
			is_crouching = false
		State.CROUCH:
			is_crouching = true
			velocity.x = move_toward(velocity.x, 0, braking_deceleration * get_physics_process_delta_time())
		State.SPINDASH:
			spindash_charge_sound.play()
			spindash_charge_level = 0
			velocity.x = 0
		State.JUMP:
			if was_on_floor:  # Только если прыжок с земли
				jump_sound.play()
				#$CollisionShape2D.scale = Vector2(normal_collision_scale.x, normal_collision_scale.y * 0.6)
		State.ROLL:
			if old_state == State.SPINDASH:
				spindash_roll_sound.play()  # Звук выстрела спиндаша
				spindash_charge_sound.pitch_scale = 1.0
				#$CollisionShape2D.scale = Vector2(normal_collision_scale.x, normal_collision_scale.y * 0.6)
			else:
				roll_sound.play()
				#$CollisionShape2D.scale = Vector2(normal_collision_scale.x, normal_collision_scale.y * 0.6)
		State.SKID:
			skid_sound.play()
		State.HURT:
			# Останавливаем другие звуки если нужно
			pass
				
	
	previous_state = current_state  # ← previous_state теперь будет правильным
	current_state = new_state
	update_collision_shapes()
	
	
func apply_boost(speed: float):
		velocity.x = last_direction * speed

func die():
	if is_dead:
		return
	
	is_dead = true
	change_state(State.DEAD)
	
	
	# Проигрываем звук смерти
	$death_sound.play()
	
	# Отключаем все коллизии
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	$Hitbox_roll.disabled = true
	$Hitbox_standLeft.disabled = true
	$Hitbox_Stand.disabled = true
	
	# Задаем velocity для смерти - подбрасываем вверх
	death_velocity = Vector2(0, -600)
	velocity = death_velocity
	
	
	# Ждем завершения анимации смерти (2-3 секунды)
	await get_tree().create_timer(2.5).timeout
	
	# После анимации смерти показываем соответствующий экран
	if lives <= 0:
		emit_signal("show_game_over")
	else:
		emit_signal("show_retry_screen")
		
func physics_dead(delta):
	# Применяем гравитацию
	death_velocity.y += gravity * delta
	velocity = death_velocity
	
	# Двигаем персонажа
	move_and_slide()
	animation_player.play("dead")
	# Вращаем персонажа при падении
	#sprite.rotation_degrees += velocity.y * delta * 0.1

func _on_death_timeout():
	if lives <= 0:
		# Game Over - полная перезагрузка игры
		get_tree().change_scene_to_file("res://ui/game_over_screen.tscn")
	else:
		# Перезагрузка уровня с сохранением количества жизней
		get_tree().reload_current_scene()

func stop_all_sounds():
	jump_sound.stop()
	spindash_roll_sound.stop()
	spindash_charge_sound.stop()
	roll_sound.stop()
	skid_sound.stop()

func handle_animations(delta):
	# Определяем целевую анимацию на основе состояния и скорости
	var speed = abs(velocity.x)
	var walk_threshold = max_speed * 0.3
	var run_threshold = max_speed * 0.8
	if current_state == State.IDLE:
		target_animation = "idle"
	elif current_state == State.RUN:
		if speed < walk_threshold:
			target_animation = "walk"
			animation_player.speed_scale = 0.7
		elif speed < run_threshold:
			target_animation = "walk"
			animation_player.speed_scale = 1.5 + (speed - walk_threshold) / (run_threshold - walk_threshold) * 0.5
		else:
			target_animation = "run"
			animation_player.speed_scale = 2 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
	elif current_state == State.JUMP:
		target_animation = "jump"
		animation_player.speed_scale = 3 + (speed - walk_threshold) / (run_threshold - walk_threshold) * 0.5
	elif current_state == State.CROUCH:
		target_animation = "crouch2"
	elif current_state == State.SPINDASH:
		target_animation = "spindash"
	elif current_state == State.ROLL:
		if speed < walk_threshold:
			target_animation = "roll"
			animation_player.speed_scale = 3 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
		elif speed < run_threshold:
			target_animation = "roll"
			animation_player.speed_scale = 5 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
		else:
			target_animation = "roll"
			animation_player.speed_scale = 7 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
	elif current_state == State.SKID:  # Добавляем анимацию торможения
		target_animation = "skid"
	elif current_state == State.HURT:
		target_animation = "hurt"
	elif current_state == State.DEAD:
		target_animation = "dead"
		
	# Плавный переход между анимациями
	if target_animation != current_animation:
		animation_blend += animation_transition_speed * delta
		if animation_blend >= 1.0:
			animation_blend = 1.0
			animation_player.play(target_animation)
			current_animation = target_animation
		#else:
		# Здесь можно добавить cross-fade между анимациями, если нужно
	if animation_player.current_animation != target_animation:
		animation_player.play(target_animation)
		animation_player.seek(animation_player.current_animation_length * animation_blend, true)
	else:
		animation_blend = 0.0

# ===== ФУНКЦИИ КОНКРЕТНЫХ СОСТОЯНИЙ =====
func physics_idle(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, deceleration * delta)
	
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.5)
		return
	
	var input_direction = get_input_direction()
	if input_direction != 0:
		change_state(State.RUN)
		return
		
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		jump_time_remaining = max_jump_time
		change_state(State.JUMP)
		return
		
	if Input.is_action_pressed("look_down"):
		change_state(State.CROUCH)
		return
	
	animation_player.play("idle")



func physics_skid(delta):
	velocity.y += gravity * delta
	
	# Сохраняем направление торможения
	if skid_direction == 0:
		skid_direction = sign(velocity.x)
	
	# Сильное замедление во время торможения
	velocity.x = move_toward(velocity.x, 0, braking_deceleration * delta * 1.5)
	
	var input_direction = get_input_direction()
	
	# Если игрок отпустил клавиши или изменил направление
	if input_direction == 0 or sign(velocity.x) == input_direction:
		# Выходим из состояния торможения
		if abs(velocity.x) < 50:
			change_state(State.IDLE)
		else:
			change_state(State.RUN)
		skid_direction = 0
		return
	
	# Если продолжаем удерживать направление, противоположное движению
	if input_direction != 0 and sign(velocity.x) != input_direction:
		# Продолжаем торможение
		pass
	
	# Проверяем, не остановились ли мы полностью
	if abs(velocity.x) < 10:
		change_state(State.IDLE)
		skid_direction = 0
		return
	
	# Проверяем возможность прыжка во время торможения
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		jump_time_remaining = max_jump_time
		change_state(State.JUMP)
		skid_direction = 0
		return
	
	# Ориентация спрайта в направлении торможения (против движения)
	sprite.flip_h = skid_direction < 0
	update_collision_shapes()



func physics_run(delta):
	velocity.y += gravity * delta
	
	var input_direction = get_input_direction()
	var speed = abs(velocity.x)
	
	# Проверка условия для торможения
	if (input_direction != 0 and 
		sign(velocity.x) != input_direction and 
		speed > min_skid_speed and 
		is_on_floor()):
		change_state(State.SKID)
		return
	
	if input_direction != 0:
		last_direction = input_direction
		
		# УМНОЕ ОГРАНИЧЕНИЕ: определяем целевую скорость
		var target_speed = input_direction * max_speed
		
		# Определяем, нужно ли торможение при смене направления
		if sign(velocity.x) != 0 and sign(velocity.x) != input_direction:
			# Торможение при смене направления
			velocity.x = move_toward(velocity.x, target_speed, braking_deceleration * delta)
		else:
			# Обычное ускорение, но не превышаем max_speed при самостоятельном разгоне
			if abs(velocity.x) < max_speed or sign(velocity.x) != input_direction:
				velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
			# Если уже едем быстрее max_speed (от спиндаша), сохраняем скорость
	else:
		# Замедление при отпускании клавиш
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)
		if abs(velocity.x) < 10:
			change_state(State.IDLE)
			return

	# Переход в IDLE только при полной остановке
		if abs(velocity.x) < 10:
			change_state(State.IDLE)
			return
	
	if speed > 1:
		if is_on_floor and Input.is_action_just_pressed("look_down"):
			change_state(State.ROLL)
			return
	
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.5)
		return
	
	if Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		jump_time_remaining = max_jump_time
		change_state(State.JUMP)
		return
		
	if Input.is_action_pressed("look_down") and abs(velocity.x) < 50:
		change_state(State.CROUCH)
		return

	sprite.flip_h = last_direction < 0
	update_collision_shapes()



func physics_jump(delta):
	if jump_time_remaining > 0 and Input.is_action_pressed("jump"):
		velocity.y += gravity * 0.45 * delta
		jump_time_remaining -= delta
	else:
		jump_time_remaining = 0
		velocity.y += gravity * delta
	
	var input_direction = get_input_direction()
	var speed = abs(velocity.x)
	
	if input_direction != 0:
		last_direction = input_direction
		velocity.x = move_toward(velocity.x, input_direction * max_speed, acceleration * delta * 0.4)
		
		var is_braking = sign(velocity.x) != 0 and sign(velocity.x) != input_direction
		if is_braking:
			velocity.x = move_toward(velocity.x, input_direction * max_speed, braking_deceleration * delta * 0.5)
		else:
			velocity.x = move_toward(velocity.x, input_direction * max_speed, acceleration * delta * 0.4)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.1)
	
	if is_on_floor():
		if speed > 1 and Input.is_action_pressed("look_down"):
			change_state(State.ROLL)
			return

	if is_on_floor():
		if abs(velocity.x) > 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
		return
	
	sprite.flip_h = last_direction < 0
	update_collision_shapes()



func physics_crouch(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, braking_deceleration * delta)
	
	if not Input.is_action_pressed("look_down"):
		if abs(velocity.x) > 0:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
		return
		
	if Input.is_action_just_pressed("jump"):
		change_state(State.SPINDASH)
		return
	


func physics_spindash(delta):
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.2)
	
	if not is_on_floor():
		change_state(State.JUMP)
		return
	
	if not Input.is_action_pressed("look_down"):
		var launch_power = base_spindash_speed + (spindash_charge_level * spindash_speed_per_level)
		velocity.x = last_direction * launch_power
		change_state(State.ROLL)
		return
	
	if Input.is_action_just_pressed("jump"):
		spindash_charge_level = min(spindash_charge_level + 1, max_spindash_levels)
		if animation_player.is_playing():
			animation_player.stop()
		animation_player.play("spindash")
		var pitch_levels = [1.0, 1.1, 1.25, 1.4, 1.6]
		if spindash_charge_level < pitch_levels.size():
			spindash_charge_sound.pitch_scale = pitch_levels[spindash_charge_level]
		else:
			spindash_charge_sound.pitch_scale = pitch_levels[-1]
		spindash_charge_sound.play()
	update_collision_shapes()



func physics_roll(delta):
	var old_state = current_state
	velocity.y += gravity * delta
	velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.5)
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		jump_time_remaining = max_jump_time
		change_state(State.JUMP)
		return
		
		
	if abs(velocity.x) < 50:
		change_state(State.IDLE)
		return
	
	
	animation_player.play("roll")
	sprite.flip_h = velocity.x < 0
	update_collision_shapes()



func physics_hurt(delta):
	velocity.y += gravity * delta
	# Медленнее замедляемся в воздухе
	if not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.2)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta * 0.5)
	
	# Выходим из состояния HURT когда почти остановились
	if is_on_floor() and abs(velocity.x) < 50:
		if abs(velocity.x) > 10:
			change_state(State.RUN)
		else:
			change_state(State.IDLE)
	
	animation_player.play("hurt")

# ===== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ =====
func get_input_direction() -> int:
	var direction = 0
	if Input.is_action_pressed("right"):
		direction += 1
	if Input.is_action_pressed("left"):
		direction -= 1
	return direction


func add_ring():
	rings = min(rings + 1, max_rings)
	print("Колец собрано: ", rings)
	emit_signal("rings_changed", rings) 
	
func get_rings() -> int:
	return rings
	
func take_damage():
	if is_invulnerable or is_dead:
		return
		
	print("Получен урон! Колец нет.")
	
	is_dead = true
	change_state(State.DEAD)
	
	# Отключаем коллизии и управление
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	$Hitbox_roll.disabled = true
	$Hitbox_Stand.disabled = true
	$Hitbox_standLeft.disabled = true
	set_process_input(false)
	
	# Подбрасываем вверх
	death_velocity = Vector2(0, -600)
	velocity = death_velocity
	
	# Фиксируем камеру на текущей позиции
	if has_node("Camera2D"):
		var camera = $Camera2D
		camera_initial_position = camera.global_position
		# Делаем камеру независимой от игрока
		remove_child(camera)
		get_parent().add_child(camera)
		camera.global_position = camera_initial_position
	
	# Ждем падения и переходим на экран
	await get_tree().create_timer(2.0).timeout
	
	# Переходим на экран RetryScreen
	get_tree().change_scene_to_file("res://screens/retry_screen.tscn")
	


func game_over():
	print("Game Over! Перезапуск уровня...")
	# Перезагружаем текущую сцену
	get_tree().reload_current_scene()

func lose_rings(amount: int):
	var rings_to_lose: int
	var rings_to_scatter: int
	
	if lose_all_rings:
		# Режим "терять все кольца"
		rings_to_lose = rings
		rings_to_scatter = min(rings, max_scattered_rings)  # Но разбрасываем до лимита
	else:
		# Режим "терять до лимита" (классический Sonic)
		rings_to_lose = min(amount, max_scattered_rings)
		rings_to_scatter = rings_to_lose
	
	rings = max(rings - rings_to_lose, 0)
	print("Потеряно: ", rings_to_lose, " колец | Разбрасываем: ", rings_to_scatter)
	emit_signal("rings_changed", rings) 
	
	# Остальной код без изменений...
	is_invulnerable = true
	invulnerability_timer.start(invulnerability_time)
	
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.3, 0.1)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.1)
	tween.set_loops(5)
	
	scatter_rings(rings_to_scatter)
	
	change_state(State.HURT)
	velocity.y = -200
	velocity.x = -last_direction * 150
func scatter_rings(amount: int):
	print("Разбрасываем ", amount, " колец")
	if amount <= 0:
		return
		
	var scattered_coin_scene = preload("res://objects/scattered_coin.tscn")
	$scatter_rings_sound.play()
	# Определяем, в какую сторону делать акцент
	var accent_direction = 1 if randf() > 0.5 else -1
	
	# Для нечетного количества (включая 1) - акцент на одну сторону
	if amount == 1:
		var coin = scattered_coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = global_position
		
		# Бросаем в случайную сторону с небольшим подъемом
		var random_side = 1 if randf() > 0.5 else -1
		var direction = Vector2(random_side, -1.5).normalized()
		var force = randf_range(300.0, 400.0)
		
		coin.velocity = direction * force
	elif amount % 2 == 1:
		for i in range(amount):
			var coin = scattered_coin_scene.instantiate()
			get_parent().add_child(coin)
			coin.global_position = global_position
			
			# Смещаем центр веера в сторону акцента
			var spread_angle = 120.0
			var angle_degrees = (i / float(amount - 1)) * spread_angle - (spread_angle / 2.0) + (accent_direction * 30.0)
			var angle_radians = deg_to_rad(angle_degrees)
			
			# Базовое направление - вверх
			var base_direction = Vector2(0, -1).normalized()
			var direction = base_direction.rotated(angle_radians)
			
			var force = randf_range(300.0, 400.0)
			coin.velocity = direction * force
	else:
		# Для четного количества - симметричный веер
		var spread_angle = 160.0
		
		for i in range(amount):
			var coin = scattered_coin_scene.instantiate()
			get_parent().add_child(coin)
			coin.global_position = global_position
			
			# Равномерное распределение по дуге
			var angle_degrees = (i / float(amount - 1)) * spread_angle - (spread_angle / 2.0)
			var angle_radians = deg_to_rad(angle_degrees)
			
			var base_direction = Vector2(0, -1).normalized()
			var direction = base_direction.rotated(angle_radians)
			
			var force = randf_range(300.0, 400.0)
			coin.velocity = direction * force

func _on_body_entered(body):
	if body.is_in_group("rings") and current_state != State.HURT and not is_invulnerable:
		body.collect(self)
		
func _on_invulnerability_timeout():
	is_invulnerable = false
	sprite.modulate.a = 1.0
	
	# Останавливаем все твины мигания
	var tweens = get_tree().get_nodes_in_group("invulnerability_tween")
	for tween in tweens:
		tween.kill()
