extends Resource
class_name CharacterConfig

@export var character_name: String = "sonic"

# Спрайт
@export var sprite_texture: Texture2D
@export var sprite_scale: Vector2 = Vector2(1, 1)
@export var sprite_offset: Vector2 = Vector2.ZERO

# Настройки региона спрайт-шита (если используется)
@export var use_sprite_sheet: bool = true
@export var sprite_region_rect: Rect2 = Rect2(0, 0, 64, 64)

# Способности
@export var can_boost: bool = false
@export var can_fly: bool = false
@export var can_spindash: bool = true
@export var can_roll: bool = true

# Характеристики
@export var max_speed: float = 450.0
@export var acceleration: float = 400.0
@export var jump_force: float = -420.0
