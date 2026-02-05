extends CharacterBody2D

@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer
@onready var collect_sound = $CollectSound
@onready var area = $Area2D

# Параметры физики - ближе к оригиналу
var gravity: float = 800.0  # Увеличим гравитацию для более быстрого падения
var bounce_factor: float = 0.8  # Меньший отскок
var life_time: float = 5.0
var time_alive: float = 0.0
var can_be_collected: bool = false
var collected: bool = false
var max_horizontal_speed: float = 400.0  # Увеличим максимальную скорость
var air_resistance: float = 0.99  # Меньшее сопротивление

# Для обработки отскоков
var bounce_count: int = 0
var max_bounces: int = 5  # Меньше отскоков
var was_on_floor: bool = false
var pre_collision_velocity: Vector2 = Vector2.ZERO

func _ready():
	area.body_entered.connect(_on_body_entered)
	# Задержка перед возможностью сбора (как в оригинале)
	await get_tree().create_timer(0.1).timeout
	can_be_collected = true
	animation_player.speed_scale = 1.5
	animation_player.play("idle")

func _physics_process(delta):
	time_alive += delta
	
	# Исчезновение через время жизни
	if time_alive >= life_time:
		queue_free()
		return
	
	# Применяем гравитацию
	velocity.y += gravity * delta
	
	# Более сильное ограничение горизонтальной скорости
	velocity.x = clamp(velocity.x, -max_horizontal_speed, max_horizontal_speed)
	
	# Меньшее сопротивление воздуха для более плавного движения
	velocity.x *= air_resistance
	
	# Сохраняем скорость ДО движения
	pre_collision_velocity = velocity
	
	# Сохраняем состояние перед движением
	var previously_on_floor = is_on_floor()
	
	# Двигаем
	move_and_slide()
	
	# Обработка отскоков от пола
	if is_on_floor() and not previously_on_floor:
		handle_bounce(pre_collision_velocity.y)
	
	# После максимального количества отскоков останавливаемся
	if is_on_floor() and bounce_count >= max_bounces:
		velocity.y = 0
		velocity.x *= 0.9  # Быстрее останавливаемся на полу
	
	# Мигание перед исчезновением (последние 2 секунды)
	if time_alive > life_time - 2.0:
		var blink_speed = 10.0  # Более быстрое мигание
		var alpha = (sin(time_alive * blink_speed) + 1.0) / 2.0
		sprite.modulate.a = alpha

func handle_bounce(impact_velocity: float):
	bounce_count += 1
	
	# Более реалистичный отскок
	var bounce_strength = bounce_factor * (1.0 - (bounce_count / float(max_bounces + 1)))
	
	# Отскок с учетом силы удара
	velocity.y = -abs(impact_velocity) * bounce_strength
	
	# Сохраняем горизонтальную скорость, но с небольшим уменьшением
	velocity.x *= 0.8

func _on_body_entered(body):
	if (can_be_collected and 
		body.is_in_group("player") and 
		not collected and
		_can_collect_ring(body)):
		collect(body)

func _can_collect_ring(player) -> bool:
	# Нельзя собирать кольца если мертв
	if player.is_dead:
		return false
	
	# Проверяем, разрешен ли сбор колец в состоянии hurt
	var state_name = player.state_machine.current_state.name.to_lower()
	if state_name == "hurt":
		# Используем флаг из состояния hurt
		return player.state_machine.current_state.can_collect_rings
	
	# Во всех остальных состояниях можно собирать кольца
	return true

func collect(player):
	collected = true
	
	if player.has_method("add_ring"):
		player.add_ring()
	
	animation_player.play("collect")
	collect_sound.play()
	
	await animation_player.animation_finished
	queue_free()
