extends RefCounted
class_name PlatformPattern

# Pattern metadata
@export var pattern_name: String = "unnamed_pattern"
@export var width: int = 5  # Width in tiles
@export var height: int = 5  # Height in tiles
@export var difficulty: float = 0.5  # 0.0 to 1.0

# Platform data - array of dictionaries with position and type info
var platforms: Array = []

func _init(name: String = ""):
	if name != "":
		pattern_name = name

# Add a platform to the pattern
func add_platform(local_x: int, local_y: int, length: int = 1, platform_type: int = TileStyleConfig.TileType.PLATFORM):
	platforms.append({
		"x": local_x,
		"y": local_y,
		"length": length,
		"type": platform_type
	})

# Get all platforms transformed to world position
func get_platforms_at_position(world_x: int, world_y: int) -> Array:
	var world_platforms = []
	for platform in platforms:
		world_platforms.append({
			"x": world_x + platform.x,
			"y": world_y + platform.y,
			"length": platform.length,
			"type": platform.type
		})
	return world_platforms

# Check if pattern fits within bounds
func fits_in_bounds(world_x: int, world_y: int, min_x: int, max_x: int, min_y: int, max_y: int) -> bool:
	for platform in platforms:
		var plat_x = world_x + platform.x
		var plat_y = world_y + platform.y
		var plat_end_x = plat_x + platform.length - 1
		
		if plat_x < min_x or plat_end_x > max_x:
			return false
		if plat_y < min_y or plat_y > max_y:
			return false
	
	return true

# Static method to create predefined patterns
static func create_staircase(ascending: bool = true) -> PlatformPattern:
	var pattern = PlatformPattern.new("staircase")
	pattern.width = 8
	pattern.height = 6
	pattern.difficulty = 0.3
	
	for i in range(5):
		var y = -i if ascending else i
		pattern.add_platform(i * 2, y, 2)
	
	return pattern

static func create_gap_series() -> PlatformPattern:
	var pattern = PlatformPattern.new("gap_series")
	pattern.width = 12
	pattern.height = 2
	pattern.difficulty = 0.4
	
	# Series of platforms with consistent gaps
	pattern.add_platform(0, 0, 2)
	pattern.add_platform(4, 0, 2)
	pattern.add_platform(8, 0, 2)
	
	return pattern

static func create_zigzag() -> PlatformPattern:
	var pattern = PlatformPattern.new("zigzag")
	pattern.width = 6
	pattern.height = 8
	pattern.difficulty = 0.5
	
	# Alternating platforms going up
	pattern.add_platform(0, 0, 2)
	pattern.add_platform(4, -2, 2)
	pattern.add_platform(0, -4, 2)
	pattern.add_platform(4, -6, 2)
	
	return pattern

static func create_tower() -> PlatformPattern:
	var pattern = PlatformPattern.new("tower")
	pattern.width = 6
	pattern.height = 10
	pattern.difficulty = 0.6
	
	# Vertical stack alternating sides
	pattern.add_platform(0, 0, 2)
	pattern.add_platform(4, -2, 2)
	pattern.add_platform(0, -4, 2)
	pattern.add_platform(4, -6, 2)
	pattern.add_platform(2, -8, 2)  # Top platform
	
	return pattern

static func create_bridge() -> PlatformPattern:
	var pattern = PlatformPattern.new("bridge")
	pattern.width = 10
	pattern.height = 3
	pattern.difficulty = 0.2
	
	# Long horizontal platform with supports
	pattern.add_platform(0, 0, 10)
	# Support pillars
	pattern.add_platform(2, 1, 1, TileStyleConfig.TileType.WALL)
	pattern.add_platform(7, 1, 1, TileStyleConfig.TileType.WALL)
	
	return pattern

static func create_floating_islands() -> PlatformPattern:
	var pattern = PlatformPattern.new("floating_islands")
	pattern.width = 10
	pattern.height = 8
	pattern.difficulty = 0.7
	
	# Clustered platforms at various heights
	pattern.add_platform(0, 0, 3)
	pattern.add_platform(5, -2, 2)
	pattern.add_platform(2, -4, 3)
	pattern.add_platform(7, -5, 2)
	pattern.add_platform(4, -7, 2)
	
	return pattern

static func create_jump_puzzle() -> PlatformPattern:
	var pattern = PlatformPattern.new("jump_puzzle")
	pattern.width = 12
	pattern.height = 6
	pattern.difficulty = 0.8
	
	# Precision jumps with specific spacing
	pattern.add_platform(0, 0, 1)
	pattern.add_platform(3, -1, 1)
	pattern.add_platform(5, -3, 1)
	pattern.add_platform(8, -2, 1)
	pattern.add_platform(11, -1, 1)
	
	return pattern

static func create_cascade() -> PlatformPattern:
	var pattern = PlatformPattern.new("cascade")
	pattern.width = 8
	pattern.height = 10
	pattern.difficulty = 0.4
	
	# Waterfall-like descending platforms
	for i in range(5):
		var x = i + (i % 2) * 2
		var y = i * 2
		pattern.add_platform(x, y, 2)
	
	return pattern

static func create_spiral() -> PlatformPattern:
	var pattern = PlatformPattern.new("spiral")
	pattern.width = 10
	pattern.height = 10
	pattern.difficulty = 0.7
	
	# Circular arrangement
	var positions = [
		[4, 0], [7, -1], [9, -3], [8, -6],
		[5, -8], [2, -7], [0, -5], [1, -2], [3, -1]
	]
	
	for pos in positions:
		pattern.add_platform(pos[0], pos[1], 1)
	
	return pattern

static func create_choice_fork() -> PlatformPattern:
	var pattern = PlatformPattern.new("choice_fork")
	pattern.width = 12
	pattern.height = 8
	pattern.difficulty = 0.5
	
	# Starting platform
	pattern.add_platform(0, 0, 3)
	
	# Upper path
	pattern.add_platform(4, -2, 2)
	pattern.add_platform(7, -3, 2)
	pattern.add_platform(10, -2, 2)
	
	# Lower path
	pattern.add_platform(4, 2, 2)
	pattern.add_platform(7, 3, 2)
	pattern.add_platform(10, 2, 2)
	
	# Reconverge
	pattern.add_platform(12, 0, 3)
	
	return pattern
