extends Control

var die_texture_paths = [
	'res://Data/Sprites/Dice/dieWhite1.png', 'res://Data/Sprites/Dice/dieWhite2.png', 'res://Data/Sprites/Dice/dieWhite3.png', 'res://Data/Sprites/Dice/dieWhite4.png', 'res://Data/Sprites/Dice/dieWhite5.png', 'res://Data/Sprites/Dice/dieWhite6.png'
]
var die_textures : Array = []

onready var initial_position : Vector2 = rect_position
onready var die_button : Button = $Die

signal rolled(result)

func _ready() -> void:
	for path in die_texture_paths:
		die_textures.append(load(path))

func read() -> int:
	return die_textures.find(die_button.icon) 

func roll() -> void:
	if die_button.pressed:
		return
	$RollTimer.start()
	$Timer.start()
	$RotationTimer.start()

func _on_Timer_timeout() -> void:
	var randI = randi() % 6
#	var randI = randi() % 1 + 5
	die_button.icon = die_textures[randI]

func _on_RotationTimer_timeout() -> void:
	die_button.rect_rotation = rand_range(0, 360)
	die_button.rect_position = Vector2(rand_range(-5, 5), rand_range(-5, 5))

func _on_RollTimer_timeout() -> void:
	$Timer.stop()
	$RotationTimer.stop()
	die_button.rect_rotation = 0
	die_button.rect_position = Vector2.ZERO
	emit_signal('rolled', read())

func _on_Die_toggled(button_pressed: bool) -> void:
	$SelectedRect.visible = button_pressed

func reset() -> void:
	die_button.pressed = false
	die_button.icon = die_textures[0]
