class_name Roof
extends Area2D


func _ready():
	self.body_entered.connect(_on_Area2D_body_entered)
	self.body_exited.connect(_on_Area2D_body_exited)

func _on_Area2D_body_entered(body):
	if body is Player:
			open()

func _on_Area2D_body_exited(body):
	if body is Player:
			close()


func close():
	self.show()
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	print("closed")



func open():
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.15)
	tween.tween_callback(self.hide)
	print("opened")
