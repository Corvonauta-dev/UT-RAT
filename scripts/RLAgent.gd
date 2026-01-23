extends Node

"""
Simple Q‑learning agent used to decide whether the virtual rat should press
the lever or ignore it.  This implementation maintains a Q‑table mapping
discrete states to actions and updates its values using the standard
Q‑learning update rule.  The agent supports two states (0 = base, 1 = near
lever) and two actions (0 = ignore lever, 1 = press lever).  Rewards are
assigned externally when food is collected or when the agent chooses not
to press.  A small epsilon value encourages exploration when selecting
actions.

Example usage:
	var rl_agent = load("res://RLAgent.gd").new()
	var action = rl_agent.choose_action(current_state)
	# perform action ...
	rl_agent.update_q(prev_state, action, reward, next_state)
"""

## Hyperparameters
# Learning parameters.  These values can be adjusted programmatically when
# instantiating the agent; they are not exported to the inspector to
# maximize compatibility across Godot versions.
var alpha: float = 0.5  # learning rate
var gamma: float = 0.9  # discount factor
var epsilon: float = 0.1  # exploration rate

# Q‑table stored as a dictionary of dictionaries: q_table[state][action] = value
var q_table := {}

## Public methods

func choose_action(state: int, actions: Array) -> int:
	"""
	Choose an action from the list of available actions for the given state
	using an ε‑greedy policy.  When a random number is less than ε, a
	uniformly random action from the provided list is returned (exploration);
	otherwise, the action with the largest Q‑value for the state is chosen
	(exploitation).  Debug messages indicate whether exploration or
	exploitation occurred.
	"""
	if actions.size() == 0:
		push_error("RLAgent.choose_action called with an empty action list")
		return -1
	# Exploration: random action with probability epsilon
	if randf() < epsilon:
		var idx = randi() % actions.size()
		var chosen = actions[idx]
		print("[RLAgent] Exploring: state=", state, ", action=", chosen)
		return chosen
	# Exploitation: choose the best action based on stored Q-values
	var best_action = actions[0]
	var best_value = -INF
	for a in actions:
		var q = get_q_value(state, a)
		if q > best_value:
			best_value = q
			best_action = a
	print("[RLAgent] Exploiting: state=", state, ", action=", best_action, ", value=", best_value)
	return best_action

func update_q(prev_state: int, prev_action: int, reward: float, next_state: int) -> void:
	"""
	Update the Q‑table using the Q‑learning rule.  If the previous state or
	action is null (e.g. at the start of an episode), the update is skipped.
	"""
	# Skip update if prev_state or prev_action is invalid
	if prev_state == -1 or prev_action == -1:
		return
	var old_value = get_q_value(prev_state, prev_action)
	var next_max = max_q_value(next_state)
	var new_value = old_value + alpha * (reward + gamma * next_max - old_value)
	set_q_value(prev_state, prev_action, new_value)
	# Debug: print the updated Q-value
	print("[RLAgent] Update: prev_state=", prev_state, ", action=", prev_action, ", reward=", reward, ", next_state=", next_state, ", new_Q=", new_value)
	# Optionally print the entire Q-table when a non-zero reward is received
	if reward != 0.0:
		debug_print_q_table()

func save_q_table(file_path: String = "res://q-tabela/q_table.json") -> void:
	"""
	Persist the Q‑table to a JSON file.  The default location is inside
	`res://q-tabela/q_table.json`.  Before saving, the target directory
	(`q-tabela`) is created if it does not already exist.
	"""
	# Ensure the directory exists.  Open a DirAccess to the res:// root
	var dir = DirAccess.open("res://")
	if dir:
		# Create the folder hierarchy q-tabela if needed
		dir.make_dir_recursive("q-tabela")
	# Now open the file for writing
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		# Serialize the Q-table to JSON
		var json = JSON.new()
		var json_string = json.stringify(q_table)
		file.store_string(json_string)
		file.close()

func load_q_table(file_path: String = "res://q-tabela/q_table.json") -> void:
	"""
	Load the Q‑table from a JSON file saved in `res://q-tabela/q_table.json` by
	default.  If the file does not exist or cannot be parsed, the Q‑table
	remains empty.  During loading, the dictionary keys are converted
	to integers to avoid duplicate string/integer keys.
	"""
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var json_str = file.get_as_text()
			file.close()
			var json = JSON.new()
			var error = json.parse(json_str)
			if error == OK and typeof(json.data) == TYPE_DICTIONARY:
				var loaded = json.data
				var new_table := {}
				for state_key in loaded.keys():
					var s = int(state_key)
					new_table[s] = {}
					var state_dict = loaded[state_key]
					for action_key in state_dict.keys():
						var a = int(action_key)
						new_table[s][a] = float(state_dict[action_key])
				q_table = new_table

## Internal helper functions

func get_q_value(state: int, action: int) -> float:
	if q_table.has(state):
		var state_table = q_table[state]
		if state_table.has(action):
			return float(state_table[action])
	return 0.0

func set_q_value(state: int, action: int, value: float) -> void:
	if not q_table.has(state):
		q_table[state] = {}
	q_table[state][action] = value

func max_q_value(state: int) -> float:
	# Compute the maximum Q-value across all actions defined for this state.
	# If the state has no entries in the Q-table, return 0.0.
	if not q_table.has(state):
		return 0.0
	var max_val = -INF
	var state_table = q_table[state]
	for a in state_table.keys():
		var val = float(state_table[a])
		if val > max_val:
			max_val = val
	if max_val == -INF:
		return 0.0
	return max_val

## Debugging helper to print the Q-table
func debug_print_q_table() -> void:
	print("Current Q-table: ", q_table)
