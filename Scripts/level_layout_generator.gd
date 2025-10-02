extends RefCounted
class_name LevelLayoutGenerator

var pattern_library: PlatformPatternLibrary
var rng: RandomNumberGenerator
var tile_size: int = 32

# Level bounds
var min_x: int
var max_x: int
var min_y: int
var max_y: int
var ground_y: int

# Placed platforms tracking
var placed_platforms: Array = []
var occupied_spaces: Dictionary = {}

# Player physics constants (from player controller)
const PLAYER_SPEED = 200.0
const PLAYER_JUMP_VELOCITY = -600.0
const GRAVITY = 980.0

func _init(seed_value: float, width_tiles: int, height_tiles: int):
	rng = RandomNumberGenerator.new()
	rng.seed = int(seed_value)
	pattern_library = PlatformPatternLibrary.new(seed_value)
	
	# Set level bounds
	var half_width = int(width_tiles / 2)
	min_x = -half_width
	max_x = half_width - 1 if width_tiles % 2 == 0 else half_width
	min_y = -(height_tiles - 1)
	max_y = height_tiles - 1
	ground_y = height_tiles - 5

func generate_level() -> Dictionary:
	var level_data = {
		"platforms": [],
		"walls": [],
		"ground": [],
		"goal": {},
		"biome": ""
	}
	
	# Clear previous data
	placed_platforms.clear()
	occupied_spaces.clear()
	
	# --- Biome selection and parameters ---
	var biome_params = {
		"cave": {
			"safe_start_width": 2, "safe_end_width": 2,
			"min_platform_width": 2, "max_platform_width": 4,
			"min_gap_width": 2, "max_gap_width": 4
		},
		"ruins": {
			"safe_start_width": 3, "safe_end_width": 3,
			"min_platform_width": 3, "max_platform_width": 7,
			"min_gap_width": 1, "max_gap_width": 2
		},
		"forest": {
			"safe_start_width": 4, "safe_end_width": 4,
			"min_platform_width": 5, "max_platform_width": 10,
			"min_gap_width": 1, "max_gap_width": 1
		}
	}
	var biome_names = biome_params.keys()
	var biome = biome_names[rng.randi_range(0, biome_names.size() - 1)]
	level_data.biome = biome
	var params = biome_params[biome]

	# --- New: Varying ground height and density ---
	var safe_start_width = params.safe_start_width
	var safe_end_width = params.safe_end_width
	var min_platform_width = params.min_platform_width
	var max_platform_width = params.max_platform_width
	var min_gap_width = params.min_gap_width
	var max_gap_width = params.max_gap_width

	# New: Randomize ground density (0.5 to 1.0)
	var ground_density = rng.randf_range(0.5, 1.0)
	# New: Random walk for ground height
	var current_ground_y = ground_y
	var min_ground_y = min_y + 2
	var max_ground_y = ground_y

	# --- New: Occasionally force platform traversal (platform path mode) ---
	var platform_path_mode = rng.randf() < 0.35  # 35% chance per level
	var platform_path_start = 0
	var platform_path_end = 0
	var platform_path_y = current_ground_y - rng.randi_range(3, 6)
	if platform_path_mode:
		platform_path_start = rng.randi_range(min_x + safe_start_width + 3, max_x - safe_end_width - 15)
		platform_path_end = platform_path_start + rng.randi_range(10, 18)
		platform_path_end = min(platform_path_end, max_x - safe_end_width - 1)
		platform_path_y = clamp(platform_path_y, min_ground_y, ground_y - 2)

	var x = min_x
	# Safe start area (no gaps, flat ground)
	while x < min_x + safe_start_width and x <= max_x:
		level_data.ground.append({"x": x, "y": current_ground_y})
		_mark_space_occupied(x, current_ground_y)
		x += 1

	while x <= max_x - safe_end_width:
		# If in platform path mode and within the forced gap, skip ground
		if platform_path_mode and x >= platform_path_start and x <= platform_path_end:
			x += 1
			continue
		# Randomly decide if this segment should have ground (based on density)
		if rng.randf() < ground_density:
			# Random walk: occasionally change ground height
			if rng.randf() < 0.3:
				current_ground_y += rng.randi_range(-1, 1)
				current_ground_y = clamp(current_ground_y, min_ground_y, max_ground_y)
			# Place a platform segment (ground)
			var platform_width = rng.randi_range(min_platform_width, max_platform_width)
			for i in range(platform_width):
				if x > max_x - safe_end_width:
					break
				# If in platform path mode and within the forced gap, skip ground
				if platform_path_mode and x >= platform_path_start and x <= platform_path_end:
					x += 1
					continue
				level_data.ground.append({"x": x, "y": current_ground_y})
				_mark_space_occupied(x, current_ground_y)
				x += 1
		else:
			# Place a gap (no ground)
			var gap_width = rng.randi_range(min_gap_width, max_gap_width)
			x += gap_width

	# Safe end area (no gaps, flat ground)
	while x <= max_x:
		level_data.ground.append({"x": x, "y": current_ground_y})
		_mark_space_occupied(x, current_ground_y)
		x += 1

	# --- Ensure at least one gap in the ground ---
	var ground_xs = {}
	for ground_tile in level_data.ground:
		ground_xs[ground_tile.x] = true
	var has_gap = false
	for gx in range(min_x, max_x + 1):
		if not ground_xs.has(gx):
			has_gap = true
			break
	# If no gap, forcibly remove a segment in the middle
	if not has_gap:
		var gap_start = int((min_x + max_x) / 2) - rng.randi_range(1, 2)
		var gap_width = rng.randi_range(2, 4)
		var new_ground = []
		for ground_tile in level_data.ground:
			if ground_tile.x < gap_start or ground_tile.x >= gap_start + gap_width:
				new_ground.append(ground_tile)
			else:
				# Remove from occupied_spaces as well
				var key = str(ground_tile.x) + "," + str(ground_tile.y)
				occupied_spaces.erase(key)
		level_data.ground = new_ground

	# If platform path mode, add a long platform above the gap
	if platform_path_mode:
		var plat_length = platform_path_end - platform_path_start + 1
		level_data.platforms.append({
			"x": platform_path_start,
			"y": platform_path_y,
			"length": plat_length
		})
		for dx in range(plat_length):
			_mark_space_occupied(platform_path_start + dx, platform_path_y)
			placed_platforms.append(Vector2(platform_path_start + dx, platform_path_y))
	# Generate walls
	for y in range(min_y, max_y + 1):
		level_data.walls.append({"x": min_x, "y": y})
		level_data.walls.append({"x": max_x, "y": y})
		_mark_space_occupied(min_x, y)
		_mark_space_occupied(max_x, y)
	
	# --- Fully randomized goal placement with overlap check ---
	var goal_x = max_x - 5
	# Allow goal anywhere from ground_y (bottom) up to min_y + 2 (top), inclusive
	var min_goal_y = min_y + 2
	var max_goal_y = ground_y
	var goal_y = rng.randi_range(min_goal_y, max_goal_y)

	# Ensure goal does not overlap with any other tile
	var max_goal_attempts = 20
	var found_goal_spot = false
	for attempt in range(max_goal_attempts):
		if not _is_space_occupied(goal_x, goal_y):
			found_goal_spot = true
			break
		# Try moving up if possible, else down
		if goal_y > min_goal_y:
			goal_y -= 1
		elif goal_y < max_goal_y:
			goal_y += 1
	if not found_goal_spot:
		# As fallback, try shifting x position nearby
		for dx in range(-5, 6):
			if not _is_space_occupied(goal_x + dx, goal_y):
				goal_x += dx
				found_goal_spot = true
				break
	# If still not found, just place at original position (will overlap, but extremely rare)

	level_data.goal = {"x": goal_x, "y": goal_y}
	print("Placed goal at: ", goal_x, ", ", goal_y)

	# Only add platform under goal if elevated and not overlapping
	if goal_y < ground_y:
		for dx in range(-1, 2):
			if not _is_space_occupied(goal_x + dx, goal_y + 2):
				level_data.platforms.append({"x": goal_x + dx, "y": goal_y + 2, "length": 1})
				_mark_space_occupied(goal_x + dx, goal_y + 2)

	# Generate level using zones
	_generate_zoned_layout(level_data)
	
	# Ensure all platforms are reachable from the ground
	_filter_unreachable_platforms(level_data)

	# --- Ensure goal is reachable ---
	var goal_pos = Vector2(level_data.goal.x, level_data.goal.y)
	var reachable = false
	# Build a set of all reachable positions (ground + platforms)
	var reachable_positions = {}
	for ground in level_data.ground:
		reachable_positions[Vector2(ground.x, ground.y)] = true
	for platform in level_data.platforms:
		for dx in range(platform.length):
			reachable_positions[Vector2(platform.x + dx, platform.y)] = true

	# Check if goal is reachable from any platform or ground
	for from_pos in reachable_positions.keys():
		if validate_jump(from_pos, goal_pos):
			reachable = true
			break

	# If not reachable, move goal down until it is, or build staircase/platforms up to it
	var max_goal_move_attempts = 20
	var moved = false
	while not reachable and level_data.goal.y < ground_y and max_goal_move_attempts > 0:
		level_data.goal.y += 1
		goal_pos = Vector2(level_data.goal.x, level_data.goal.y)
		for from_pos in reachable_positions.keys():
			if validate_jump(from_pos, goal_pos):
				reachable = true
				break
		max_goal_move_attempts -= 1
		moved = true

	# If still not reachable, build a staircase/platforms up to the goal
	if not reachable:
		var min_dist = INF
		var start_x = 0
		for from_pos in reachable_positions.keys():
			var dist = abs(from_pos.x - level_data.goal.x)
			if dist < min_dist:
				min_dist = dist
				start_x = from_pos.x
		var steps = max(1, int((level_data.goal.y - ground_y) / -2))
		for i in range(steps):
			var plat_x = int(lerp(start_x, level_data.goal.x, float(i) / steps))
			var plat_y = ground_y - i * 2
			level_data.platforms.append({
				"x": plat_x,
				"y": plat_y,
				"length": 2
			})

	return level_data

