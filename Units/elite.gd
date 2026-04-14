extends CharacterBody2D
class_name PlayerUnit

signal unit_died(unit)

# ==========================
# 🧱 基本屬性
# ==========================
@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var attack_interval: float = 1.0
@export var speed: float = 100.0
@export var is_enemy: bool = false
@export var unit_number: int = 0

# ==========================
# ⚔️ 狀態變數
# ==========================
var current_hp: int
var attack_timer: float = 0.0
var target: Node = null
var is_on_ground: bool = false

# 新增：移動鎖定
var movement_locked: bool = false

# ==========================
# 🟢 Buff 系統
# ==========================
var active_buffs: Array = []

func _ready():
	current_hp = max_hp
	ensure_number_label()
	update_number_label()
	update_health_label()

	if is_enemy:
		add_to_group("enemy")
	else:
		add_to_group("ally")


func update_health_label():
	if has_node("HealthLabel"):
		$HealthLabel.text = "%d / %d" % [current_hp, max_hp]


func ensure_number_label():
	if has_node("NumberLabel"):
		return

	var number_label := Label.new()
	number_label.name = "NumberLabel"
	number_label.offset_left = -30.0
	number_label.offset_top = -110.0
	number_label.offset_right = 30.0
	number_label.offset_bottom = -82.0
	number_label.add_theme_font_size_override("font_size", 18)
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


# ==========================
# 🚶‍♂️ 行為邏輯
# ==========================
func _physics_process(delta):
	if target and not is_instance_valid(target):
		target = null

	is_on_ground = $FloorRay.is_colliding()

	# ==========================
	# 死亡判定
	# ==========================
	if current_hp <= 0:
		die()
		return

	_update_buffs(delta)

	# ==========================
	# ⚔️ 攻擊優先（最重要）
	# ==========================
	if target:

		attack_timer += delta

		if attack_timer >= attack_interval:
			attack_timer = 0.0

			if target and target.has_method("take_damage"):
				target.take_damage(get_final_atk())

		# ⚠️ 攻擊時停止移動（不論是否被鎖）
		velocity = Vector2.ZERO
		move_and_slide()
		return


	# ==========================
	# 🔒 被節點鎖定（不能前進，但可以被打）
	# ==========================
	if movement_locked:

		velocity = Vector2.ZERO
		move_and_slide()
		return


	# ==========================
	# 🚶‍♂️ 一般移動
	# ==========================
	if is_on_ground:
		velocity.x = get_final_speed() if not is_enemy else -get_final_speed()
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
# ⚔️ 攻擊偵測
# ==========================
func _on_attack_range_body_entered(body):

	if body is CharacterBody2D and body.has_method("take_damage"):

		if (is_in_group("ally") and body.is_in_group("enemy")) \
		or (is_in_group("enemy") and body.is_in_group("ally")):

			target = body
			velocity = Vector2.ZERO


func _on_attack_range_body_exited(body):
	if body == target:
		target = null


# =====================================================
# 🟢 Buff 系統
# =====================================================

func heal_percent(ratio: float):
	current_hp = min(max_hp, current_hp + int(max_hp * ratio))
	update_health_label()


func _update_buffs(delta: float):

	for buff in active_buffs:
		buff["time_left"] -= delta

	active_buffs = active_buffs.filter(func(b): return b["time_left"] > 0)


# =====================================================
# 🧮 Buff 後屬性
# =====================================================
func get_final_atk() -> int:

	var atk = attack_damage

	for buff in active_buffs:
		if buff["type"] == "atk":
			atk = int(atk * (1.0 + buff["value"]))

	return atk


func get_final_speed() -> float:

	var spd = speed

	for buff in active_buffs:
		if buff["type"] == "speed":
			spd = spd * (1.0 + buff["value"])

	return spd


# =====================================================
# 🔒 節點佔領用：鎖定移動
# =====================================================
func set_movement_locked(state: bool):

	movement_locked = state

	if state:
		velocity = Vector2.ZERO
		target = null
