extends Node
class_name StateMachine

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	# Автоматически находим все состояния среди дочерних нод
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.player = get_parent()
			child.state_machine = self
	
	# Начинаем с состояния idle
	change_state("idle")

func _input(event):
	handle_input()

func change_state(new_state_name: String):
	# Защита от рекурсивных вызовов
	if current_state and current_state.name.to_lower() == new_state_name.to_lower():
		return
	
	var new_state = states.get(new_state_name.to_lower())
	
	if not new_state:
		push_error("State not found: " + new_state_name)
		return
	
	if current_state:
		current_state.exit()
		# Сохраняем предыдущее состояние
		get_parent().previous_state = current_state
	
	current_state = new_state
	current_state.enter()

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func update(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func handle_input():
	if current_state:
		current_state.handle_input()