func _generate_zoned_layout(level_data: Dictionary):
	# Divide level into zones
	var zone_width = int((max_x - min_x) / 3)
	var zone_height = int((ground_y - min_y) / 3)
	
	# Define zones (3x3 grid)
	var zones = [
		# Bottom row (near ground)
		{"x": min_x + 2, "y": ground_y - zone_height, "type": "start"},
		{"x": min_x + zone_width, "y": ground_y - zone_height, "type": "easy"},
		{"x": min_x + zone_width * 2, "y": ground_y - zone_height, "type": "transition"},
		
		# Middle row
		{"x": min_x + 2, "y": ground_y - zone_height * 2, "type": "medium"},
		{"x": min_x + zone_width, "y": ground_y - zone_height * 2, "type": "hub"},
		{"x": min_x + zone_width * 2, "y": ground_y - zone_height * 2, "type": "medium"},
		
		# Top row (high platforms)
		{"x": min_x + 2, "y": ground_y - zone_height * 3, "type": "hard"},
		{"x": min_x + zone_width, "y": ground_y - zone_height * 3, "type": "challenge"},
		{"x": min_x + zone_width * 2, "y": ground_y - zone_height * 3, "type": "goal_path"}
	]
	
	# Process each zone
	for zone in zones:
		_fill_zone(zone, level_data)
	
	# Ensure connectivity between zones
	_ensure_connectivity(level_data)

