extends CharacterBody2D
class_name Player

# Хитбоксы как в SWN
var HITBOXES = {
	"normal": Vector2(18, 38),
	"roll": Vector2(14, 28),
	"crouch": Vector2(18, 22),
	"glide": Vector2(20, 20)
}

# Ссылки на узлы
@onready var hit_box: CollisionShape2D = $HitBox
@onready var sprite_holder: Node2D = $SpriteHolder
@onready var state_machine: Node = $StateMachine

# Текущий персонаж
var current_character: String = ""
var animation_player: AnimationPlayer
var character_sprite: Sprite2D

func _ready():
	# Загружаем выбранного персонажа
	load_character(Global.selected_character_id)
	
	# Инициализируем state machine
	initialize_state_machine()
	
	# Устанавливаем начальный хитбокс
	update_hitbox("normal")

func load_character(character_id: String):
	current_character = character_id
	
	# Загружаем сцену анимаций персонажа
	var character_scene: PackedScene
	match character_id:
		"sonic":
			character_scene = preload("res://characters/sonic/sonic.tscn")
		"exetior":
			character_scene = preload("res://characters/exetior/exetior.tscn")
		_:
			character_scene = preload("res://characters/sonic/sonic.tscn")
	
	# Очищаем предыдущего персонажа
	for child in sprite_holder.get_children():
		child.queue_free()
	
	# Добавляем нового персонажа
	var char_instance = character_scene.instantiate()
	sprite_holder.add_child(char_instance)
	
	# Получаем ссылки на компоненты анимаций
	character_sprite = char_instance.get_node("Sprite2D")
	animation_player = char_instance.get_node("AnimationPlayer")
	
	print("Загружен персонаж: ", character_id)

func update_hitbox(hitbox_type: String):
	var hitbox_size = HITBOXES.get(hitbox_type, HITBOXES.normal)
	
	# Сохраняем текущую позицию низа хитбокса
	var current_bottom = hit_box.global_position.y + hit_box.shape.size.y / 2
	
	# Меняем размер
	hit_box.shape.size = hitbox_size
	
	# Корректируем позицию чтобы низ оставался на месте
	var new_bottom = hit_box.global_position.y + hitbox_size.y / 2
	var y_correction = current_bottom - new_bottom
	hit_box.position.y += y_correction
	
	print("Хитбокс обновлен: ", hitbox_type, " размер: ", hitbox_size)

func initialize_state_machine():
	# Инициализируем все состояния
	for state in state_machine.get_children():
		if state.has_method("set_player"):
			state.set_player(self)
	
	# Запускаем начальное состояние
	state_machine.change_state("Normal")
