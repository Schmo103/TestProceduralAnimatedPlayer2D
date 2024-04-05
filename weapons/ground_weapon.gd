class_name GroundWeapon
extends GroundItem



var weapon : Weapon


func pickup(player : Player ):
	if weapon != null:
		if player.add_to_inv(weapon):
			queue_free()
