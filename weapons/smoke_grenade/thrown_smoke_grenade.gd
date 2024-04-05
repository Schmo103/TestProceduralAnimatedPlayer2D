class_name ThrownGrenade
extends RigidBody2D



@onready var mouse_pos
@onready var angle_to_mouse
@onready var anim_player = $AnimationPlayer_nade

func _ready() -> void:
	anim_player.play("throb")
	await get_tree().create_timer(3.0).timeout
	explode()


func launch_to_mouse_pos(speed : float, p_velocity):
	mouse_pos = get_global_mouse_position()
	angle_to_mouse = position.angle_to_point(mouse_pos)
	var impulse = Vector2.RIGHT.rotated(angle_to_mouse) * speed
	apply_impulse(impulse + p_velocity, Vector2.ZERO)
	print("launched")

func explode():
	anim_player.play("explode")



func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "explode":
		queue_free()
