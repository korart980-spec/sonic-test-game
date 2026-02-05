extends CharacterBody2D
class_name PlayerBase

# сигналы
signal rings_changed(rings_count)
signal show_game_over()
signal show_retry_screen()

# Character configuration - будет переопределяться в дочерних сценах
var character_name: String = "sonic"
var can_boost: bool = false
var can_fly: bool = false
var can_spindash: bool = true
var can_roll: bool = true
var is_boosting: bool = false

# Экспортируемые параметры
@export_category("Movement Properties")
@export var max_speed: float = 450.0
@export var acceleration: float = 400.0
@export var deceleration: float = 400.0
@export var braking_deceleration: float = 1200.0

@export_category("Jump Properties")
@export var jump_force: float = -420.0
@export var max_jump_time: float = 0.3
@export var gravity: float = 1000.0

@export_category("Emotion Properties")
@export var can_use_emotions: bool = false

@export_category("Fly Properties")
@export var max_fly_time: float = 5.0
@export var fly_boost_power: float = 300.0
@export var fly_drop_power: float = 400.0

@export_category("Boost Properties")
@export var boost_speed: float = 600.0
@export var boost_cooldown: float = 2.5

@export_category("Ring Properties")
@export var max_rings: int = 999
@export var ring_scatter_force: float = 300.0
@export var ring_scatter_count: int = 50
@export var invulnerability_time: float = 1.5

@export_category("Player Properties")
@export var max_lives: int = 3
var lives: int = max_lives

@export_category("Ring Loss Settings")
@export var max_scattered_rings: int = 40
@export var lose_all_rings: bool = true

@export_category("Spindash Properties")
@export var base_spindash_speed: float = 300.0
@export var spindash_speed_per_level: float = 120.0
@export var max_spindash_levels: int = 5

@export_category("Hurt Properties")
@export var hurt_bounce_velocity_y: float = -370
@export var hurt_bounce_velocity_x: float = 180

@export_category("Trail Properties")
@export var enable_trail: bool = true
@export var trail_speed_threshold: float = 700  # Минимальная скорость для активации шлейфа
@export var trail_spawn_interval: float = 0.03  # Интервал между созданиями послеобразов
@export var trail_fade_time: float = 0.3  # Время затухания послеобраза
@export var trail_max_count: int = 10  # Максимальное количество послеобразов
@export var trail_color: Color = Color(0.5, 0.8, 1.0, 0.6)  # Цвет шлейфа

# ===== ВНУТРЕННИЕ ПЕРЕМЕННЫЕ =====

# Основные переменные движения
var last_direction: int = 1
var jump_time_remaining: float = 0.0
var spindash_charge_level: int = 0
var is_crouching: bool = false
var skid_direction: int = 0
var min_skid_speed: float = 200.0

# Состояния игрока
var is_invulnerable: bool = false
var is_dead: bool = false
var was_on_floor: bool = false
var death_timer: float = 0.0
var death_duration: float = 2.5
var death_velocity: Vector2 = Vector2.ZERO

# Анимации
var current_animation: String = ""
var target_animation: String = ""
var animation_transition_speed: float = 10.0
var animation_blend: float = 0.0
var is_animation_finished: bool = false
var crouched: bool = false
var looked_up: bool = false

# эмоции
var is_emoting: bool = false
# Система колец
var rings: int = 0
var invulnerability_timer: Timer

# Система шлейфа
var trail_timer_value: float = 0.0
var trail_instances: Array = []  # Массив активных послеобразов
var trail_material: ShaderMaterial
var time_since_last_trail: float = 0.0  # Таймер для создания послеобразов

# ===== КРИВОЛИНЕЙНОЕ ДВИЖЕНИЕ =====
var current_surface_angle: float = 0.0
var target_rotation: float = 0.0
var is_in_loop: bool = false
var loop_progress: float = 0.0
var curve_rotation_speed: float = 5.0
var max_bank_angle: float = 30.0
var loop_gravity_scale: float = 1.5

# Управление состояниями
var previous_state: State
var pending_state: String = ""
var state_change_cooldown: float = 0.0
var state_priority: Dictionary = {
	"dead": 100,
	"hurt": 90,
	"spindash": 80,
	"jump": 70,
	"roll": 60,
	"skid": 50,
	"crouch": 40,
	"look_up": 35,
	"run": 30,
	"idle": 20
}

