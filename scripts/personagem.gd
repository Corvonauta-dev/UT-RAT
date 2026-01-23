extends CharacterBody3D

# ==============================================================================
# SETTINGS AND REFERENCES
# ==============================================================================
@export var walkSpeed : float = 5.0
@export var runSpeed : float = 10.0

# --- Scene Node References ---
@onready var follow_target: FollowTarget = $FollowTarget
@onready var walk_around: WalkAround = $WalkAround
@onready var food_dispenser: MeshInstance3D = $"../NavigationRegion3D/Map/FoodDispenser"
@onready var response_lever: MeshInstance3D = $"../NavigationRegion3D/Map/ResponseLever"
@onready var ap: AnimationPlayer = $Rat/AnimationPlayer
@onready var animation_tree: AnimationTree = $Rat/AnimationTree

# --- UI References ---
@onready var ui_layer = $"../UI" 
@onready var label: RichTextLabel = $"../UI/VBoxContainer2/PanelContainer/Label" 
@onready var lever_button = $"../UI/VBoxContainer2/Button"
@onready var next_phase_button = $"../UI/VBoxContainer2/Button2"
@onready var info_button = $"../UI/VBoxContainer2/InfoButton" 
@onready var smell_area: Area3D = $Smell

# --- Progress Bars ---
@onready var FeederProgress: TextureProgressBar = $"../UI/VBoxContainer/FeederProgress"
@onready var FeederProgressLabel: Label = $"../UI/VBoxContainer/FeederProgressLabel"
@onready var FeederProgressTitle: Label = $"../UI/VBoxContainer/FeederProgressTitle"

@onready var GoToLeverTitle: Label = $"../UI/VBoxContainer/GoToLeverTitle"
@onready var GoToLeverProgress: TextureProgressBar = $"../UI/VBoxContainer/GoToLeverProgress"
@onready var PressLeverTitle: Label = $"../UI/VBoxContainer/PressLeverTitle"
@onready var PressLeverProgress: TextureProgressBar = $"../UI/VBoxContainer/PressLeverProgress"
@onready var SequenceProgressTitle: Label = $"../UI/VBoxContainer/SequenceProgressTitle"
@onready var SequenceProgress: TextureProgressBar = $"../UI/VBoxContainer/SequenceProgress"
@onready var SequenceProgressLabel: Label = $"../UI/VBoxContainer/SequenceProgressLabel"

@onready var ExploreProgress: TextureProgressBar = $"../UI/VBoxContainer/ExploreProgress" 
@onready var ExploreTitle: Label = $"../UI/VBoxContainer/ExploreTitle"
@onready var ExtinctionTimerLabel: Label = $"../UI/VBoxContainer/ExtinctionTimerLabel"

# ==============================================================================
# RL BRAIN
# ==============================================================================
@onready var rl_agent = preload("res://scripts/RLAgent.gd").new()
var prev_state: int = -1
var prev_action: int = -1
var pending_reward: float = 0.0

const MAX_Q_PHASE_3 = 3.0 
const MAX_Q_EXPLORE = 2.5 

var start_epsilon: float = 0.5      
var min_epsilon: float = 0.05       
var decay_rate: float = 0.95       

# ==============================================================================
# EXTERNAL DATA
# ==============================================================================
var experiment_data_external: Dictionary = {}
const BACKUP_THEORY = "[center][b]Erro ao carregar JSON.[/b][/center]"

# ==============================================================================
# CONTROL VARIABLES
# ==============================================================================
var current_phase: int = 0
var consecutive_feeds: int = 0
var consecutive_presses: int = 0
const FEEDS_CRITERION: int = 10 
const PRESSES_CRITERION: int = 10
var extinction_timer: float = 0.0
const EXTINCTION_CRITERION_SECONDS: float = 600.0 # 10 minutes
var lever_pressed_successfully: bool = false
var criterion_met_announced: bool = false
var info_panel: PanelContainer 
var current_animation_state: String = "walk"
var is_busy: bool = false 

