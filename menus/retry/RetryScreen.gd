extends CanvasLayer

@onready var press_x_label = $Control/PressX
@onready var blink_timer = $Control/Timer

var can_restart: bool = false

func _ready():
	# Ждем немного перед тем как разрешить рестарт
	await get_tree().create_timer(1.0).timeout
	can_restart = true
	blink_timer.start(0.5)

func _input(event):
	if can_restart and event.is_action_pressed("jump"):
		# Уменьшаем жизни при рестарте
		Global.lives -= 1
		print("Жизнь потеряна. Осталось: ", Global.lives)
		get_tree().change_scene_to_file("res://levels/test_level/level.tscn")

func _on_blink_timer_timeout():
	# Мигаем текстом
	press_x_label.visible = !press_x_label.visible
