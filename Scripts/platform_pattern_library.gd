extends RefCounted
class_name PlatformPatternLibrary

var patterns: Dictionary = {}
var pattern_weights: Dictionary = {}
var rng: RandomNumberGenerator

func _init(seed_value: float):
	rng = RandomNumberGenerator.new()
	rng.seed = int(seed_value)
	_load_all_patterns()
	_initialize_weights()

func _load_all_patterns():
	# Load all predefined patterns
	patterns["staircase_up"] = PlatformPattern.create_staircase(true)
	patterns["staircase_down"] = PlatformPattern.create_staircase(false)
	patterns["gap_series"] = PlatformPattern.create_gap_series()
	patterns["zigzag"] = PlatformPattern.create_zigzag()
	patterns["tower"] = PlatformPattern.create_tower()
	patterns["bridge"] = PlatformPattern.create_bridge()
	patterns["floating_islands"] = PlatformPattern.create_floating_islands()
	patterns["jump_puzzle"] = PlatformPattern.create_jump_puzzle()
	patterns["cascade"] = PlatformPattern.create_cascade()
	patterns["spiral"] = PlatformPattern.create_spiral()
	patterns["choice_fork"] = PlatformPattern.create_choice_fork()

func _initialize_weights():
	# Set initial weights for pattern selection
	pattern_weights = {
		"staircase_up": 1.0,
		"staircase_down": 0.8,
		"gap_series": 1.0,
		"zigzag": 0.8,
		"tower": 0.6,
		"bridge": 0.4,
		"floating_islands": 0.7,
		"jump_puzzle": 0.3,
		"cascade": 0.6,
		"spiral": 0.3,
		"choice_fork": 0.5
	}

func get_random_pattern() -> PlatformPattern:
	# Calculate total weight
	var total_weight = 0.0
	for weight in pattern_weights.values():
		total_weight += weight
	
	# Select pattern based on weighted random
	var random_value = rng.randf() * total_weight
	var accumulated = 0.0
	
	for pattern_name in pattern_weights:
		accumulated += pattern_weights[pattern_name]
		if random_value <= accumulated:
			# Reduce weight after selection to avoid repetition
			pattern_weights[pattern_name] *= 0.7
			return patterns[pattern_name]
	
	# Fallback (shouldn't reach here)
	return patterns["gap_series"]

func get_pattern_by_name(name: String) -> PlatformPattern:
	if patterns.has(name):
		return patterns[name]
	return null

func reset_weights():
	_initialize_weights()

# Get a pattern suitable for a specific difficulty range
func get_pattern_by_difficulty(min_difficulty: float, max_difficulty: float) -> PlatformPattern:
	var suitable_patterns = []
	var suitable_weights = []
	
	for pattern_name in patterns:
		var pattern = patterns[pattern_name]
		if pattern.difficulty >= min_difficulty and pattern.difficulty <= max_difficulty:
			suitable_patterns.append(pattern)
			suitable_weights.append(pattern_weights[pattern_name])
	
	if suitable_patterns.is_empty():
		return get_random_pattern()
	
	# Weighted random selection from suitable patterns
	var total_weight = 0.0
	for weight in suitable_weights:
		total_weight += weight
	
	var random_value = rng.randf() * total_weight
	var accumulated = 0.0
	
	for i in range(suitable_patterns.size()):
		accumulated += suitable_weights[i]
		if random_value <= accumulated:
			return suitable_patterns[i]
	
	return suitable_patterns[0]