func _fill_zone(zone: Dictionary, level_data: Dictionary):
	var pattern: PlatformPattern

	# Biome-specific pattern pools
	var biome_pattern_pools = {
		"cave": [
			"zigzag", "tower", "spiral", "jump_puzzle", "cascade", "staircase_up", "staircase_down"
		],
		"ruins": [
			"bridge", "gap_series", "choice_fork", "cascade", "staircase_up", "staircase_down"
		],
		"forest": [
			"floating_islands", "zigzag", "choice_fork", "bridge", "cascade"
		]
	}
	var biome = level_data.biome if level_data.has("biome") else "ruins"
	var allowed_patterns = biome_pattern_pools[biome] if biome_pattern_pools.has(biome) else biome_pattern_pools["ruins"]

	# Select pattern based on zone type, but filtered by biome
	match zone.type:
		"start":
			# Easy patterns near start, filtered by biome
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)
		"easy":
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)
		"transition":
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)
		"medium":
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)
		"hub":
			# Central area - prefer bridge or floating islands if available
			if "bridge" in allowed_patterns and rng.randf() < 0.5:
				pattern = pattern_library.get_pattern_by_name("bridge")
			elif "floating_islands" in allowed_patterns:
				pattern = pattern_library.get_pattern_by_name("floating_islands")
			else:
				var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
				pattern = pattern_library.get_pattern_by_name(name)
		"hard":
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)
		"challenge":
			if "jump_puzzle" in allowed_patterns and rng.randf() < 0.5:
				pattern = pattern_library.get_pattern_by_name("jump_puzzle")
			elif "spiral" in allowed_patterns:
				pattern = pattern_library.get_pattern_by_name("spiral")
			else:
				var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
				pattern = pattern_library.get_pattern_by_name(name)
		"goal_path":
			if "staircase_up" in allowed_patterns:
				pattern = pattern_library.get_pattern_by_name("staircase_up")
			else:
				var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
				pattern = pattern_library.get_pattern_by_name(name)
		_:
			var name = allowed_patterns[rng.randi_range(0, allowed_patterns.size() - 1)]
			pattern = pattern_library.get_pattern_by_name(name)

	# Try to place pattern in zone with reachability check
	_place_pattern_in_zone_with_reachability(pattern, zone, level_data)

