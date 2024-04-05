extends Node

var projectile_space : Node

func add_projectile(projectile :Node):
	projectile_space.add_child(projectile)
