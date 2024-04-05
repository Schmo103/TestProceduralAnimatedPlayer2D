extends Area2D

@onready var mech : Mech = $".."


func hide_prompt():
	mech.hide_prompt()

func show_prompt():
	mech.show_prompt()

func interact(who: Player):
	if mech.inside == false:
		mech.enter_mech(who)
	else:
		mech.exit_mech(who)
