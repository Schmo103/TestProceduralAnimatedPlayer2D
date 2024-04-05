class_name Player
extends CharacterBody2D


@onready var arm1 = $torso/arm_left
@onready var arm2 = $torso/arm_right
@onready var body = $torso
@onready var anim_p = $AnimationPlayer

@onready var pickup_area : Area2D = %pickup_area

@onready var enter_spot : Area2D = $vehicle_enter_spot
@onready var collision : CollisionShape2D = $CollisionShape2D

@export var bomb : PackedScene

@export var speed = 300
@export var sprint_speed = 1200
@export var dash_speed = 2000  # Adjust this value to control the dash speed
@onready var friction = 0.1
@export var acceleration = 0.1
@export var body_rotation_speed = 6

@export var violent_hand : Node2D

@onready var hook := $grapple/hook
@onready var hook_shape := $grapple/hook/CollisionShape2D
@onready var line := $grapple/Line2D

var inv_slot_1 : Weapon
var inv_slot_2 : Weapon

const HOOK_MAX_LENGTH := 2000.0
const HOOK_SPEED := 5000.0
const PLAYER_HOOK_SPEED := 2750.0

var grappling = false
var attacking = false
var sprinting = false
var idle = false
var dashing = false  # New variable to track if the player is dashing
var mouse_position = Vector2()
var prev_angle_difference = 0.0

enum PlayerStates {DEFAULT, HOOKED, INVEHICLE}
enum HookStates {NONE, EXTEND, RETRACT_TO_PLAYER}

var hook_direction: Vector2
@export var player_state: PlayerStates = PlayerStates.DEFAULT
var hook_state: HookStates = HookStates.NONE

func _ready():
	pass

func entering_mech():
	pass

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
	if Input.is_action_pressed("sprint"):
		sprinting = true
	elif !Input.is_action_pressed("sprint"):
		if sprinting:
			if !dashing:
				anim_p.stop()
		sprinting = false
	if Input.is_action_just_pressed("dash"):
		dashing = true
	return input

# This represents the player's inertia.
var push_force = 80.0
func _physics_process(delta):
	match player_state:
		PlayerStates.DEFAULT:
			#print("DEFAULT")
			var direction = get_input()
			
			if dashing:
				velocity = (mouse_position - global_position).normalized() * dash_speed
				animate("dash")
			elif direction.length() > 0:
				if !dashing:
					if !sprinting:
						velocity = velocity.lerp(direction.normalized() * speed, acceleration)
						animate("walk")
					else:
						velocity = velocity.lerp(direction.normalized() * sprint_speed, acceleration)
						animate("run")
			else:
				velocity = velocity.lerp(Vector2.ZERO, friction)
				if !dashing and !attacking:
					animate("still")
			
			move_and_slide()
			
			
			for i in get_slide_collision_count():
				var c = get_slide_collision(i)
				if c.get_collider() is RigidBody2D:
					c.get_collider().apply_central_impulse(-c.get_normal() * push_force)
			
			
			if !clambering:
				# Update the mouse position
				mouse_position = get_global_mouse_position()
				
				# Rotate the arms instantly towards the mouse
				
				#arm1.look_at(mouse_position)
				#arm2.look_at(mouse_position)
				body.look_at(mouse_position)
				$CollisionShape2D.look_at(mouse_position)
				%pickup_area.look_at(mouse_position)
				#arm1.rotate(-89.31)
				#arm2.rotate(-89.8)
				#animate("still")

				## Interpolate the body rotation towards the mouse
				#var body_angle = body.rotation
				#var target_angle = (mouse_position - body.global_position).angle()
				#var angle_difference = wrapf(target_angle - body_angle, -PI, PI)
#
#
				#if abs(angle_difference) > 0.01:  # Adjust the threshold as needed
					#if sign(prev_angle_difference) == sign(angle_difference) or prev_angle_difference == 0.0:
						#body.rotation += clamp(angle_difference, -body_rotation_speed * delta, body_rotation_speed * delta)
					#prev_angle_difference = angle_difference
		PlayerStates.HOOKED:
			#print("HOOKED")
			if !in_vehicle:
				grappling = true
				animate("grapple")
				
				var is_collision := move_and_collide(velocity * delta)
				
				if is_collision:
					player_state = PlayerStates.DEFAULT
					grappling = false
					animate("walk")
					hide_hook()

				elif global_position.distance_to(hook.global_position) <= PLAYER_HOOK_SPEED * delta:
					global_position = hook.global_position
					player_state = PlayerStates.DEFAULT
					grappling = false
					animate("walk")
					hide_hook()
		PlayerStates.INVEHICLE:
			#print("INVEHICLE")
			self.global_position = current_vehicle.global_position
			self.rotation = current_vehicle.rotation
			print("player rotation:")
			print(self.rotation)
			print("mech rotation:")
			print(current_vehicle.rotation)

		
	match hook_state:
		HookStates.EXTEND:
			if !in_vehicle:
				hook.global_position += hook_direction * HOOK_SPEED * delta
				if hook.global_position.distance_to(global_position) >= HOOK_MAX_LENGTH:
					hook_state = HookStates.RETRACT_TO_PLAYER
					hook_shape.set_disabled.call_deferred(true)
				
		HookStates.RETRACT_TO_PLAYER:
			if !in_vehicle:
				hook.global_position += hook.global_position.direction_to(global_position) * HOOK_SPEED * delta
				if hook.global_position.distance_to(global_position) <= HOOK_SPEED * delta:
					hook_state = HookStates.NONE
					hide_hook()
	
	if hook.visible:
		line.points[1] = to_local(hook.global_position)

