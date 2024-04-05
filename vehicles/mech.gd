class_name Mech
extends CharacterBody2D


@onready var prompt = $enter_mech_prompt
@onready var body = $body
@onready var seat = $body/seat
@onready var exit = $body/exit
var inside = false

var mouse_position = Vector2()
var prev_angle_difference = 0.0

func enter_mech(player:Player):
	if !inside:
		hide_prompt()
		player.enter_mech((seat.global_position),self)

func exit_mech(player:Player):
	player.exit_mech((exit.global_position),self)
	
func show_prompt():
	if !inside:
		prompt.show()

func hide_prompt():
	if !inside:
		prompt.hide()


func get_input():
	var input = Vector2()
	if Input.is_action_pressed('right'):
		input.x += 1
	if Input.is_action_pressed('left'):
		input.x -= 1
	if Input.is_action_pressed('down'):
		input.y += 1
	if Input.is_action_pressed('up'):
		input.y -= 1
	return input
	

var speed = 250
var body_rotation_speed = 3
var acceleration = 0.1

var exiting = false
func _physics_process(delta: float) -> void:
	if inside:
		if !exiting:
			var direction = get_input()
			velocity = velocity.lerp(direction.normalized() * speed, acceleration)
			move_and_slide()
			
			mouse_position = get_global_mouse_position()
			
			var body_angle = body.rotation - 89.5
			var target_angle = (mouse_position - body.global_position).angle()
			var angle_difference = wrapf(target_angle - body_angle, -PI, PI)


			if abs(angle_difference) > 0.01:  # Adjust the threshold as needed
				if sign(prev_angle_difference) == sign(angle_difference) or prev_angle_difference == 0.0:
					body.rotation += clamp(angle_difference, -body_rotation_speed * delta, body_rotation_speed * delta)
				prev_angle_difference = angle_difference
