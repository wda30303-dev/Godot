extends CharacterBody2D

signal unit_died(unit)

@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var attack_interval: float = 1.0
@export var speed: float = 100.0
@export var is_enemy: bool = true
@export var attack_power: int = 10
@export var unit_number: int = 0

var current_hp: int
var attack_timer: float = 0.0
var target: Node = null
var is_on_ground: bool = false

# --- 節點佔領用 ---
var movement_locked: bool = false

# --- 狀態暫存 ---
var speed_multiplier: float = 1.0
var attack_multiplier: float = 1.0


func _ready():
	current_hp = max_hp
	ensure_number_label()
	update_number_label()
	update_health_label()

	if is_enemy:
		add_to_group("enemy")
		add_to_group("enemy_units")
	else:
		add_to_group("ally")
		add_to_group("player_units")


func update_health_label():
	if has_node("HealthLabel"):
		$HealthLabel.text = "%d / %d" % [current_hp, max_hp]


func ensure_number_label():
	if has_node("NumberLabel"):
		return

	var number_label := Label.new()
	number_label.name = "NumberLabel"
	number_label.offset_left = -70.0
	number_label.offset_top = -250.0
	number_label.offset_right = 70.0
	number_label.offset_bottom = -205.0
	number_label.add_theme_font_size_override("font_size", 42)
	number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(number_label)


func update_number_label():
	if has_node("NumberLabel"):
		$NumberLabel.text = str(unit_number)


func set_unit_number(value: int):
	unit_number = value
	update_number_label()


func add_unit_number(amount: int):
	set_unit_number(unit_number + amount)


func _physics_process(delta):

	is_on_ground = $FloorRay.is_colliding()

	# ==========================
	# 死亡
	# ==========================
	if current_hp <= 0:
		die()
		return

	# ==========================
	# 清除無效 target
	# ==========================
	if target and not is_instance_valid(target):
		target = null

	# ==========================
	# ⚔️ 攻擊優先（最重要）
	# ==========================
	if target:

		attack_timer += delta

		if attack_timer >= attack_interval:
			attack_timer = 0.0

			if target and target.has_method("take_damage"):
				target.take_damage(int(attack_damage * attack_multiplier))

		# 攻擊時停止水平移動，但保留重力
		if not is_on_ground:
			velocity.y += 500 * delta
		else:
			velocity.y = 0

		velocity.x = 0
		move_and_slide()
		return


	# ==========================
	# 🔒 節點鎖定（不能走，但會掉下來）
	# ==========================
	if movement_locked:

		if not is_on_ground:
			velocity.y += 500 * delta
		else:
			velocity.y = 0

		velocity.x = 0
		move_and_slide()
		return


	# ==========================
	# 🚶‍♂️ 正常移動
	# ==========================
	if is_on_ground:
		velocity.x = (-speed if is_enemy else speed) * speed_multiplier
	else:
		velocity.y += 500 * delta

	move_and_slide()


# ==========================
# ❤️ 傷害與死亡
# ==========================
func take_damage(amount: int):
	current_hp -= amount
	update_health_label()

	if current_hp <= 0:
		die()


func die():
	emit_signal("unit_died", self)
	queue_free()


# ==========================
# ⚔️ 攻擊偵測（❗已修正）
# ==========================
func _on_body_entered(body):

	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.is_enemy != is_enemy:
			target = body
			velocity = Vector2.ZERO


func _on_body_exited(body):
	if body == target:
		target = null


func _on_attack_range_body_entered(body):

	if body is CharacterBody2D and body.has_method("take_damage"):
		if body.is_enemy != is_enemy:
			target = body
			velocity = Vector2.ZERO


# ==========================
# 🔒 節點佔領 API
# ==========================
func set_movement_locked(state: bool):

	movement_locked = state

	if state:
		velocity.x = 0   # ❗ 不清 target（讓戰鬥可以發生）


# ==========================
# 🟢 戰術卡 API
# ==========================
func buff_attack(percent: int, duration: float = 10.0):

	var multiplier = 1.0 + float(percent) / 100.0
	attack_multiplier *= multiplier

	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		attack_multiplier /= multiplier)


func speed_up(multiplier: float, duration: float = 5.0):

	speed_multiplier *= multiplier

	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(func():
		speed_multiplier /= multiplier)