# Boost система
var can_boost_current: bool = true
var boost_cooldown_timer: float = 0.0

var is_trail_active: bool = false
var trail_timer: Timer
var max_trail_segments: int = 8
var trail_segment_lifetime: float = 0.15
var trail_width: float = 1.0
var trail_fade_speed: float = 5.0

# Камера
var camera_offset_target: Vector2 = Vector2.ZERO
var camera_offset_current: Vector2 = Vector2.ZERO
var camera_offset_speed: float = 3.0 
var camera_offset_amount: float = 80.0 
var camera_locked: bool = false

# ===== ССЫЛКИ НОД =====
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var state_machine: StateMachine = $StateMachine
@onready var hitbox_stand = $Hitbox_Stand
@onready var hitbox_stand_left = $Hitbox_standLeft
@onready var hitbox_roll = $Hitbox_roll
@onready var camera = $Camera2D
@onready var front_detector = $FrontSurfaceDetector
@onready var rear_detector = $RearSurfaceDetector

# Звуковые эффекты
@onready var jump_sound = $Jump_sound
@onready var spindash_roll_sound = $spindash_roll_sound
@onready var spindash_charge_sound = $spindash_charge_sound
@onready var roll_sound = $roll_sound
@onready var skid_sound = $skid_sound
@onready var speed_chute_sound = $speed_chute_sound

func _ready() -> void:
	add_to_group("player")
	lives = max_lives
	
	# Создаем материал для шлейфа
	create_trail_material()
	
	# Trail таймер
	trail_timer = Timer.new()
	trail_timer.one_shot = true
	
	# Таймер неуязвимости
	invulnerability_timer = Timer.new()
	add_child(invulnerability_timer)
	invulnerability_timer.timeout.connect(_on_invulnerability_timeout)
	
	if front_detector and rear_detector:
		front_detector.detection_range = 80.0
		rear_detector.detection_range = 80.0
	
	# Инициализация камеры
	if has_node("Camera2D"):
		camera = $Camera2D
	
	# Initialize boost based on character ability
	can_boost_current = can_boost

func _physics_process(delta: float) -> void:
	# Обработка кулдауна boost
	if can_boost and boost_cooldown_timer > 0:
		boost_cooldown_timer -= delta
		if boost_cooldown_timer <= 0:
			can_boost_current = true
			boost_cooldown_timer = 0
	
	# Обработка кулдауна смены состояний
	if state_change_cooldown > 0:
		state_change_cooldown -= delta
	
	# Применяем отложенную смену состояния после кулдауна
	if pending_state != "" and state_change_cooldown <= 0:
		state_machine.change_state(pending_state)
		pending_state = ""
	
	if state_machine:
		state_machine.physics_update(delta)
	
	update_surface_detection()
	
	# Обработка шлейфа
	handle_trail(delta)
	
	was_on_floor = is_on_floor()
	handle_animations(delta)
	move_and_slide()

	if camera and not camera_locked:
		var offset_diff = camera_offset_target - camera_offset_current
		if offset_diff.length() > 0.1:
			camera_offset_current += offset_diff.normalized() * min(offset_diff.length(), camera_offset_speed)
		else:
			camera_offset_current = camera_offset_target
		
		camera.position = camera_offset_current
	
	# Удаляем старые послеобразы
	cleanup_trail_instances()
	
func _process(delta: float) -> void:
	if state_machine:
		state_machine.update(delta)

func _input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input()

func _on_invulnerability_timeout():
	is_invulnerable = false
	if sprite:
		sprite.modulate.a = 1.0

# ===== СИСТЕМА ШЛЕЙФА (TRAIL) =====

func create_trail_material():
	if not sprite:
		return
	
	# Создаем шейдерный материал для эффекта послеобраза
	trail_material = ShaderMaterial.new()
	trail_material.shader = Shader.new()
	trail_material.shader.code = """
	shader_type canvas_item;

	uniform vec4 trail_color : source_color = vec4(0.5, 0.8, 1.0, 0.6);

	void fragment() {
		vec4 tex_color = texture(TEXTURE, UV);
		COLOR = tex_color * trail_color;
	}
	"""
	trail_material.set_shader_parameter("trail_color", trail_color)

