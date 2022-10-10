extends Control

export var player_name : String = ''
export var player_icon : Texture

onready var rows = [$'%Ones', $'%Twos', $'%Threes', $'%Fours', $'%Fives', $'%Sixes', $'%Bonus', $'%3OfAKind', $'%4OfAKind', $'%FullHouse', $'%SMStraight', $'%LGStraight', $'%Yahtzee', $'%Chance', $'%Total']

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
	for i in 6:
		if rows[i].pressed: continue
		rows[i].text = str(get_number_res(i+1, rollArray))
	for i in [7, 8]:
		if rows[i].pressed: continue
		rows[i].text = str(get_of_a_kind_res(3 if i == 7 else (4 if i == 8 else 5), rollArray))
	
	if not rows[9].pressed:
		rows[9].text = str(get_full_house_res(rollArray))
	if not rows[10].pressed:
		rows[10].text = str(get_straight_res(false, rollArray))
	if not rows[11].pressed:
		rows[11].text = str(get_straight_res(true, rollArray))
	if not rows[12].pressed:
		rows[12].text = str(50 if is_yahtzee(rollArray) else 0)
	if not rows[13].pressed:
		rows[13].text = str(get_chance_res(rollArray))

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
	return 25 if diffNums.size() <= 2 else 0

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
		if row is Button and row.pressed:
			sum += int(row.text)
	return sum

func refresh_bonus() -> void:
	var sum := 0
	for i in 6:
		var row = rows[i]
		if not row.pressed: continue
		sum += int(row.text)
	if sum >= 63:
		rows[6].text = '35'
		return
	rows[6].text = str(sum) + ' (' + str(63-sum) + ' left)'