# ==============================================================================
# ENGINE CALLBACKS
# ==============================================================================

func _ready() -> void:
	randomize()
	animation_tree.animation_finished.connect(_on_animation_tree_animation_finished)
	if label: label.mouse_filter = Control.MOUSE_FILTER_STOP
	
	_load_texts_from_file()
	_create_custom_info_panel()
	
	# Brain initialization (repeated on reset)
	_reset_brain()
	
	_change_phase(1)
	print("[Experiment] Ready. Endless Cycle Mode.")

func _process(delta: float) -> void:
	_update_animation_tree()
	
	# Extinction timer logic
	if current_phase == 4:
		extinction_timer -= delta 
		
		# Update the timer text
		var minutes = int(extinction_timer) / 60
		var seconds = int(extinction_timer) % 60
		if extinction_timer < 0: extinction_timer = 0
		ExtinctionTimerLabel.text = "%02d:%02d" % [minutes, seconds]
		
		# --- CHANGE: END OF PHASE 4 NO LONGER LOCKS ---
		if extinction_timer <= 0:
			# If the button is still disabled, time has just run out
			if next_phase_button.disabled:
				next_phase_button.disabled = false # Enable the button to restart
				next_phase_button.text = "REINICIAR" # Visual feedback on the button (optional)
				label.text += "\n\n[color=green][b]EXTINÇÃO CONCLUÍDA![/b]\nO comportamento cessou. Clique para reiniciar o experimento.[/color]"
				print("[Experiment] Extinction Timer finished. Waiting for user reset.")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

# ==============================================================================
# DATA AND SYSTEM FUNCTIONS
# ==============================================================================

func _reset_brain():
	# Helper function to clear the rat's mind
	rl_agent.epsilon = start_epsilon
	rl_agent.q_table = {} # Wipe memory completely (tabula rasa)
	
	# Re-inject "Natural Instinct" so it doesn't stay idle
	rl_agent.set_q_value(0, 0, 1.0) 
	rl_agent.set_q_value(1, 0, 1.0) 
	rl_agent.set_q_value(2, 0, 1.0) 

func _load_texts_from_file():
	var file_path = "res://scripts/textos_experimento.json"
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(json_text) == OK:
			experiment_data_external = json.data
		else:
			print("[Erro] JSON inválido.")

func _create_custom_info_panel():
	info_panel = PanelContainer.new()
	info_panel.name = "InfoOverlay"
	info_panel.anchors_preset = Control.PRESET_CENTER
	info_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	info_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	info_panel.custom_minimum_size = Vector2(800, 600)
	info_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	info_panel.visible = false 
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.08, 0.85) 
	style.set_border_width_all(2)
	style.border_color = Color(0.4, 0.4, 0.4, 1.0)
	style.set_corner_radius_all(16)
	style.shadow_size = 10
	style.shadow_color = Color(0,0,0,0.5)
	info_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	var margin_container = MarginContainer.new()
	margin_container.add_theme_constant_override("margin_top", 30)
	margin_container.add_theme_constant_override("margin_left", 30)
	margin_container.add_theme_constant_override("margin_right", 30)
	margin_container.add_theme_constant_override("margin_bottom", 30)
	
	info_panel.add_child(margin_container)
	margin_container.add_child(vbox)
	
	var title_lbl = Label.new()
	title_lbl.text = "TEORIA: CAIXA DE SKINNER"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(title_lbl)
	
	var rtl = RichTextLabel.new()
	rtl.bbcode_enabled = true
	if experiment_data_external.has("teoria"):
		rtl.text = experiment_data_external["teoria"]
	else:
		rtl.text = BACKUP_THEORY
	rtl.size_flags_vertical = Control.SIZE_EXPAND_FILL 
	rtl.fit_content = false 
	rtl.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	vbox.add_child(rtl)
	
	var close_btn = Button.new()
	close_btn.text = "FECHAR"
	close_btn.custom_minimum_size = Vector2(150, 50)
	close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_btn.pressed.connect(_on_close_info_pressed)
	vbox.add_child(close_btn)
	
	if ui_layer:
		ui_layer.add_child(info_panel)
		info_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	else:
		add_child(info_panel)

	if info_button:
		info_button.pressed.connect(_on_open_info_pressed)

