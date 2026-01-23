extends NavigationAgent3D
class_name FollowTarget

@export var Speed = 5.0
@export var TurnSpeed = 0.3

var target : Node3D
var isTargetSet : bool = false
var targetPosition : Vector3 = Vector3.ZERO
var lastTargetPosition : Vector3 = Vector3.ZERO
var fixedTarget : bool = false
var is_stopped : bool = false

@onready var parent = get_parent() as CharacterBody3D

func _process(delta: float) -> void:
	if is_stopped:
		parent.velocity = Vector3.ZERO
		parent.move_and_slide()
		return
	if fixedTarget:
		go_to_location(targetPosition)
	else:
		go_to_location(target.global_position)
	parent.move_and_slide()

func SetFixedTarget(newTarget : Vector3) -> void:
	target = null
	targetPosition = newTarget
	fixedTarget = true
	isTargetSet = true
	is_stopped = false
	
func SetTarget(newTarget : Node3D) -> void:
	target = newTarget
	targetPosition = Vector3.ZERO
	fixedTarget = false
	isTargetSet = true
	is_stopped = false
	
func ClearTarget() -> void:
	target = null
	targetPosition = Vector3.ZERO
	isTargetSet = false
	is_stopped = false

func Stop() -> void:
	target = null
	targetPosition = Vector3.ZERO
	isTargetSet = false
	is_stopped = true

func go_to_location(targetPosition : Vector3):
	if not isTargetSet or lastTargetPosition != targetPosition:
		set_target_position(targetPosition)
		lastTargetPosition = targetPosition
		isTargetSet = true
		
	var lookDir = atan2(parent.velocity.x, parent.velocity.z)
	parent.rotation.y = lerp_angle(parent.rotation.y, lookDir, TurnSpeed)
	
	if is_navigation_finished():
		isTargetSet = false
		return
		
	var nextPathPosition = get_next_path_position()
	var currentEnemyPosition = parent.global_position
	var newVelocity = (nextPathPosition - currentEnemyPosition).normalized() * Speed
	
	if avoidance_enabled:
		set_velocity(newVelocity.move_toward(newVelocity, 0.25))
	else:
		parent.velocity = newVelocity.move_toward(newVelocity, 0.25)
	

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	parent.velocity = parent.velocity.move_toward(safe_velocity, 0.25)
