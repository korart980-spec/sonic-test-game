extends Area2D

@export var damage: int = 1
@onready var sound_effect = $sound_effect

func _ready():
	body_entered.connect(_on_body_entered)
	# Убедитесь, что область достаточно большая для обнаружения
	if not shape_owner_get_shape(0, 0):
		push_warning("Hazard area has no collision shape!")

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Используем call_deferred для безопасной обработки
		call_deferred("handle_player_collision", body)

func handle_player_collision(player):
	# Проверяем условия столкновения
	if not can_damage_player(player):
		return
	
	# Проигрываем звук
	if sound_effect and sound_effect.stream:
		sound_effect.play()
	
	# Вычисляем направление от опасности к игроку
	var damage_direction = sign(player.global_position.x - global_position.x)
	if damage_direction == 0:
		damage_direction = -player.last_direction
	
	# Наносим урон игроку
	player.take_damage(damage_direction)

func can_damage_player(player) -> bool:
	return (
		player.is_in_group("player") and 
		player.has_method("take_damage") and 
		not player.is_invulnerable and 
		not player.is_dead
	)
