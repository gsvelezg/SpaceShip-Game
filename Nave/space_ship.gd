extends RigidBody3D

@export var masa: int = 2 # En kg

var on_floor: bool = false

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	var contact_count := state.get_contact_count()

	if contact_count == 0:
		on_floor = false
		return

	var local_up := state.transform.basis.y.normalized()

	on_floor = false
	for i in contact_count:
		var normal := state.get_contact_local_normal(i)
		if normal.dot(local_up) > 0.99: 
			on_floor = true
			break


func GetNeighbors():
	return $neighborArea3D.get_overlapping_bodies()

func _init() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


var gravity_dir = Vector3(0,0,0)
var gravity_force = 0
const gConstant = 2

func calcGravitiy():
	var isNearPlanet = GetNeighbors().size() > 0
	if(isNearPlanet):
		var planet = GetNeighbors()[0].get_parent()
		
		gravity_dir = (planet.position - position)
		gravity_force = gConstant*(planet.masa * masa)/gravity_dir.length()
		gravity_dir = gravity_dir.normalized()
	else:
		gravity_force = 0
		gravity_dir = Vector3.ZERO

var yaw_rate = 0.0
var pitch_rate = 0.0
const ROLL_DAMP = 3.0 
func calcMouseRotations(delta: float):
	var mouse = Input.get_last_mouse_velocity()
	var sensitivity = 0.05

	yaw_rate = -mouse.x * sensitivity* delta
	pitch_rate = -mouse.y * sensitivity* delta

	# pasar angular_velocity (global) a espacio local de la nave
	var local_ang_vel = global_transform.basis.inverse() * angular_velocity

	local_ang_vel.y = yaw_rate      # tú mandas en yaw
	local_ang_vel.x = pitch_rate    # tú mandas en pitch
	local_ang_vel.z *= 1.0 - min(ROLL_DAMP * delta, 1.0)  # roll decae solo, no lo fuerzas a 0 directo

	angular_velocity = global_transform.basis * local_ang_vel

var velocity = Vector3(0,0,0)
const SPEED = 20


func _physics_process(delta: float) -> void:
	calcGravitiy()
	calcMouseRotations(delta)
	
	if(on_floor):
		angular_velocity = Vector3.ZERO
	print(on_floor)
	
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var input_altura = Input.get_axis("shift","space")

	var direction := (transform.basis * Vector3(input_dir.x, input_altura, input_dir.y)).normalized()
	
	linear_velocity += gravity_dir * gravity_force * delta
	if direction:
		linear_velocity += direction * SPEED * delta
