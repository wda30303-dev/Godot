extends StaticBody2D

@export var max_hp: int = 10000  # 最大 HP 可由 Inspector 設定
@export var damage_interval: float = 1.0  # 攻擊間隔（秒）
@onready var hp_label = $EnemyHPLabel
@onready var detector = $HitDetector

var current_hp: int  # 實際運作用的變數
var attacking_units: Array = []
var damage_timer: float = 0.0

func _ready():
	current_hp = max_hp  # 遊戲開始時把最大 HP 指定給目前 HP
	update_health_label()
	# 若要保險，也可以手動連接區域訊號
	detector.body_entered.connect(_on_HitDetector_body_entered)
	detector.body_exited.connect(_on_HitDetector_body_exited)
	
func _process(delta):
	damage_timer += delta
	if damage_timer >= damage_interval:
		damage_timer = 0.0
		apply_damage()  # 執行扣血動作

func apply_damage():
	var total_damage = 0
	attacking_units = attacking_units.filter(func(e): return e and e.is_inside_tree())

	for enemy in attacking_units:
		if enemy.has_method("get_attack_power"):
			total_damage += enemy.get_attack_power()
		elif "attack_power" in enemy:
			total_damage += enemy.attack_power
		else:
			total_damage += 10  # 預設攻擊力（保底用）

	if total_damage > 0:
		current_hp -= total_damage
		current_hp = max(current_hp, 0)
		update_health_label()

		print("🏰 主堡受到攻擊，扣血：", total_damage)

		if current_hp <= 0:
			print("❌ 遊戲結束：玩家勝利！")
			get_tree().paused = true

func update_health_label():
	if has_node("EnemyHPLabel"):
		$EnemyHPLabel.text = "%d / %d" % [current_hp, max_hp]

func _on_HitDetector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_units"):
		print("⚔️ 有 player_units 進入 EnemyCastle 範圍：", body.name)
		if not attacking_units.has(body):
			attacking_units.append(body)

func _on_HitDetector_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_units"):
		print("⬅️ player_units 離開 EnemyCastle 範圍：", body.name)
		attacking_units.erase(body)
