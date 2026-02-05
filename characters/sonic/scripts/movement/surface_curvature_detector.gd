extends RayCast2D

@export var detection_range: float = 80.0
var surface_angle: float = 0.0

func _ready():
	target_position = Vector2(0, detection_range)
	enabled = true

func _physics_process(_delta):
	if is_colliding():
		var normal = get_collision_normal()
		surface_angle = normal.angle() + PI/2  # Исправленная формула
		# Нормализуем угол между -PI и PI
		while surface_angle > PI:
			surface_angle -= 2 * PI
		while surface_angle < -PI:
			surface_angle += 2 * PI
	else:
		surface_angle = 0.0

func get_surface_angle() -> float:
	return surface_angle

func is_on_surface() -> bool:
	return is_colliding()
