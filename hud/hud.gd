extends CanvasLayer

@onready var rings_label = $RingsCounter

func _ready():
	print("HUD инициализирован")
	
	# Ждем немного чтобы игрок успел загрузиться
	await get_tree().create_timer(0.1).timeout
	
	connect_to_player()

func connect_to_player():
	var player = get_tree().get_first_node_in_group("player")
	
	if player:
		print("Подключаемся к игроку")
		
		# Проверяем есть ли сигнал
		if player.has_signal("rings_changed"):
			player.rings_changed.connect(update_rings_display)
			print("Сигнал подключен")
		else:
			print("Сигнал rings_changed не найден у игрока")
		
		# Обновляем начальное значение
		if player.has_method("get_rings"):
			update_rings_display(player.get_rings())
	else:
		print("Игрок не найден в сцене")

func update_rings_display(rings_count):
	print("Обновление счетчика на: ", rings_count)
	
	if rings_label:
		rings_label.text = str(rings_count)
	else:
		print("Ошибка: rings_label не найден")