func handle_trail(delta: float):
	if not enable_trail:
		return
	
	# Проверяем, достигнута ли скорость порога
	var current_speed = velocity.length()
	
	# Отладка скорости (можно временно включить)
	# if Engine.get_frames_drawn() % 60 == 0:  # Каждую секунду
	#     print("Скорость: ", current_speed, " / ", trail_speed_threshold)
	
	if current_speed >= trail_speed_threshold:
		# Таймер для создания новых послеобразов
		time_since_last_trail += delta
		
		if time_since_last_trail >= trail_spawn_interval:
			time_since_last_trail = 0.0
			spawn_trail_instance()
	else:
		# Если скорость ниже порога, не создаем новые шлейфы
		pass


# Добавьте метод для копирования спрайта:
func copy_sprite_properties(from_sprite: Sprite2D, to_sprite: Sprite2D) -> void:
	# Копируем текстуру
	to_sprite.texture = from_sprite.texture
	
	# Копируем свойства региона (для sprite sheets)
	if from_sprite.region_enabled:
		to_sprite.region_enabled = true
		to_sprite.region_rect = from_sprite.region_rect
	else:
		to_sprite.region_enabled = false
	
	# Копируем настройки анимации
	to_sprite.hframes = from_sprite.hframes
	to_sprite.vframes = from_sprite.vframes
	to_sprite.frame = from_sprite.frame
	
	# Копируем трансформации
	to_sprite.flip_h = from_sprite.flip_h
	to_sprite.flip_v = from_sprite.flip_v
	to_sprite.scale = from_sprite.scale
	to_sprite.rotation = from_sprite.rotation
	to_sprite.offset = from_sprite.offset
	
	# Копируем настройки фильтрации
	to_sprite.texture_filter = from_sprite.texture_filter
	
	# Копируем модуляцию цвета
	to_sprite.modulate = from_sprite.modulate

# Тогда обновите spawn_trail_instance():

func debug_trail_info():
	print("=== ДЕБАГ ШЛЕЙФА ===")
	print("Скорость: ", velocity.length())
	print("Порог шлейфа: ", trail_speed_threshold)
	print("Включен ли шлейф: ", enable_trail)
	print("Активные послеобразы: ", trail_instances.size())
	print("Таймер создания: ", time_since_last_trail)
	print("Спрайт видим: ", sprite.visible)
	print("Спрайт текстура: ", sprite.texture)
	print("Спрайт region_enabled: ", sprite.region_enabled)
	if sprite.region_enabled:
		print("Спрайт region_rect: ", sprite.region_rect)
	print("==================")

# Обновите метод spawn_trail_instance - УПРОЩЕННАЯ РАБОЧАЯ ВЕРСИЯ:
func spawn_trail_instance():
	if not sprite or not is_instance_valid(sprite):
		return
	
	# Создаем новый послеобраз
	var trail_instance = Sprite2D.new()
	
	# 1. Копируем текстуру и свойства
	trail_instance.texture = sprite.texture
	
	# 2. Копируем region если используется
	if sprite.region_enabled:
		trail_instance.region_enabled = true
		trail_instance.region_rect = sprite.region_rect
	else:
		trail_instance.hframes = sprite.hframes
		trail_instance.vframes = sprite.vframes
		trail_instance.frame = sprite.frame
	
	# 3. Копируем трансформации (БЕЗ ИЗМЕНЕНИЯ РАЗМЕРА)
	trail_instance.flip_h = sprite.flip_h
	trail_instance.scale = sprite.scale  # ИСПОЛЬЗУЕМ ТОЧНО ТАКОЙ ЖЕ РАЗМЕР
	trail_instance.rotation = sprite.rotation
	
	# 4. Устанавливаем ГЛОБАЛЬНУЮ позицию
	trail_instance.global_position = global_position
	
	# 5. Настройки отображения
	trail_instance.z_index = -1  # Позади игрока
	trail_instance.modulate = trail_color  # Используем начальный цвет без изменений
	trail_instance.visible = true
	
	# 6. Добавляем в родителя сцены
	var target_parent = get_tree().current_scene
	
	if target_parent:
		target_parent.add_child(trail_instance)
		trail_instance.global_position = global_position
	else:
		get_parent().add_child(trail_instance)
		trail_instance.global_position = global_position
	
	# 7. Сохраняем информацию
	var trail_data = {
		"instance": trail_instance,
		"timer": 0.0,
		"max_time": trail_fade_time,
		"initial_global_position": global_position
	}
	
	trail_instances.append(trail_data)
	
	# 8. Ограничиваем количество
	if trail_instances.size() > trail_max_count:
		var oldest = trail_instances[0]
		if oldest["instance"] and is_instance_valid(oldest["instance"]):
			oldest["instance"].queue_free()
		trail_instances.remove_at(0)

