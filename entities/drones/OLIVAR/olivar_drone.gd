extends CharacterBody3D

var owner_entity : Node
var movement_marker : Node
var move_target : Node
#@onready var attack_range = $attack_area
#@onready var attack_collision = $attack_area/CollisionShape2D
#@onready var interact_range = $interact_area
#@onready var detection_range = $detection_range
#@onready var timer = $Cooldown
#@onready var tooltip = $tooltip
@onready var camera = $Camera3D
@onready var turret_camera = $blockbench_export/body2/turret/mount/cannon/Camera3D
#@onready var thrust_pivot = $thruster_pivot
@onready var turret_base: Node3D = $blockbench_export/body2/turret
@onready var turret_pivot = $blockbench_export/body2/turret/mount
@onready var turret_elevation = $blockbench_export/body2/turret/mount/cannon
#@onready var projectile_spawn = $turret_pivot/projectile_spawn
#@onready var shoot_ray = $turret_pivot/RayCast2D
#@onready var inventory_manager = $inventory_manager
# lights
#@onready var body_light = $PointLight2D
#@onready var turret_light = $turret_pivot/PointLight2D
#@onready var thruster_light = $thruster_pivot/PointLight2D
# exported vars
#@export var projectile_scene : PackedScene
@export var debug = false
@export var SPEED = 10
@export var rotation_speed = 1.0
@export var sprint_speed = 200.0
@export var default_speed = 100.0
@export var team = ""
@export var cooldown = 0.1
@export var follow_dist = 10
@export var signal_range = 500
# standard vars
var has_owner = true
var can_connect = true
var connected = false
var modes = ["Sentry","AI","Player Control"]
var mode = 1
var turret_speed = 20

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	movement_marker = $"../Player"
	move_target = movement_marker
	#var turret_radius = attack_collision.get_shape().get_radius() 
	#shoot_ray.target_position = shoot_ray.target_position.normalized()
	#shoot_ray.target_position = (shoot_ray.target_position) * turret_radius
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if has_owner:
		if modes[mode - 1] == "Sentry":
			set_process_input(false)
			Sentry_mode(delta)
		elif modes[mode - 1] == "AI":
			set_process_input(false)
			AI_mode(delta)
		elif modes[mode - 1] == "Player Control":
			set_process_input(true)
			Player_Ctrl(delta)
		
		if Input.is_action_just_pressed("swap_view") and connected == true:
			if camera.current == true:
				turret_camera.make_current()
			else:
				camera.make_current()
		'''
		if global_position.distance_to(owner_entity.global_position) > signal_range:
			mode = 1
			can_connect = false
			owner_entity.hud.push_message("Drone connection offline.")
		else:
			can_connect = true
			owner_entity.hud.push_message("Drone connection online.")
		owner_entity.hud.connection = can_connect
		'''
func Sentry_mode(delta):
	velocity = Vector3.ZERO
	track_entity(delta)
	#attack()
	

func AI_mode(delta):
	track_entity(delta)
	if global_position.distance_to(move_target.global_position) > follow_dist:
		var direction = (move_target.global_position - global_position).normalized()
		
		# Calculate the rotation needed to face the movement target.
		var target_position = movement_marker.global_position
		
		# Create a temporary transform that faces the target.
		var target_transform = global_transform.looking_at(target_position)
		
		# Convert the current and desired rotations into quaternions.
		var current_rotation = global_basis.get_rotation_quaternion()
		var target_rotation = target_transform.basis.get_rotation_quaternion()
		
		# Smoothly rotate toward the desired orientation.
		global_basis = Basis(current_rotation.slerp(target_rotation, rotation_speed * delta))
		
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta)
		velocity.y = move_toward(velocity.y, 0, SPEED * delta)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta)
	#print(velocity)
	#move_and_slide()
	
