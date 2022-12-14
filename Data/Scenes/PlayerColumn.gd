extends Control

export var player_name : String = ''
export var player_icon : Texture

enum EMappings {
	Ones = 0,
	Twos = 1,
	Threes = 2,
	Fours = 3,
	Fives = 4,
	Sixes = 5,
	Bonus = 6,
	ThreeOfAKind = 7,
	FourOfAKind = 8,
	FullHouse = 9,
	SMStraight = 10,
	LGStraight = 11,
	Yahtzee = 12,
	Chance = 13,
	Total = 14
}

onready var rows = [$'%Ones', $'%Twos', $'%Threes', $'%Fours', $'%Fives', $'%Sixes', $'%Bonus', $'%3OfAKind', $'%4OfAKind', $'%FullHouse', $'%SMStraight', $'%LGStraight', $'%Yahtzee', $'%Chance', $'%Total']
onready var bonus_progress : ProgressBar = rows[6].get_child(0)
onready var bonus_tween : Tween = $BonusTween

var has_yahtzeed : bool = false
var has_bonused : bool = false
var last_rolls : Array

onready var pressedBG : StyleBoxFlat = load('res://Data/StyleBoxes/StyleBox_GreenPressed.tres')

signal end_turn(playerName)

func _ready() -> void:
	connect_buttons()
	$"%PlayerName".text = player_name
	$"%PlayerIcon".texture = player_icon
	refresh_bonus()

func connect_buttons() -> void:
	for child in get_children():
		if child is Button:
			var _ret = child.connect('pressed', self, 'on_button_pressed', [child.name])
			assert(_ret == OK)

func on_button_pressed(identifier: String) -> void:
	var buttonNode : Button = get_node(identifier)
#	print('Pressed: ', identifier, '\t\twhich is now: ', 'pressed' if buttonNode.pressed else 'not pressed')
#	buttonNode.disabled = true
	if not buttonNode.pressed:
		buttonNode.pressed = true
	else:
		if buttonNode.text.empty():
			buttonNode.pressed = false
			return
		var yPoints : int = int(rows[EMappings.Yahtzee].text.split(' ')[0])
		if is_yahtzee(last_rolls) and rows[EMappings.Yahtzee].pressed and yPoints > 0:
			if not has_yahtzeed:
				has_yahtzeed = true
			else:
				# warning-ignore:integer_division
				rows[EMappings.Yahtzee].text = str(yPoints + 100) + ' (' + str((yPoints + 100) / 100 + 1) + 'x)'
		refresh_bonus()
		refresh_total()
		buttonNode.release_focus()
		emit_signal('end_turn', player_name)

func new_turn() -> void:
	for child in get_children():
		if child is Button and not child.pressed:
			child.text = ''

func refresh_total() -> void:
	rows[14].text = str(get_total())
	
func refresh_for_rolls(rollArray: Array) -> void:
	last_rolls = rollArray
	for i in 6:
		if rows[i].pressed: continue
		rows[i].text = str(get_number_res(i+1, rollArray))
	for i in [EMappings.ThreeOfAKind, EMappings.FourOfAKind]:
		if rows[i].pressed: continue
		rows[i].text = str(get_of_a_kind_res(3 if i == 7 else (4 if i == 8 else 5), rollArray))
	
	if not rows[EMappings.FullHouse].pressed:
		rows[EMappings.FullHouse].text = '25' if wildcard_multi_yahtzee(rollArray) else str(get_full_house_res(rollArray))
	if not rows[EMappings.SMStraight].pressed:
		rows[EMappings.SMStraight].text = '30' if wildcard_multi_yahtzee(rollArray) else str(get_straight_res(false, rollArray))
	if not rows[EMappings.LGStraight].pressed:
		rows[EMappings.LGStraight].text = '40' if wildcard_multi_yahtzee(rollArray) else str(get_straight_res(true, rollArray))
	if not rows[EMappings.Yahtzee].pressed:
		rows[EMappings.Yahtzee].text = str(50 if is_yahtzee(rollArray) else 0)
	if not rows[EMappings.Chance].pressed:
		rows[EMappings.Chance].text = str(get_chance_res(rollArray))

func get_number_res(number: int, rollArray: Array) -> int:
	var sum = 0
	for roll in rollArray:
		sum += number if roll == number else 0
	return sum

func get_of_a_kind_res(minCount: int, rollArray: Array) -> int:
	var sortedArray := rollArray.duplicate()
	sortedArray.sort()
	var count := 0
	var counted := 0
	var sum := 0
	for roll in sortedArray:
		if roll != counted:
			count = 1
			counted = roll
		else:
			count += 1
			if count >= minCount:
				break
	for roll in sortedArray:
		sum += roll
	var score = sum if count >= minCount else 0
	return score

func get_chance_res(rollArray: Array) -> int:
	var sum : int = 0
	for roll in rollArray:
		sum += roll
	return sum

func get_full_house_res(rollArray: Array) -> int:
	var diffNums : Array = []
	for roll in rollArray:
		if diffNums.find(roll) == -1:
			diffNums.append(roll)
	for diffNum in diffNums:
		# If there is only one occurance there is no full
		if rollArray.find(diffNum) == rollArray.find_last(diffNum):
			return 0
	return 25 if diffNums.size() == 2 else 0

func wildcard_multi_yahtzee(rollArray: Array) -> bool:
	var num = rollArray[0]
	var is_pressed : bool = rows[num - 1].pressed
	return is_yahtzee(rollArray) and is_pressed and rows[EMappings.Yahtzee].pressed and int(rows[EMappings.Yahtzee].text) != 0

func get_straight_res(large: bool, rollArray: Array) -> int:
	for i in [3, 4]:
		if rollArray.find(i) == -1:
			return 0
	if large:
		for i in [2, 5]:
			if rollArray.find(i) == -1:
				return 0
		if rollArray.find(1) != -1 or rollArray.find(6) != -1:
			return 40
		return 0
	if (rollArray.find(1) != -1 and rollArray.find(2) != -1) or \
		(rollArray.find(2) != -1 and rollArray.find(5) != -1) or \
		(rollArray.find(5) != -1 and rollArray.find(6) != -1):
		return 30
	return 0

func is_yahtzee(rollArray: Array) -> bool:
	return get_of_a_kind_res(5, rollArray) > 0

func get_total() -> int:
	var sum := 0
	for row in rows:
		if row == rows[EMappings.Yahtzee]:
			var yPoints : int = int(rows[EMappings.Yahtzee].text.split(' ')[0])
			sum += yPoints
		elif row is Button and row.pressed:
			sum += int(row.text)
	if has_bonused:
		sum += 35
	return sum

func refresh_bonus() -> void:
	var sum := 0
	for i in 6:
		var row = rows[i]
		if not row.pressed: continue
		sum += int(row.text)
	if sum >= 63:
		rows[EMappings.Bonus].text = '35'
		has_bonused = true
		set_bonus_gradually(63)
		$Bonus/ProgressBar.set('custom_styles/fg', pressedBG)
		rows[EMappings.Bonus].set('custom_fonts/font', null)
		return
	set_bonus_gradually(sum)
	rows[EMappings.Bonus].text = '0' + ' (' + str(63-sum) + ' left)'

func set_bonus_gradually(bonusPoint: int) -> void:
	var dist : int = int(abs(bonusPoint - bonus_progress.value))
	var _ret = bonus_tween.interpolate_property(bonus_progress, 'value', bonus_progress.value, bonusPoint, 0.01 * dist)
	_ret = bonus_tween.start()
	
