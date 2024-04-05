class_name GroundItem
extends Area2D


func _ready() -> void:
	add_to_group("GroundItem")

func pickup(player:Player):
	queue_free()