func _input(event: InputEvent) -> void:
	# turret movement when the player is controlling
	if event is InputEventMouseMotion and GameGlobals.mouse_is_controling:
		if camera.current:
			rotate_y(deg_to_rad(event.relative.x * GameGlobals.mouse_sens))
			rotate_z(deg_to_rad(event.relative.y * GameGlobals.mouse_sens))
		if turret_camera.current:
			turret_pivot.rotate_y(deg_to_rad(-event.relative.x * GameGlobals.mouse_sens))
			turret_elevation.rotate_z(deg_to_rad(-event.relative.y * GameGlobals.mouse_sens))

func Player_Ctrl(delta):
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	var vert_input := Input.get_axis("down","up")
	var direction := (transform.basis * Vector3(input_dir.x, vert_input, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.y = direction.y * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	if Input.is_action_pressed("roll_left"):
		rotate_x(deg_to_rad(1))
	if Input.is_action_pressed("roll_right"):
		rotate_x(deg_to_rad(-1))
		
	move_and_slide()

'''
func attack():
	# attack logic
	if timer.is_stopped() and has_owner:
		for area in attack_range.get_overlapping_areas():
			if area.is_in_group("targetable") and (area.team != "neutral" and area.team != team):
				var aim = (area.global_position - turret_pivot.global_position).normalized()
				var angle_diff = rad_to_deg(turret_pivot.transform.x.angle_to(aim))
				if (turret_pivot.rotation_degrees + angle_diff) > -6 + rotation_degrees and (turret_pivot.rotation_degrees + angle_diff) < 166 + rotation_degrees:
					turret_pivot.look_at(area.global_position)
					shoot_ray.force_raycast_update()
					if debug:
						print("Colliding with:" + str(shoot_ray.get_collider()))
					if shoot_ray.get_collider() == area:
						shoot(area.global_position)
						timer.start(cooldown)
						break

func interaction():
	# interact logic
	for area in interact_range.get_overlapping_areas():
		if area.is_in_group("interactable") and (area != owner_entity and area != self):
			area.interact(self)
	for body in interact_range.get_overlapping_bodies():
		if body.is_in_group("interactable") and (body != owner_entity and body != self):
			body.interact(self)
				
func shoot(entity):
	turret_pivot.look_at(entity)
	var projectile = projectile_scene.instantiate() #instance projectile
	var direction = (entity - projectile_spawn.global_position).normalized()
	projectile.direction = direction
	projectile.team = team
	projectile.global_position = projectile_spawn.global_position
	projectile.owner_entity = self
	projectile.rotation = direction.angle()
	get_tree().current_scene.add_child(projectile)
	

func interact(entity):
	if not has_owner:
		owner_entity = entity
		print("Recieved owner " + str(owner_entity.name))
		team = owner_entity.team
		owner_entity.drone = self
		movement_marker = entity.get_node("marker_oli")
		print(movement_marker.name)
		has_owner = true
		tooltip.visible = false
		body_light.visible = true
		turret_light.visible = true
		thruster_light.visible = true
'''

func track_entity(delta):
	var target_position = move_target.global_position + Vector3(0,1.4,0) # 1.4 temp added to make aim at head

	# Get direction relative to the turret base.
	var direction = turret_base.global_transform.basis.inverse() * (target_position - turret_base.global_position).normalized()

	# Calculate yaw and pitch.
	var yaw = atan2(-direction.x, -direction.z)

	var pitch = atan2(direction.y,Vector2(direction.x, direction.z).length())

	# Create target rotations.
	var target_yaw = Quaternion(Vector3.UP, yaw + deg_to_rad(90))
	var target_pitch = Quaternion(Vector3.FORWARD, -pitch)

	# Smoothly interpolate.
	turret_pivot.quaternion = turret_pivot.quaternion.slerp(target_yaw, 5.0 * delta)

	turret_elevation.quaternion = turret_elevation.quaternion.slerp(target_pitch, 5.0 * delta)