func _on_open_info_pressed():
	if info_panel:
		info_panel.visible = true
		get_tree().paused = true

func _on_close_info_pressed():
	if info_panel:
		info_panel.visible = false
		get_tree().paused = false

# ==============================================================================
# PHASE MANAGEMENT (WITH RESET)
# ==============================================================================

func _change_phase(new_phase: int) -> void:
	current_phase = new_phase
	print("[Experiment] Entering Phase ", new_phase)
	
	# Reset control variables
	is_busy = false
	consecutive_feeds = 0
	consecutive_presses = 0
	extinction_timer = 0.0
	prev_state = -1
	prev_action = -1
	pending_reward = 0.0
	lever_pressed_successfully = false
	criterion_met_announced = false
	
	_hide_all_ui()
	
	# Load phase text
	var phase_key = str(new_phase)
	if experiment_data_external.has("fases") and experiment_data_external["fases"].has(phase_key):
		var dados = experiment_data_external["fases"][phase_key]
		label.text = "%s\n\n%s\n\n%s" % [dados["titulo"], dados["instrucao"], dados["criterio"]]
	
	match current_phase:
		1: # Baseline (OR RESTART)
			next_phase_button.disabled = false
			next_phase_button.text = "Próxima Fase" # Ensure the text returns to normal if it was set to "REINICIAR"
			lever_button.disabled = true
			
			# --- THE REAL RESET HAPPENS HERE ---
			_reset_brain()
			print("[System] Brain Reset for new experiment run.")
			
			_show_explore_ui()
			make_base_decision()
			
		2: # Feeder Training
			next_phase_button.disabled = true
			lever_button.disabled = false
			
			FeederProgress.max_value = FEEDS_CRITERION 
			FeederProgress.value = 0
			FeederProgressLabel.text = "Aprendizado: Iniciando... (0/%d)" % FEEDS_CRITERION
			
			FeederProgress.visible = true
			FeederProgressLabel.visible = true
			FeederProgressTitle.visible = true 
			_show_explore_ui()
			
		3: # Shaping
			next_phase_button.disabled = true
			lever_button.disabled = false
			
			GoToLeverTitle.visible = true
			GoToLeverProgress.visible = true
			PressLeverTitle.visible = true
			PressLeverProgress.visible = true
			SequenceProgressTitle.visible = true
			SequenceProgress.visible = true
			SequenceProgressLabel.visible = true
			_show_explore_ui()
			
			GoToLeverProgress.max_value = 1.0 
			PressLeverProgress.max_value = 1.0 
			SequenceProgress.max_value = PRESSES_CRITERION 
			
			_update_learning_graphs() 
			SequenceProgress.value = 0
			SequenceProgressLabel.text = "%d / %d" % [0, PRESSES_CRITERION]

		4: # Extinction
			next_phase_button.disabled = true
			lever_button.disabled = true 
			
			var mat_off = load("res://Ratinho - Copia/white.tres") 
			if mat_off and food_dispenser:
				food_dispenser.set_surface_override_material(0, mat_off)
			
			GoToLeverTitle.visible = true
			GoToLeverProgress.visible = true
			PressLeverTitle.visible = true
			PressLeverProgress.visible = true
			_show_explore_ui()
			
			GoToLeverProgress.max_value = 1.0 
			PressLeverProgress.max_value = 1.0
			
			_update_learning_graphs()
			
			extinction_timer = EXTINCTION_CRITERION_SECONDS 
			ExtinctionTimerLabel.text = "10:00"
			ExtinctionTimerLabel.visible = true 
			rl_agent.epsilon = 0.1 
			
		5: # END STATE (no longer used; now loops back to 1)
			pass

