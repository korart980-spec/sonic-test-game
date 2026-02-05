extends Area2D

@onready var animation_player = $AnimationPlayer
@onready var coin_collect = $coin_collect

var collected: bool = false

func _ready():
	body_entered.connect(_on_body_entered)
	animation_player.play("idle")

func _on_body_entered(body):
	if (body.is_in_group("player") and 
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
	if collected:
		return
		
	collected = true
	print("Кольцо собрано!")
	
	if player.has_method("add_ring"):
		player.add_ring()
	
	animation_player.play("collect")
	coin_collect.play()
	await animation_player.animation_finished
	queue_free()
