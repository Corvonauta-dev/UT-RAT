extends MeshInstance3D

@onready var mat1 := preload("res://assets/white.tres")
@onready var mat2 := preload("res://assets/green.tres")

var food = false

func _on_button_button_down():
	pass
	#fuelFood()
	

func fuelFood():
	if !food:
		set_surface_override_material(0,mat2)
		food = true
		$FoodArea/FoodAreaCollision.disabled = false
		$FoodAreaSmell/FoodAreaSmellCollision.disabled = false
		

func emptyFood():
	set_surface_override_material(0,mat1)
	$FoodArea/FoodAreaCollision.disabled = true
	$FoodAreaSmell/FoodAreaSmellCollision.disabled = true
	food = false
