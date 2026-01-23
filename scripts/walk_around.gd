extends Node3D
class_name WalkAround

@onready var target: Marker3D = $TargetArm/Target
@onready var target_arm: SpringArm3D = $TargetArm

func GetNextPoint() -> Vector3:
	randomize()
	var angle = deg_to_rad(randi_range(-120, 120))
	var distance = randf_range(1, 10)
	rotation.y = angle
	target_arm.spring_length = distance
	return target.global_position
