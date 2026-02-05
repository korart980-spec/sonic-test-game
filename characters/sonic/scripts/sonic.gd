extends "res://characters/player_base.gd"

func _ready():
	# Конфигурация способностей Соника
	character_name = "sonic"
	can_boost = false
	can_fly = false
	can_spindash = true
	can_roll = true
	
	# Вызов родительского ready
	super._ready()

# Переопределяем анимации для Соника если нужно
func get_animation_for_state(state_name: String, speed: float) -> String:
	# Базовая логика из player_base, можно переопределить специфичные анимации
	return super.get_animation_for_state(state_name, speed)