func cleanup_trail_instances():
	var i = 0
	while i < trail_instances.size():
		var trail_data = trail_instances[i]
		
		if not trail_data or not is_instance_valid(trail_data["instance"]):
			trail_instances.remove_at(i)
			continue
		
		trail_data["timer"] += get_process_delta_time()
		
		# Экспоненциальное затухание (более плавное)
		var progress = trail_data["timer"] / trail_data["max_time"]
		
		# Формула экспоненциального затухания: e^(-k*t)
		var fade_factor = exp(-1.0 * progress)  # 3.0 - коэффициент скорости затухания
		
		# Альтернатива: плавное затухание с помощью ease-функции
		# var fade_factor = 1.0 - ease(progress, 0.5)  # Ease-out
		
		trail_data["instance"].modulate.a = trail_color.a * fade_factor
		
		# Удаляем при почти полной прозрачности
		if trail_data["timer"] >= trail_data["max_time"] or fade_factor <= 0.01:
			trail_data["instance"].queue_free()
			trail_instances.remove_at(i)
		else:
			i += 1


func clear_trail():
	"""Очищает все активные послеобразы"""
	for trail_data in trail_instances:
		if trail_data and trail_data.has("instance") and is_instance_valid(trail_data["instance"]):
			trail_data["instance"].queue_free()
	trail_instances.clear()

func set_trail_color(new_color: Color):
	trail_color = new_color
	if trail_material:
		trail_material.set_shader_parameter("trail_color", trail_color)
	
	# Обновляем цвет существующих послеобразов
	for trail_data in trail_instances:
		if trail_data and trail_data.has("instance") and is_instance_valid(trail_data["instance"]):
			var progress = trail_data["timer"] / trail_data["max_time"]
			var alpha = trail_color.a * (1.0 - progress)
			trail_data["instance"].modulate = trail_color
			trail_data["instance"].modulate.a = alpha

func toggle_trail(enabled: bool):
	enable_trail = enabled
	if not enabled:
		clear_trail()

# ===== ОСНОВНЫЕ МЕТОДЫ =====

# State management with ability checks
func request_state_change(new_state: String, force: bool = false, delay: float = 0.0) -> bool:
	if is_dead and new_state != "dead":
		return false
	
	# Check if state is available for this character
	if not is_state_available(new_state):
		return false
	
	# Если есть кулдаун и не форсируем - откладываем смену состояния
	if state_change_cooldown > 0 and not force:
		if pending_state == "" or state_priority.get(new_state, 0) > state_priority.get(pending_state, 0):
			pending_state = new_state
		return false
	
	var current_state_name = state_machine.current_state.name.to_lower()
	var current_priority = state_priority.get(current_state_name, 0)
	var new_priority = state_priority.get(new_state, 0)
	
	# Проверяем приоритеты
	if new_priority >= current_priority or force:
		if delay > 0:
			pending_state = new_state
			state_change_cooldown = delay
			return true
		else:
			state_machine.change_state(new_state)
			return true
	
	return false

func is_state_available(state_name: String) -> bool:
	match state_name:
		"fly", "fly_slow":
			return can_fly
		"boost":
			return can_boost
		"roll":
			return can_roll
		"spindash":
			return can_spindash
		_:
			return true

# Управление камерой
func lock_camera():
	camera_locked = true
	
func unlock_camera():
	camera_locked = false
	camera_offset_current = Vector2.ZERO
	camera_offset_target = Vector2.ZERO
	if camera:
		camera.position = Vector2.ZERO

func set_camera_offset(offset: Vector2):
	camera_offset_target = offset

func reset_camera_offset():
	camera_offset_target = Vector2.ZERO

# Управление и ввод
func get_input_direction() -> int:
	var direction = 0
	if Input.is_action_pressed("right"):
		direction += 1
	if Input.is_action_pressed("left"):
		direction -= 1
	return direction

