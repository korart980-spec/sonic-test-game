extends CharacterBody2D
class_name TestEnemy

@export var health: int = 1
@onready var animation_player = $AnimationPlayer
@onready var hitbox = $PlayerDetectionArea  # Area2D для обнаружения столкновений

var is_dead: bool = false

func _ready():
	add_to_group("enemies")
	# Подключаем сигнал от Area2D hitbox
	animation_player.play("walk")
	if hitbox:
		hitbox.body_entered.connect(_on_body_entered)

func _physics_process(delta):
	if is_dead:
		return
	
	# Просто стоим на месте для теста
	velocity.y += 980 * delta
	move_and_slide()

func _on_body_entered(body):
	if body.is_in_group("player") and not is_dead:
		handle_player_collision(body)

func handle_player_collision(player):
	if player.is_invulnerable or player.is_dead:
		return
	
	# Простая проверка: если игрок сверху - враг умирает, иначе игрок получает урон
	if player.global_position.y < global_position.y - 10:  # игрок выше врага
		take_damage()
	else:
		player.take_damage()

func take_damage():
	health -= 1
	if health <= 0:
		die()
	else:
		animation_player.play("hit")

func die():
	is_dead = true
	animation_player.play("destroy")
	set_collision_layer_value(1, false)
	set_collision_mask_value(1, false)
	await animation_player.animation_finished
	queue_free()
