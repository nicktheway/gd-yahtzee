extends Control


onready var dice = [$'%Die1', $'%Die2', $'%Die3', $'%Die4', $'%Die5']
onready var roll_button : Button = $VBoxContainer/RollButton

var dice_rolls = [0, 0, 0, 0, 0]
var current_roll_id = 0

var roll_texts = [
	'Roll Dice ① ② ③',
	'Roll Dice ● ② ③',
	'Roll Dice ● ● ③',
	'Roll Dice ● ● ●'
]

func _ready() -> void:
	randomize()
	$VBoxContainer/ReadDiceLabel.text = '-----'
	for i in range(dice.size()):
		var _ret = dice[i].connect('rolled', self, 'die_rolled', [i])
		assert(_ret == OK)
	roll_button.text = roll_texts[current_roll_id]

func _on_RollButton_pressed() -> void:
	current_roll_id += 1
	roll_button.text = roll_texts[current_roll_id]
	roll_dice()
	if current_roll_id >= 3:
		roll_button.disabled = true

func roll_dice() -> void:
	for die in dice:
		die.roll()

func die_rolled(result: int, index: int) -> void:
	dice_rolls[index] = result + 1
	var strArray = []
	for roll in dice_rolls:
		strArray.append(str(roll))
	$VBoxContainer/ReadDiceLabel.text = String(strArray)
	$VBoxContainer/HBoxContainer/PlayerColumn.refresh_for_rolls(dice_rolls)

func _on_PlayerColumn_end_turn(_playerName: String) -> void:
	for die in dice:
		die.reset()
	$VBoxContainer/ReadDiceLabel.text = '-----'
	$VBoxContainer/HBoxContainer/PlayerColumn.new_turn()
	roll_button.disabled = false
	current_roll_id = 0
	roll_button.text = roll_texts[current_roll_id]