# Система Колец
func take_damage(damage_direction: int = 0):
	if is_invulnerable or is_dead:
		return
	
	# Очищаем шлейф при получении урона
	clear_trail()
	
	if damage_direction == 0:
		damage_direction = -last_direction
		
	if rings > 0:
		velocity.y = hurt_bounce_velocity_y
		velocity.x = damage_direction * hurt_bounce_velocity_x
		
		var rings_to_lose = min(rings, 10)
		lose_rings(rings_to_lose)
	else:
		velocity.y = hurt_bounce_velocity_y
		velocity.x = damage_direction * hurt_bounce_velocity_x
		request_state_change("dead", true)

func add_ring():
	rings = min(rings + 1, max_rings)
	print("Колец собрано: ", rings)
	emit_signal("rings_changed", rings) 
	
func get_rings() -> int:
	return rings

func lose_rings(amount: int):
	var rings_to_lose: int
	var rings_to_scatter: int
	
	if lose_all_rings:
		rings_to_lose = rings
		rings_to_scatter = min(rings, max_scattered_rings)
	else:
		rings_to_lose = min(amount, max_scattered_rings)
		rings_to_scatter = rings_to_lose
	
	rings = max(rings - rings_to_lose, 0)
	emit_signal("rings_changed", rings)
	
	scatter_rings(rings_to_scatter)
	
	request_state_change("hurt", true)

func scatter_rings(amount: int):
	print("Разбрасываем ", amount, " колец")
	if amount <= 0:
		return
		
	var scattered_coin_scene = preload("res://objects/coins/scattered_coin/scattered_coin.tscn")
	if has_node("scatter_rings_sound"):
		$scatter_rings_sound.play()
	
	var coins_data = []
	var player_position = global_position
	
	var base_force = 350.0
	var force_variation = 30.0
	
	var start_angle = -90.0
	
	if amount == 1:
		var direction = Vector2(randf_range(-0.2, 0.2), -1.0).normalized()
		var force = base_force
		coins_data.append([player_position, direction * force])
	else:
		var spread_angle = 0.0
		
		if amount == 2:
			spread_angle = 60.0
		elif amount == 3:
			spread_angle = 90.0
		elif amount == 4:
			spread_angle = 120.0
		elif amount <= 8:
			spread_angle = 180.0
		else:
			spread_angle = 360.0
		
		var adjusted_start_angle = start_angle - (spread_angle / 2.0)
		
		for i in range(amount):
			var angle_degrees = adjusted_start_angle + (i / float(amount - 1)) * spread_angle
			var angle_radians = deg_to_rad(angle_degrees)
			
			var direction = Vector2(cos(angle_radians), sin(angle_radians))
			var force = base_force + randf_range(-force_variation, force_variation)
			
			coins_data.append([player_position, direction * force])
	
	call_deferred("_create_scattered_coins", scattered_coin_scene, coins_data)

func _create_scattered_coins(coin_scene, coins_data: Array):
	for coin_data in coins_data:
		var coin = coin_scene.instantiate()
		get_parent().add_child(coin)
		coin.global_position = coin_data[0]
		coin.velocity = coin_data[1]

# Анимации
func handle_animations(delta: float) -> void:
	var speed = abs(velocity.x)
	
	if state_machine and state_machine.current_state:
		target_animation = get_animation_for_state(state_machine.current_state.name.to_lower(), speed)
	
	handle_animation_transition(delta)

