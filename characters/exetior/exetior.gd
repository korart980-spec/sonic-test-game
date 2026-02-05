extends "res://characters/player_base.gd"

func _ready():
	# Конфигурация способностей Exetior
	character_name = "exetior"
	can_boost = true
	can_fly = true
	can_spindash = true
	can_roll = true
	
	# Специфичные настройки полета
	fly_boost_power = 0  # Не используем в новой системе
	fly_drop_power = 0   # Не используем в новой системе
	
	# Вызов родительского ready
	super._ready()

# Переопределяем анимации для Exetior
func get_animation_for_state(state_name: String, speed: float) -> String:
	if state_name == "fly":
		# Разные анимации в зависимости от скорости
		if speed < max_speed * 0.3:
			animation_player.speed_scale = 1.0
			return "fly_slow"
		elif is_boosting:  # Новая переменная, нужно добавить в player_base.gd
			animation_player.speed_scale = 3.0
			return "fly_boost"  # Создайте эту анимацию
		else:
			animation_player.speed_scale = 1.5
			return "fly"
	
	return super.get_animation_for_state(state_name, speed)
