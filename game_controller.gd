extends Node

# --- 數值 ---
var special_point: int = 0
var current_guess_count: int = 0
var special_energy: int = 0
var max_special_energy: int = 100

# 🔹 A/B/C 累積統計
var total_A: int = 0
var total_B: int = 0
var total_C: int = 0   # 預留

# 自動召喚計時
@export var player_spawn_interval: float = 4.0
var player_spawn_timer: float = 0.0
@export var enemy_spawn_interval: float = 3.0
var enemy_spawn_timer: float = 0.0

# 單位數量
var player_unit_count: int = 0
var enemy_unit_count: int = 0

# 敵人能量
var enemy_energy: int = 0
var enemy_max_energy: int = 5
var enemy_energy_timer: float = 0.0

# --- 場景 ---
var elite_scene = preload("res://Units/elite.tscn")
var enemy_scene = preload("res://Units/enemy_units.tscn")
var king_scene = preload("res://Units/king.tscn")
var special_enemy_scene = preload("res://Units/special_enemy.tscn")

# --- 節點 ---
@onready var guess_engine = get_node("/root/MainScene/GuessEngine")
@onready var player_units = get_node("/root/MainScene/Battlefield/PlayerUnits")
@onready var enemy_units = get_node("/root/MainScene/Battlefield/EnemyUnits")
@onready var player_history_container = get_node("/root/MainScene/UI/GuessHistoryPanel/ScrollContainer/VBoxContainer/HBoxContainer/PlayerResultBox/PlayerGuessHistoryContainer")
@onready var control_nodes = get_node("/root/MainScene/Battlefield/ControlNodes")
@onready var player_castle = get_node("/root/MainScene/Battlefield/PlayerCastle")
@onready var enemy_castle = get_node("/root/MainScene/Battlefield/EnemyCastle")
@onready var special_energy_bar = get_node("/root/MainScene/UI/SpecialEnergyBar")
@onready var enemy_energy_bar = get_node("/root/MainScene/UI/EnemyEnergyBar")
@onready var player_count_label = get_node("/root/MainScene/UnitCounterUI/PlayerCountLabel")
@onready var enemy_count_label = get_node("/root/MainScene/UnitCounterUI/EnemyCountLabel")

# 🔹 A/B/C UI
@onready var total_A_label = get_node("/root/MainScene/UI/GuessStatPanel/ALabel")
@onready var total_B_label = get_node("/root/MainScene/UI/GuessStatPanel/BLabel")
@onready var total_C_label = get_node("/root/MainScene/UI/GuessStatPanel/CLabel")

const CONTROL_NODE_SCENE = preload("res://ControlNode.tscn")
const CONTROL_NODE_COUNT := 5
const CONTROL_NODE_VERTICAL_SCALE := 0.8
const CONTROL_NODE_GAP := 0.0

# --- 初始化 ---
func _ready():
	update_special_energy_bar()
	update_enemy_energy_bar()
	update_guess_stat_ui()
	player_unit_count = player_units.get_child_count()
	enemy_unit_count  = enemy_units.get_child_count()
	update_unit_count_labels()
	setup_control_nodes()

# ===================== 猜測結果 =====================
func handle_guess_result(A: int, B: int, C: int = 0):
	current_guess_count += 1
	var guess = guess_engine.last_guess

	add_guess_history(guess, A, B)

	# 🔹 累積統計
	total_A += A
	total_B += B
	total_C += C
	update_guess_stat_ui()

	# 玩家猜中
	if A == 3:
		clear_player_guess_history()
		guess_engine.regenerate_player_code()
		current_guess_count = 0

		special_energy += 20
		if special_energy > max_special_energy:
			special_energy = max_special_energy

		# 🔹 猜中重置統計
		total_A = 0
		total_B = 0
		total_C = 0
		update_guess_stat_ui()

	update_special_energy_bar()


# ===================== A/B/C UI =====================
func update_guess_stat_ui():
	if total_A_label:
		total_A_label.text = "A總數: %d" % total_A
	if total_B_label:
		total_B_label.text = "B總數: %d" % total_B
	if total_C_label:
		total_C_label.text = "C總數: %d" % total_C

