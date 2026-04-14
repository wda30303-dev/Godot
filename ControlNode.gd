extends Area2D

enum Owner { NEUTRAL, PLAYER, ENEMY }

@export var capture_time: float = 5.0
@export_range(0.0, 1.0, 0.01) var node_alpha: float = 0.2
@export_range(0.05, 1.0, 0.01) var capture_center_ratio: float = 0.35

var node_owner: Owner = Owner.NEUTRAL
var capture_progress: float = 0.0

var player_units_inside: Array = []
var enemy_units_inside: Array = []

var building_instance = null

@onready var sprite = $Sprite2D
@onready var progress_bar = $ProgressBar
@onready var label = $Label


func _ready():
	progress_bar.max_value = capture_time
	progress_bar.value = 0
	progress_bar.hide()
	update_visual()


func _process(delta):

	var player_units_at_center = _get_units_in_capture_center(player_units_inside)
	var enemy_units_at_center = _get_units_in_capture_center(enemy_units_inside)
	var player_count = player_units_at_center.size()
	var enemy_count = enemy_units_at_center.size()

	# ==========================
	# 玩家佔領
	# ==========================
	if node_owner != Owner.PLAYER \
	and player_count > 0 \
	and enemy_count == 0:

		capture_progress += delta
		progress_bar.value = capture_progress
		progress_bar.show()

		lock_units(player_units_at_center, true)
		lock_units(enemy_units_at_center, false)

		if capture_progress >= capture_time:
			change_owner(Owner.PLAYER)
			reset_capture()

	# ==========================
	# 敵人佔領
	# ==========================
	elif node_owner != Owner.ENEMY \
	and enemy_count > 0 \
	and player_count == 0:

		capture_progress += delta
		progress_bar.value = capture_progress
		progress_bar.show()

		lock_units(enemy_units_at_center, true)
		lock_units(player_units_at_center, false)

		if capture_progress >= capture_time:
			change_owner(Owner.ENEMY)
			reset_capture()

	# ==========================
	# 無法佔領 (雙方或沒人)
	# ==========================
	else:
		lock_units(player_units_at_center, false)
		lock_units(enemy_units_at_center, false)
		if capture_progress > 0:
			reset_capture()


func change_owner(new_owner):
	node_owner = new_owner
	update_visual()


func reset_capture():
	capture_progress = 0
	progress_bar.value = 0
	progress_bar.hide()

	lock_units(player_units_inside, false)
	lock_units(enemy_units_inside, false)


func update_visual():
	match node_owner:
		Owner.NEUTRAL:
			sprite.modulate = Color(0.5, 0.5, 0.5, node_alpha)
			label.text = "中立"

		Owner.PLAYER:
			sprite.modulate = Color(0.2, 0.45, 1.0, node_alpha)
			label.text = "玩家"

		Owner.ENEMY:
			sprite.modulate = Color(1.0, 0.25, 0.25, node_alpha)
			label.text = "敵人"


func lock_units(units: Array, state: bool):
	for unit in units:
		if is_instance_valid(unit) and unit.has_method("set_movement_locked"):
			unit.set_movement_locked(state)


func _get_units_in_capture_center(units: Array) -> Array:
	var centered_units: Array = []
	var center_half_width = _get_capture_center_half_width()

	for unit in units:
		if not is_instance_valid(unit):
			continue

		if abs(unit.global_position.x - global_position.x) <= center_half_width:
			centered_units.append(unit)

	return centered_units


func _get_capture_center_half_width() -> float:
	var collision_shape: CollisionShape2D = $CollisionShape2D
	var node_width = (collision_shape.shape as RectangleShape2D).size.x * collision_shape.scale.x * scale.x
	return node_width * capture_center_ratio * 0.5


func _on_body_entered(body):

	if body.is_in_group("ally"):
		player_units_inside.append(body)
		print("player entered:", body.name)

	elif body.is_in_group("enemy"):
		enemy_units_inside.append(body)
		print("enemy entered:", body.name)


func _on_body_exited(body):

	if body.is_in_group("ally"):
		player_units_inside.erase(body)

	elif body.is_in_group("enemy"):
		enemy_units_inside.erase(body)