func _place_pattern_in_zone_with_reachability(pattern: PlatformPattern, zone: Dictionary, level_data: Dictionary):
	# Try multiple positions within the zone
	var attempts = 10

	# --- New: Randomly parameterize pattern placement ---
	var pattern_stretch = rng.randf() < 0.4  # 40% chance to stretch pattern horizontally
	var stretch_factor = rng.randi_range(1, 2) if pattern_stretch else 1
	var pattern_vertical_offset = rng.randi_range(-2, 2)

	while attempts > 0:
		# Random offset within zone bounds
		var offset_x = rng.randi_range(0, 5)
		var offset_y = rng.randi_range(-3, 3) + pattern_vertical_offset

		var place_x = zone.x + offset_x
		var place_y = zone.y + offset_y

		# Check if pattern fits (with stretch)
		var fits = true
		for platform in pattern.platforms:
			var plat_x = place_x + platform.x * stretch_factor
			var plat_y = place_y + platform.y
			var plat_end_x = plat_x + platform.length * stretch_factor - 1
			if plat_x < min_x + 1 or plat_end_x > max_x - 1:
				fits = false
				break
			if plat_y < min_y or plat_y > ground_y - 1:
				fits = false
				break
		if fits and _can_place_pattern(pattern, place_x, place_y):
			# Build stretched platforms
			var platforms = []
			for platform in pattern.platforms:
				if platform.type == TileStyleConfig.TileType.PLATFORM:
					platforms.append({
						"x": place_x + platform.x * stretch_factor,
						"y": place_y + platform.y,
						"length": platform.length * stretch_factor,
						"type": platform.type
					})
				elif platform.type == TileStyleConfig.TileType.WALL:
					platforms.append({
						"x": place_x + platform.x * stretch_factor,
						"y": place_y + platform.y,
						"length": platform.length * stretch_factor,
						"type": platform.type
					})
			# Check reachability: at least one platform must be reachable from an existing platform
			var reachable = false
			for platform in platforms:
				if platform.type == TileStyleConfig.TileType.PLATFORM:
					for existing in placed_platforms:
						if validate_jump(existing, Vector2(platform.x, platform.y)):
							reachable = true
							break
					if reachable:
						break
			# If this is the first platform, allow placement
			if placed_platforms.size() == 0:
				reachable = true
			if reachable:
				# Place the pattern
				for platform in platforms:
					if platform.type == TileStyleConfig.TileType.PLATFORM:
						level_data.platforms.append({
							"x": platform.x,
							"y": platform.y,
							"length": platform.length
						})
						# Mark spaces as occupied
						for i in range(platform.length):
							_mark_space_occupied(platform.x + i, platform.y)
							placed_platforms.append(Vector2(platform.x + i, platform.y))
					elif platform.type == TileStyleConfig.TileType.WALL:
						for i in range(platform.length):
							level_data.walls.append({
								"x": platform.x + i,
								"y": platform.y
							})
							_mark_space_occupied(platform.x + i, platform.y)
				break

		attempts -= 1

	# If pattern couldn't be placed, add some simple platforms
	if attempts == 0:
		_add_fallback_platforms(zone, level_data)