func _show_explore_ui():
	if ExploreProgress: 
		ExploreProgress.visible = true
		ExploreTitle.visible = true
		ExploreProgress.max_value = 1.0

func _hide_all_ui() -> void:
	FeederProgress.visible = false
	FeederProgressLabel.visible = false
	FeederProgressTitle.visible = false 
	GoToLeverTitle.visible = false
	GoToLeverProgress.visible = false
	PressLeverTitle.visible = false
	PressLeverProgress.visible = false
	SequenceProgressTitle.visible = false
	SequenceProgress.visible = false
	SequenceProgressLabel.visible = false
	ExtinctionTimerLabel.visible = false 
	if ExploreProgress: ExploreProgress.visible = false
	if ExploreTitle: ExploreTitle.visible = false

# ==============================================================================
# DECISION AND ANIMATION
# ==============================================================================

func make_base_decision() -> void:
	if is_busy:
		return
		
	match current_phase:
		1: 
			if randf() < 0.05: 
				_play_random_idle_animation()
			else:
				follow_target.SetFixedTarget(walk_around.GetNextPoint())
				current_animation_state = "walk"
		2: 
			var current_state_f2 : int = 1 if food_dispenser.food else 0
			rl_agent.update_q(prev_state, prev_action, pending_reward, current_state_f2)
			pending_reward = 0.0
			
			_update_learning_graphs()
			
			var actions_f2 : Array = [0] 
			if current_state_f2 == 1:
				actions_f2.append(2)
			var action_f2 : int = rl_agent.choose_action(current_state_f2, actions_f2)
			
			if action_f2 == 0: pending_reward += 0.05 
			prev_state = current_state_f2
			prev_action = action_f2
			_execute_chosen_action(action_f2)
			
		3, 4: 
			var current_state : int = 1 if food_dispenser.food else 0
			rl_agent.update_q(prev_state, prev_action, pending_reward, current_state)
			pending_reward = 0.0
			
			_update_learning_graphs() 
			
			var actions = _get_available_actions(current_state)
			var action : int = rl_agent.choose_action(current_state, actions)
			
			if action == 0: pending_reward += 0.05
			prev_state = current_state
			prev_action = action
			_execute_chosen_action(action)

func _execute_chosen_action(action: int):
	if action == 1: 
		follow_target.SetFixedTarget(response_lever.global_position)
		current_animation_state = "walk"
	elif action == 2: 
		follow_target.SetFixedTarget(food_dispenser.global_position)
		current_animation_state = "walk"
	else: 
		if randf() < 0.25: 
			_play_random_idle_animation()
		else:
			follow_target.SetFixedTarget(walk_around.GetNextPoint())
			current_animation_state = "walk"

func _play_random_idle_animation():
	var roll = randi() % 3
	match roll:
		0: current_animation_state = "SHAKE_EARS"
		1: current_animation_state = "QUADRUPED_LOOK"
		2: current_animation_state = "BIPEDAL_SNIFF"
	is_busy = true 
	follow_target.Stop()

# ==============================================================================
# INTERACTIONS
# ==============================================================================

func _on_next_phase_button_pressed():
	if current_phase < 4:
		_change_phase(current_phase + 1)
	elif current_phase == 4 and extinction_timer <= 0:
		# LOOP LOGIC: When phase 4 ends, return to phase 1 (which resets the brain)
		_change_phase(1)

