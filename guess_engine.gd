extends Node

var player_code: Array[int] = []
var last_guess: Array = []

func _ready():
	generate_new_code_only()

# 產生不重複3位數
func generate_unique_code() -> Array[int]:
	var code: Array[int] = []
	var pool = [0,1,2,3,4,5,6,7,8,9]

	while code.size() < 3:
		var rand_index = randi() % pool.size()
		var digit = pool[rand_index]
		code.append(digit)
		pool.remove_at(rand_index)

	return code

# 只產生玩家密碼
func generate_new_code_only():
	player_code = generate_unique_code()
	print("✅ 玩家密碼:", player_code)

func regenerate_player_code():
	player_code = generate_unique_code()

# 核心判定
func check_guess(guess_str: String, code: Array[int]) -> Dictionary:

	if guess_str.length() != 3:
		return { "valid": false, "msg": "請輸入3位數字。" }

	var guess: Array[int] = []

	for c in guess_str:
		if not c.is_valid_int():
			return { "valid": false, "msg": "只能輸入數字。" }
		guess.append(int(c))

	if guess.size() != 3 or guess.duplicate().size() != 3:
		return { "valid": false, "msg": "不能輸入重複數字。" }

	last_guess = guess

	var A = 0
	var B = 0

	for i in range(3):
		if guess[i] == code[i]:
			A += 1
		elif guess[i] in code:
			B += 1

	return {
		"valid": true,
		"A": A,
		"B": B,
		"msg": "%dA%dB" % [A, B]
	}

# 專給玩家用
func check_player_guess(guess_str: String) -> Dictionary:
	return check_guess(guess_str, player_code)