func setup_control_nodes():
	for child in control_nodes.get_children():
		child.queue_free()

	var player_front_x = _get_castle_front_edge(player_castle, true)
	var enemy_front_x = _get_castle_front_edge(enemy_castle, false)
	var available_width = enemy_front_x - player_front_x
	var total_gap_width = CONTROL_NODE_GAP * (CONTROL_NODE_COUNT - 1)
	var node_width = (available_width - total_gap_width) / CONTROL_NODE_COUNT
	var y = (player_castle.position.y + enemy_castle.position.y) / 2.0

	for i in range(CONTROL_NODE_COUNT):
		var node = CONTROL_NODE_SCENE.instantiate()
		var node_shape: CollisionShape2D = node.get_node("CollisionShape2D")
		var node_base_width = (node_shape.shape as RectangleShape2D).size.x * node_shape.scale.x
		control_nodes.add_child(node)
		var x = player_front_x + (node_width * 0.5) + i * (node_width + CONTROL_NODE_GAP)
		node.position = Vector2(x, y)
		node.scale = Vector2(node_width / node_base_width, CONTROL_NODE_VERTICAL_SCALE)


func _get_castle_front_edge(castle: Node2D, is_left_castle: bool) -> float:
	var collision_shape: CollisionShape2D = castle.get_node("CollisionShape2D")
	var shape_width = (collision_shape.shape as RectangleShape2D).size.x * collision_shape.scale.x
	var half_width = shape_width * 0.5

	if is_left_castle:
		return castle.position.x + collision_shape.position.x + half_width

	return castle.position.x + collision_shape.position.x - half_width
# ===================== 敵人能量 =====================
func gain_enemy_energy(amount: int):
	enemy_energy += amount
	if enemy_energy >= enemy_max_energy:
		enemy_energy = 0
	update_enemy_energy_bar()


# ===================== UI =====================
func update_special_energy_bar():
	special_energy_bar.value = special_energy

func update_enemy_energy_bar():
	enemy_energy_bar.value = enemy_energy


# ===================== 遊戲迴圈 =====================
func _process(delta: float) -> void:

	player_spawn_timer += delta
	if player_spawn_timer >= player_spawn_interval:
		player_spawn_timer = 0
		spawn_player_unit()

	enemy_spawn_timer += delta
	if enemy_spawn_timer >= enemy_spawn_interval:
		enemy_spawn_timer = 0
		spawn_enemy_unit()

	enemy_energy_timer += delta
	if enemy_energy_timer >= 10.0:
		enemy_energy_timer = 0
		gain_enemy_energy(int(enemy_max_energy * 0.01))


# ===================== 單位召喚 =====================
func spawn_player_unit():
	var unit = elite_scene.instantiate()
	player_units.add_child(unit)
	unit.connect("unit_died", Callable(self, "_on_unit_died"))
	unit.position = Vector2(100, 550)
	player_unit_count += 1
	update_unit_count_labels()

func spawn_enemy_unit():
	var enemy = enemy_scene.instantiate()
	enemy_units.add_child(enemy)
	enemy.connect("unit_died", Callable(self, "_on_unit_died"))
	enemy.position = Vector2(1200, 500)
	enemy_unit_count += 1
	update_unit_count_labels()


# ===================== 單位死亡 =====================
func _on_unit_died(unit):
	if unit.is_in_group("ally"):
		player_unit_count = max(0, player_unit_count - 1)
	elif unit.is_in_group("enemy"):
		enemy_unit_count = max(0, enemy_unit_count - 1)

	update_unit_count_labels()




# ===================== 數量更新 =====================
func update_unit_count_labels():
	if player_count_label:
		player_count_label.text = "玩家單位: %d" % player_unit_count
	if enemy_count_label:
		enemy_count_label.text = "敵人單位: %d" % enemy_unit_count


# ===================== 猜測歷史 =====================
func add_guess_history(guess: Array, A: int, B: int) -> void:
	var player_label = Label.new()
	player_label.text = "%s → %dA%dB" % [guess, A, B]
	player_history_container.add_child(player_label)

func clear_player_guess_history():
	for child in player_history_container.get_children():
		child.queue_free()