func _on_lever_button_pressed():
	match current_phase:
		2: 
			food_dispenser.fuelFood()
		3: 
			var is_near = is_rat_near_lever()
			var is_facing = is_rat_facing_lever()
			if is_near:
				rl_agent.set_q_value(2, 1, rl_agent.get_q_value(2, 1) + 0.3) 
				food_dispenser.fuelFood()
			elif is_facing:
				rl_agent.set_q_value(0, 1, rl_agent.get_q_value(0, 1) + 0.3) 
				food_dispenser.fuelFood()
			else:
				print("[UI] Ignorado. Angulo: ", get_rat_facing_dot())
			_update_learning_graphs()

func _on_follow_target_navigation_finished() -> void:
	if is_busy: return
	# In phase 5 (if it existed) we'd stop, but now we loop to 1, so < 5 is always true
	if current_phase <= 5: make_base_decision()

func _on_smell_area_entered(area: Area3D) -> void:
	if is_busy: return
	if area is Lever: _handle_lever_interaction()
	elif area is Food: _handle_food_interaction()
	elif area is Wall:
		follow_target.Stop()
		current_animation_state = "walk"
		make_base_decision()

func _on_animation_tree_animation_finished(anim_name: StringName) -> void:
	var anim_str = String(anim_name)
	
	if anim_str.contains("SHAKE_EARS") or anim_str.contains("QUADRUPED_LOOK") or anim_str.contains("BIPEDAL_SNIFF"):
		is_busy = false 
		make_base_decision()
	elif anim_str.contains("GROOM_FACE"):
		is_busy = false
		if current_phase == 2: lever_button.disabled = false
		if not get_tree().paused: make_base_decision()
	elif anim_str.contains("BIPEDAL_LOOK"): 
		if current_phase == 3 or current_phase == 4:
			is_busy = false
			make_base_decision()

# ==============================================================================
# HELPERS & GRAPH UPDATES
# ==============================================================================

func _get_available_actions(state: int) -> Array:
	var actions: Array = [0] 
	if state == 1 or state == 3: actions.append(2)
	if current_phase >= 3:
		var conhecimento_ir_barra = rl_agent.get_q_value(0, 1) 
		var limiar_aprendizado = 0.7 
		if state == 2: 
			if conhecimento_ir_barra > limiar_aprendizado: actions.append(1) 
		if state == 0: actions.append(1)
	return actions

func _update_learning_graphs() -> void:
	var learn_to_go = rl_agent.get_q_value(0, 1) 
	var learn_to_press = rl_agent.get_q_value(2, 1) 
	var learn_explore = rl_agent.get_q_value(0, 0) 
	
	if ExploreProgress:
		var norm_explore = clamp(learn_explore / MAX_Q_EXPLORE, 0.0, 1.0)
		ExploreProgress.value = norm_explore
	
	if current_phase >= 3:
		var norm_go = 0.0
		var norm_press = 0.0
		if current_phase == 4:
			var extinction_visual_factor = 0.8
			norm_go = clamp((learn_to_go / MAX_Q_PHASE_3) * extinction_visual_factor, 0.0, 1.0)
			norm_press = clamp((learn_to_press / MAX_Q_PHASE_3) * extinction_visual_factor, 0.0, 1.0)
		else:
			norm_go = clamp(learn_to_go / MAX_Q_PHASE_3, 0.0, 1.0)
			norm_press = clamp(learn_to_press / MAX_Q_PHASE_3, 0.0, 1.0)
		GoToLeverProgress.value = norm_go
		PressLeverProgress.value = norm_press