func _can_place_pattern(pattern: PlatformPattern, world_x: int, world_y: int) -> bool:
	# Check if any platform in the pattern would overlap existing platforms
	var platforms = pattern.get_platforms_at_position(world_x, world_y)
	
	for platform in platforms:
		for i in range(platform.length):
			var check_x = platform.x + i
			var check_y = platform.y
			
			if _is_space_occupied(check_x, check_y):
				return false
			
			# Also check one tile above and below to avoid platforms being too close
			if _is_space_occupied(check_x, check_y - 1) or _is_space_occupied(check_x, check_y + 1):
				return false
	
	return true

func _add_fallback_platforms(zone: Dictionary, level_data: Dictionary):
	# Add 2-3 simple platforms in the zone area, only if reachable from existing platforms
	var num_platforms = rng.randi_range(2, 3)

	for i in range(num_platforms):
		var attempts = 5
		while attempts > 0:
			var plat_x = zone.x + rng.randi_range(0, 8)
			var plat_y = zone.y + rng.randi_range(-4, 4)
			var plat_length = rng.randi_range(2, 4)

			# Check bounds and overlap
			if plat_x + plat_length <= max_x and plat_y > min_y and plat_y < ground_y:
				var can_place = true
				for dx in range(plat_length):
					if _is_space_occupied(plat_x + dx, plat_y):
						can_place = false
						break

				# Check reachability: at least one tile of the platform must be reachable from existing platforms
				var reachable = false
				if can_place:
					for dx in range(plat_length):
						for existing in placed_platforms:
							if validate_jump(existing, Vector2(plat_x + dx, plat_y)):
								reachable = true
								break
						if reachable:
							break
				# If this is the first platform, allow placement
				if placed_platforms.size() == 0:
					reachable = true

				if can_place and reachable:
					level_data.platforms.append({
						"x": plat_x,
						"y": plat_y,
						"length": plat_length
					})
					for dx in range(plat_length):
						_mark_space_occupied(plat_x + dx, plat_y)
						placed_platforms.append(Vector2(plat_x + dx, plat_y))
					break

			attempts -= 1

