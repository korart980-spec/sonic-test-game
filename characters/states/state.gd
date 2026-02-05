extends Node
class_name State

# Ссылка на персонажа
var player: CharacterBody2D
var state_machine: StateMachine

func enter() -> void:
	pass

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	pass

func update(delta: float) -> void:
	pass

func handle_input() -> void:
	pass
