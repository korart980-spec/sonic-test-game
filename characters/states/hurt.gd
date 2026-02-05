extends State

var hurt_timer: float = 0.0
var max_hurt_time: float = 1.2  # Время в состоянии урона
var can_collect_rings: bool = false
var ring_collect_delay: float = 0.5
var has_landed: bool = false  # Флаг для отслеживания приземления
var initial_bounce_complete: bool = false  # Флаг завершения начального отскока

func enter():
	player.is_invulnerable = true
	player.target_animation = "hurt"
	player.invulnerability_timer.start(player.invulnerability_time)
	
	# Запрещаем сбор колец в начале состояния урона
	can_collect_rings = false
	has_landed = false
	initial_bounce_complete = false
	
	# Более плавный мигающий эффект
	var tween = create_tween()
	tween.tween_property(player.sprite, "modulate:a", 0.2, 0.15)
	tween.tween_property(player.sprite, "modulate:a", 1.0, 0.15)
	tween.set_loops(6)  # Увеличили количество циклов
	
	hurt_timer = 0.0
	player.update_collision_shapes()
	
	# Разрешаем сбор колец через короткое время
	await get_tree().create_timer(ring_collect_delay).timeout
	can_collect_rings = true

func exit():
	player.sprite.modulate.a = 1.0
	can_collect_rings = true
	has_landed = false
	initial_bounce_complete = false

func physics_update(delta: float):
	player.velocity.y += player.gravity * delta
	
	# Меньше замедление в воздухе для более плавного отскока
	if not player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.1)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0, player.deceleration * delta * 0.3)
	
	# Отмечаем, что начальный отскок завершен, когда начинаем падать
	if player.velocity.y >= 0 and not initial_bounce_complete:
		initial_bounce_complete = true
	
	# Проверяем приземление только после завершения начального отскока
	if player.is_on_floor() and initial_bounce_complete and not has_landed:
		has_landed = true
		state_machine.change_state("run")
		return
	
	hurt_timer += delta
	
	# Автоматический выход после максимального времени (если все еще в воздухе)
	if hurt_timer >= max_hurt_time and not player.is_on_floor():
		state_machine.change_state("jump")
