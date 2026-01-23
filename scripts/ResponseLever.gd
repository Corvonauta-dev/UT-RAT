extends MeshInstance3D
const ROTATION_SPEED := 15
@onready var click := $Click
@onready var food_dispenser: MeshInstance3D = $"../FoodDispenser"
@onready var food_area_smell_collision: CollisionShape3D = $"../FoodDispenser/FoodAreaSmell/FoodAreaSmellCollision"

func _on_button_button_down():
	pressLever()
	
func pressLever():
	click.play()
	rotate_z(deg_to_rad(ROTATION_SPEED))
	await get_tree().create_timer(0.3).timeout
	rotate_z(deg_to_rad(-ROTATION_SPEED))
	
