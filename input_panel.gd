extends Control

@onready var input_field = $NumberInput
@onready var submit_button = $SubmitButton
@onready var feedback_label = $FeedbackLabel
@onready var guess_engine = get_node("/root/MainScene/GuessEngine")
@onready var game_controller = get_node("/root/MainScene/GameController")
var can_guess := true

func _ready():
	submit_button.focus_mode = Control.FOCUS_NONE
	submit_button.pressed.connect(_on_submit_pressed)
	input_field.text_submitted.connect(_on_enter_pressed)
	_focus_input_field()

func _on_submit_pressed():
	_submit_guess()

func _on_enter_pressed(_new_text):
	_submit_guess()

func _submit_guess():

	if not can_guess:
		return

	can_guess = false
	submit_button.disabled = true

	var guess_str = input_field.text.strip_edges()

	var player_result = guess_engine.check_player_guess(guess_str)

	if not player_result["valid"]:
		feedback_label.text = player_result["msg"]
	else:
		feedback_label.text = player_result["msg"]
		game_controller.handle_guess_result(
			player_result["A"], player_result["B"],
		)
		input_field.text = ""

	await get_tree().create_timer(1.0).timeout

	can_guess = true
	submit_button.disabled = false
	_focus_input_field()


func _focus_input_field():
	get_viewport().gui_release_focus()
	input_field.call_deferred("grab_focus")
	input_field.call_deferred("grab_click_focus")
	input_field.call_deferred("set_caret_column", input_field.text.length())