func _handle_lever_interaction() -> void:
	match current_phase:
		3, 4:
			var lever_state : int = 3 if food_dispenser.food else 2
			rl_agent.update_q(prev_state, prev_action, pending_reward, lever_state)
			_update_learning_graphs() 
			pending_reward = 0.0
			var actions = _get_available_actions(lever_state)
			var action : int = rl_agent.choose_action(lever_state, actions)
			
			if current_phase == 4 and action == 1:
				pending_reward -= 0.05 
			
			prev_state = lever_state
			prev_action = action
			if action == 1:
				is_busy = true
				current_animation_state = "lever"
				follow_target.Stop()
				response_lever.pressLever()
				if current_phase == 3:
					if lever_pressed_successfully:
						consecutive_presses = 0
						SequenceProgress.value = 0
						SequenceProgressLabel.text = "%d / %d" % [0, PRESSES_CRITERION]
					lever_pressed_successfully = true
					pending_reward += 1.0
					if rl_agent.epsilon > min_epsilon: rl_agent.epsilon *= decay_rate
					food_dispenser.fuelFood() 
				else: 
					extinction_timer = EXTINCTION_CRITERION_SECONDS 
					ExtinctionTimerLabel.text = "10:00"
			else:
				follow_target.SetFixedTarget(walk_around.GetNextPoint())
				current_animation_state = "walk"

func _handle_food_interaction() -> void:
	if food_dispenser.food:
		is_busy = true
		current_animation_state = "eating"
		follow_target.Stop()
		food_dispenser.emptyFood()
		
		match current_phase:
			2:
				pending_reward += 1.0
				var current_state = 0
				rl_agent.update_q(prev_state, prev_action, pending_reward, current_state)
				pending_reward = 0.0
				consecutive_feeds += 1
				FeederProgress.value = consecutive_feeds
				FeederProgressLabel.text = "Coletas: %d / %d" % [consecutive_feeds, FEEDS_CRITERION]
				if consecutive_feeds >= FEEDS_CRITERION:
					next_phase_button.disabled = false
					if not criterion_met_announced:
						label.text += "\n\n[color=green][b]CRITÉRIO ATINGIDO! Pressione 'Próxima Fase'.[/b][/color]"
						criterion_met_announced = true
			3:
				var current_state = 0
				rl_agent.update_q(prev_state, prev_action, pending_reward, current_state)
				_update_learning_graphs() 
				pending_reward = 0.0
				if lever_pressed_successfully:
					consecutive_presses += 1
					lever_pressed_successfully = false 
				else:
					consecutive_presses = 0 
				SequenceProgress.value = consecutive_presses
				SequenceProgressLabel.text = "%d / %d" % [consecutive_presses, PRESSES_CRITERION]
				if consecutive_presses >= PRESSES_CRITERION:
					next_phase_button.disabled = false
					if not criterion_met_announced:
						label.text += "\n\n[color=green][b]COMPORTAMENTO APRENDIDO! Pressione 'Próxima Fase'.[/b][/color]"
						criterion_met_announced = true

func is_rat_near_lever() -> bool:
	for area in smell_area.get_overlapping_areas():
		if area is Lever: return true
	return false

func is_rat_near_food() -> bool:
	for area in smell_area.get_overlapping_areas():
		if area is Food: return true
	return false

func get_rat_facing_dot() -> float:
	var rat_forward = -global_transform.basis.z.normalized()
	var to_lever = (response_lever.global_position - global_position).normalized()
	return -rat_forward.dot(to_lever)

func is_rat_facing_lever() -> bool:
	return get_rat_facing_dot() > 0.6

func _update_animation_tree() -> void:
	animation_tree.set("parameters/conditions/WALK", current_animation_state == "walk")
	animation_tree.set("parameters/conditions/BIPEDAL_LOOK", current_animation_state == "lever")
	animation_tree.set("parameters/conditions/GROOM_FACE", current_animation_state == "eating")
	animation_tree.set("parameters/conditions/SHAKE_EARS", current_animation_state == "SHAKE_EARS")
	animation_tree.set("parameters/conditions/QUADRUPED_LOOK", current_animation_state == "QUADRUPED_LOOK")
	animation_tree.set("parameters/conditions/BIPEDAL_SNIFF", current_animation_state == "BIPEDAL_SNIFF")

func _on_button_button_down() -> void:
	_on_lever_button_pressed()

func _on_button_2_button_down() -> void:
	_on_next_phase_button_pressed()