func get_animation_for_state(state_name: String, speed: float) -> String:
	if not is_state_available(state_name):
		return "idle"
	
	var walk_threshold = max_speed * 0.3
	var run_threshold = max_speed * 0.8
	
	match state_name:
		"idle":
			if not is_on_floor():
				if animation_player.has_animation("fall"):
					animation_player.speed_scale = 1.5
					return "fall"
				else:
					return "jump"
			else:
				animation_player.speed_scale = 0.7
				return "idle"
		"run", "walk":
			if not is_on_floor():
				if animation_player.has_animation("fall"):
					animation_player.speed_scale = 1.5
					return "fall"
				else:
					return "jump"
			elif speed < walk_threshold:
				animation_player.speed_scale = 0.5
				return "walk"
			elif speed <= run_threshold:
				animation_player.speed_scale = 1 + (speed - walk_threshold) / (run_threshold - walk_threshold) * 0.5
				return "walk"
			else:
				animation_player.speed_scale = 2.5 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
				return "run"
		"jump":
			animation_player.speed_scale = 3 + (speed - walk_threshold) / (run_threshold - walk_threshold) * 0.5
			return "jump"
		"fly", "fly_slow":
			if can_fly:
				if animation_player.has_animation("fly_slow") and speed < walk_threshold:
					animation_player.speed_scale = 1
					return "fly_slow"
				elif animation_player.has_animation("fly"):
					animation_player.speed_scale = 2.5 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
					return "fly"
				else:
					return "jump"
			else:
				return "jump"
		"crouch":
			animation_player.speed_scale = 3
			return "crouch"
		"lookup":
			animation_player.speed_scale = 3
			return "look_up"
		"spindash":
			animation_player.speed_scale = 3
			return "spindash"
		"roll":
			if speed < walk_threshold:
				animation_player.speed_scale = 3 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
			elif speed < run_threshold:
				animation_player.speed_scale = 4 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
			else:
				animation_player.speed_scale = 6 + (speed - run_threshold) / (max_speed - run_threshold) * 0.5
			return "roll"
		"skid":
			animation_player.speed_scale = 3.0
			return "skid"
		"hurt":
			animation_player.speed_scale = 5.0
			return "hurt"
		"dead":
			animation_player.speed_scale = 1.0
			return "dead"
		_:
			return "idle"

func handle_animation_transition(delta: float) -> void:
	if (target_animation == "crouch" and crouched) or (target_animation == "look_up" and looked_up):
		if animation_player.current_animation != target_animation and animation_player.has_animation(target_animation):
			animation_player.play(target_animation)
			animation_player.seek(animation_player.current_animation_length, true)
		return
	
	if target_animation != current_animation and animation_player.has_animation(target_animation):
		if current_animation == "crouch" or current_animation == "look_up":
			crouched = false
			looked_up = false
			is_animation_finished = false
		
		animation_blend += animation_transition_speed * delta
		if animation_blend >= 1.0:
			animation_blend = 1.0
			animation_player.play(target_animation)
			current_animation = target_animation
	
	if animation_player.current_animation != target_animation and animation_player.has_animation(target_animation):
		animation_player.play(target_animation)
		if animation_player.current_animation_length > 0:
			animation_player.seek(animation_player.current_animation_length * animation_blend, true)
	else:
		animation_blend = 0.0

func update_collision_shapes():
	call_deferred("_deferred_update_collision_shapes")

func _deferred_update_collision_shapes():
	if not hitbox_stand or not hitbox_stand_left or not hitbox_roll:
		return
		
	hitbox_stand.disabled = true
	hitbox_stand_left.disabled = true
	hitbox_roll.disabled = true

	var state_name = state_machine.current_state.name.to_lower()
	
	if state_name in ["jump", "roll"]:
		hitbox_roll.disabled = false
		set_collision_mask_value(3, false)
	else:
		if sprite and sprite.flip_h:
			hitbox_stand_left.disabled = false
		else:
			hitbox_stand.disabled = false
		set_collision_mask_value(3, true)

func disable_collisions():
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	if hitbox_roll:
		hitbox_roll.disabled = true
	if hitbox_stand_left:
		hitbox_stand_left.disabled = true
	if hitbox_stand:
		hitbox_stand.disabled = true

# ===== СИСТЕМА КРИВОЛИНЕЙНОГО ДВИЖЕНИЯ =====
func update_surface_detection():
	if not front_detector or not rear_detector:
		return
		
	front_detector.position.x = 25 * last_direction
	rear_detector.position.x = -25 * last_direction

func start_emotion():
	if not can_use_emotions or is_emoting:
		return
	
	is_emoting = true
	
	if has_node("emotion_sound"):
		$emotion_sound.play()
	
	print(character_name + " выражает эмоцию!")

func stop_emotion():
	if not is_emoting:
		return
	
	is_emoting = false
	
	if has_node("emotion_sound"):
		$emotion_sound.stop()

func can_emote() -> bool:
	return can_use_emotions and not is_emoting and is_on_floor() and abs(velocity.x) < 10

func _exit_tree():
	clear_trail()