var clambering = false
func animate(animation):
	if !attacking:
		if !dashing and !grappling:
			if animation == "run":
				anim_p.play("run",-1,sprint_speed/485.7)
			elif animation == "walk":
				anim_p.play("walk")
			elif animation == "still":
				anim_p.play("still")
		elif animation == "dash":
			anim_p.play("dash")
		elif animation == "clamber":
			print("clamber")
			anim_p.play("clamber")
		elif animation == "grapple":
			anim_p.play("grapple")
	elif animation == "staff_attack":
		anim_p.play("staff_attack",-1,2)
	elif animation == "grenade_attack":
		anim_p.play("grenade_attack",-1,1.5)

func _on_animation_player_animation_finished(anim_name):
	match anim_name:
		"dash":
			dashing = false
		"clamber":
			clambering = false
		"staff_attack":
			attacking = false
		"grenade_attack":
			attacking = false
		"grapple":
			grappling = false


func _input(event: InputEvent) -> void:
	if !in_vehicle:
		if event.is_action_pressed("click") and hook_state == HookStates.NONE:
			hook.global_position = global_position
			hook_state = HookStates.EXTEND
			hook_direction = get_local_mouse_position().normalized().rotated(PI/2)
			hook.show()
			line.show()
			hook_shape.disabled = false
			
		elif event.is_action_pressed("rclick"):
			#var instance = bomb.instantiate()
			#self.get_parent().add_child(instance)
			#instance.global_position = get_viewport().get_mouse_position()
			#instance.emitting = true
			
			if inv_slot_1 != null or inv_slot_2 != null:
				if current_inv_slot == 1:
					inv_slot_1.attack()
					attacking = true
					animate(inv_slot_1.attack_animation)
					print(inv_slot_1.attack_animation)
					print("slot 1 attacking")
				elif current_inv_slot == 2:
					inv_slot_2.attack()
					attacking = true
					animate(inv_slot_2.attack_animation)
					print("slot 2 attacking")
	

func _on_hook_body_entered(body1):
	if !in_vehicle:
		if body1 != ColorRect:
			player_state = PlayerStates.HOOKED
			velocity = global_position.direction_to(hook.global_position) * PLAYER_HOOK_SPEED
			hook_state = HookStates.NONE
			hook_shape.set_disabled.call_deferred(true)

func hide_hook() -> void:
	hook.hide()
	line.hide()
	hook_shape.set_disabled.call_deferred(true)


func _process(delta):
	if Input.is_action_just_pressed("interact"):
		for area in enter_spot.get_overlapping_areas():
			if area.is_in_group("interactable"):
				area.interact(self)
	if Input.is_action_just_pressed("pickup"):
		pickup_items()
	if Input.is_action_just_pressed("switch_weapon"):
		if inv_slot_1 != null and inv_slot_2 != null:
			switch_weapon()
			print("switch_weapon_caled")



func _on_vehicle_enter_spot_area_entered(area):
	if area.is_in_group("interactable"):
		area.show_prompt()


func _on_vehicle_enter_spot_area_exited(area):
	if area.is_in_group("interactable"):
		area.hide_prompt()

var in_vehicle = false
var current_vehicle = null
func enter_mech(seat_pos, mech: Mech):
	clambering = true
	in_vehicle = true
	collision.disabled = true
	animate("clamber")
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", seat_pos, 1)
	tween.connect("finished",done_entering)
	current_vehicle = mech

func exit_mech(exit_pos, mech: Mech):
	in_vehicle = false
	collision.disabled = false
	mech.exiting = true
	animate("clamber")
	var tween = get_tree().create_tween()
	tween.tween_property(self, "position", exit_pos, 1)
	tween.connect("finished",done_exiting)

func done_entering():
	player_state = PlayerStates.INVEHICLE
	current_vehicle.inside = true

func done_exiting():
	current_vehicle.exiting = false
	current_vehicle.inside = false
	current_vehicle = null
	player_state = PlayerStates.DEFAULT


func pickup_items():
	for item in pickup_area.get_overlapping_areas():
		print("item in area")
		if item is GroundItem:
			item.pickup(self)
			print("item picked up")
			

var current_inv_slot = 1
func add_to_inv(weapon : Weapon):
	if inv_slot_1 == null:
		inv_slot_1 = weapon
		equip_weapon(weapon)
		print("invslot1 is full")
	elif inv_slot_2 == null:
		inv_slot_2 = weapon
		#equip_weapon(weapon)
		print("invslot2 is full")
	else:
		return false
	return true


func equip_weapon(weapon : Weapon):
		get_node(weapon.path).visible = true
		animate(weapon.equip_animation)
		weapon.player = self
		#print(weapon.path)

func switch_weapon():
	if current_inv_slot == 1:
		current_inv_slot = 2
		get_node(inv_slot_1.path).visible = false
		equip_weapon(inv_slot_2)
		
	elif current_inv_slot == 2:
		current_inv_slot = 1
		get_node(inv_slot_2.path).visible = false
		equip_weapon(inv_slot_1)
		

func release_item():#primarily for letting go of grenade
	if current_inv_slot == 1:
		inv_slot_1.release()
		#print("releasing slot 1")
	elif current_inv_slot == 2:
		inv_slot_2.release()
		#print("releasing slot 2")
	#print("current inv slot: " + str(inv_slot_1))
	
