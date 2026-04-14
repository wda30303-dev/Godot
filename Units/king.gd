extends CharacterBody2D
signal unit_died(unit)   # 🟢 新增：死亡時發送的訊號
@export var max_hp: int = 100
@export var attack_damage: int = 10
@export var attack_interval: float = 1.0
@export var speed: float = 100.0
@export var is_enemy: bool = false  # ❗我方單位設定為 false
@export var attack_power: int = 10  # 每秒對敵人主堡造成的傷害

@export var unit_number: int = 0
var current_hp: int
var attack_timer: float = 0.0
var target: Node = null
var is_on_ground: bool = false

func _ready():
	current_hp = max_hp
	ensure_number_label()
	update_number_label()
	update_health_label()
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
	number_label.offset_top = -108.0
	number_label.offset_right = 30.0
	number_label.offset_bottom = -80.0
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


func _physics_process(delta):
	is_on_ground = $FloorRay.is_colliding()

	if current_hp <= 0:
		queue_free()
		return

	if target:
		# 攻擊邏輯
		attack_timer += delta
		if attack_timer >= attack_interval:
			attack_timer = 0.0
			if target.has_method("take_damage"):
				target.take_damage(attack_damage)
	else:
		# 沒有攻擊目標就往前走（我方往右）
		if is_on_ground:
			velocity.x = speed
		else:
			velocity.y += 500 * delta

		move_and_slide()

func take_damage(amount: int):
	current_hp -= amount
	update_health_label()
	if current_hp <= 0:
		queue_free()
		die()
# 🟢 新增：統一死亡處理
func die():
	emit_signal("unit_died", self)   # 發送訊號給 GameController
	queue_free()
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
		if (is_in_group("ally") and body.is_in_group("enemy")) or (is_in_group("enemy") and body.is_in_group("ally")):
			target = body
			velocity = Vector2.ZERO
			#print("⚔️ 發現敵人！準備攻擊！")