func _filter_unreachable_platforms(level_data: Dictionary):
	# Build a set of all platform positions
	var platform_positions = {}
	for platform in level_data.platforms:
		for dx in range(platform.length):
			var pos = Vector2(platform.x + dx, platform.y)
			platform_positions[pos] = true

	# Start BFS from all ground tiles
	var reachable = {}
	var queue = []
	for ground in level_data.ground:
		var pos = Vector2(ground.x, ground.y)
		reachable[pos] = true
		queue.append(pos)

	# Move unreachable platforms down until reachable or at ground
	var updated_platforms = []
	for platform in level_data.platforms:
		var _moved = false
		var _original_y = platform.y
		while not _is_platform_reachable(platform, reachable) and platform.y < ground_y:
			platform.y += 1
			_moved = true
			# Prevent overlap with ground or other platforms
			var overlap = false
			for dx in range(platform.length):
				var pos = Vector2(platform.x + dx, platform.y)
				if pos in platform_positions or pos.y > ground_y:
					overlap = true
					break
			if overlap:
				platform.y -= 1
				break
		# After moving, mark all tiles as reachable if now reachable
		if _is_platform_reachable(platform, reachable) or platform.y == ground_y:
			for dx in range(platform.length):
				var pos = Vector2(platform.x + dx, platform.y)
				reachable[pos] = true
			updated_platforms.append(platform)
	level_data.platforms = updated_platforms

	# Fallback: if no platforms remain, add a simple staircase from ground to goal
	if level_data.platforms.size() == 0 and level_data.goal:
		var goal_x = level_data.goal.x
		var goal_y = level_data.goal.y
		# Find a ground tile closest to the goal
		var min_dist = INF
		var start_x = 0
		for ground in level_data.ground:
			var dist = abs(ground.x - goal_x)
			if dist < min_dist:
				min_dist = dist
				start_x = ground.x
		# Build a staircase up to the goal
		var steps = max(1, int((goal_y - ground_y) / -2))
		for i in range(steps):
			var plat_x = int(lerp(start_x, goal_x, float(i) / steps))
			var plat_y = ground_y - i * 2
			level_data.platforms.append({
				"x": plat_x,
				"y": plat_y,
				"length": 2
			})
func _is_platform_reachable(platform, reachable: Dictionary) -> bool:
	for dx in range(platform.length):
		var pos = Vector2(platform.x + dx, platform.y)
		for from_pos in reachable.keys():
			if validate_jump(from_pos, pos):
				return true
	return false

func _ensure_connectivity(level_data: Dictionary):
	# Add connecting platforms where needed to ensure the level is traversable
	# This is a simplified version - you could implement pathfinding for better validation
	
	# Check if there are enough platforms leading upward
	var height_bands = {}
	
	for platform in level_data.platforms:
		var band = int(platform.y / 3)
		if not height_bands.has(band):
			height_bands[band] = []
		height_bands[band].append(platform)
	
	# Ensure each height band has some platforms
	for y in range(ground_y - 12, ground_y, 3):
		var band = int(y / 3)
		if not height_bands.has(band) or height_bands[band].size() < 2:
			# Add a connecting platform
			var x = rng.randi_range(min_x + 5, max_x - 5)
			var length = rng.randi_range(2, 4)
			
			if x + length <= max_x:
				level_data.platforms.append({
					"x": x,
					"y": y,
					"length": length
				})

func _mark_space_occupied(x: int, y: int):
	var key = str(x) + "," + str(y)
	occupied_spaces[key] = true

func _is_space_occupied(x: int, y: int) -> bool:
	var key = str(x) + "," + str(y)
	return occupied_spaces.has(key)

func validate_jump(from_pos: Vector2, to_pos: Vector2) -> bool:
	var dx = to_pos.x - from_pos.x
	var dy = to_pos.y - from_pos.y
	
	# Calculate max jump capabilities
	var max_jump_height = (PLAYER_JUMP_VELOCITY * PLAYER_JUMP_VELOCITY) / (2.0 * GRAVITY)
	var time_to_peak = abs(PLAYER_JUMP_VELOCITY / GRAVITY)
	var max_horizontal = PLAYER_SPEED * time_to_peak * 2.0
	
	# Convert to tiles and add safety margin
	max_jump_height = (max_jump_height / tile_size) * 0.85
	max_horizontal = (max_horizontal / tile_size) * 0.85
	
	# Check if jump is possible
	if dy < 0:  # Jumping up
		if abs(dy) > max_jump_height:
			return false
	
	if abs(dx) > max_horizontal:
		return false
	
	return true
