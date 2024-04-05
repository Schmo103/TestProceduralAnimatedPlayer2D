class_name Grenade
extends Weapon



var equip_animation = "grenade_equip"
var attack_animation = "grenade_attack"
var attack_animation_2 = "grenade_attack_2"
var path = "torso/arm_left/hand_left/grenade"
var thrown_nade_path = preload("res://weapons/grenade/thrown_grenade.tscn")
var nade_speed = 1000
var nade_spawn_time = 0.5 #TEMPORARY :(
#this is how long the animation takes before actual throw


func attack() -> void:
	pass


func release():
	var thrown_nade = thrown_nade_path.instantiate()
	thrown_nade.global_position = player.violent_hand.global_position
	ProjectileManager.add_projectile(thrown_nade)
	thrown_nade.launch_to_mouse_pos(nade_speed, player.velocity)
