extends RefCounted
class_name PixelArtTileGenerator

# Generate pixel art tiles for biome styles
static func generate_tile_image(biome: String, tile_type: int, seed_value: float, tile_size: int = 32) -> Image:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(seed_value * 1000 + tile_type)
	
	var img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
	
	match biome:
		"GRASSLAND":
			return _generate_grassland_tile(img, tile_type, rng, tile_size)
		"FOREST":
			return _generate_forest_tile(img, tile_type, rng, tile_size)
		"CAVE":
			return _generate_cave_tile(img, tile_type, rng, tile_size)
		"DISCO":
			return _generate_disco_tile(img, tile_type, rng, tile_size)
		_:
			# Fallback - simple colored tile
			img.fill(Color(0.5, 0.5, 0.5))
			return img

# Helper function to add spiky grass edges
static func _add_spiky_grass_edges(img: Image, rng: RandomNumberGenerator, tile_size: int, grass_colors: Array) -> void:
	# Create irregular spiky outline by removing pixels
	# Top edge - create grass blade spikes by removing gaps
	for x in range(tile_size):
		var pixel = img.get_pixel(x, 0)
		if pixel.a > 0 and _is_similar_color(pixel, grass_colors):
			# Randomly remove pixels to create gaps between grass blades
			if rng.randf() < 0.35:
				img.set_pixel(x, 0, Color(0, 0, 0, 0))  # Make transparent
				# Sometimes remove the pixel below too
				if rng.randf() < 0.4 and x % 2 == 0:
					img.set_pixel(x, 1, Color(0, 0, 0, 0))
	
	# Left and right edges - occasional irregular bumps
	for y in range(tile_size):
		var pixel_left = img.get_pixel(0, y)
		if pixel_left.a > 0 and rng.randf() < 0.15:
			img.set_pixel(0, y, Color(0, 0, 0, 0))
		
		var pixel_right = img.get_pixel(tile_size - 1, y)
		if pixel_right.a > 0 and rng.randf() < 0.15:
			img.set_pixel(tile_size - 1, y, Color(0, 0, 0, 0))

# Helper function to add jagged rock edges
static func _add_jagged_rock_edges(img: Image, rng: RandomNumberGenerator, tile_size: int, rock_colors: Array) -> void:
	# Create highly jagged rocky edges with dramatic gaps - LIKE ROCKS NOT PEBBLES
	# Top edge - very rough, uneven rock surface with large irregularities
	for x in range(tile_size):
		var pixel = img.get_pixel(x, 0)
		if pixel.a > 0:
			# Much higher removal rate for dramatic jaggedness (65% removal rate)
			if rng.randf() < 0.65:
				img.set_pixel(x, 0, Color(0, 0, 0, 0))
				# Extend gaps much deeper more frequently (80% chance)
				if rng.randf() < 0.8:
					img.set_pixel(x, 1, Color(0, 0, 0, 0))
					# Create frequent very deep crevices (70% chance for 2 pixels)
					if rng.randf() < 0.7:
						img.set_pixel(x, 2, Color(0, 0, 0, 0))
						# Even deeper gouges (50% chance for 3 pixels)
						if rng.randf() < 0.5:
							img.set_pixel(x, 3, Color(0, 0, 0, 0))
							# Occasional massive cracks (30% chance for 4 pixels)
							if rng.randf() < 0.3:
								img.set_pixel(x, 4, Color(0, 0, 0, 0))
				# Remove more adjacent pixels for much wider gaps
				if rng.randf() < 0.6 and x > 0:
					img.set_pixel(x - 1, 0, Color(0, 0, 0, 0))
					if rng.randf() < 0.5:
						img.set_pixel(x - 1, 1, Color(0, 0, 0, 0))
						if rng.randf() < 0.4:
							img.set_pixel(x - 1, 2, Color(0, 0, 0, 0))
				# Also remove pixels on the other side for chunky gaps
				if rng.randf() < 0.5 and x < tile_size - 1:
					img.set_pixel(x + 1, 0, Color(0, 0, 0, 0))
					if rng.randf() < 0.4:
						img.set_pixel(x + 1, 1, Color(0, 0, 0, 0))
	
	# Bottom edge - jagged underside with larger chunks
	for x in range(tile_size):
		var pixel = img.get_pixel(x, tile_size - 1)
		if pixel.a > 0 and rng.randf() < 0.5:
			img.set_pixel(x, tile_size - 1, Color(0, 0, 0, 0))
			if rng.randf() < 0.6:
				img.set_pixel(x, tile_size - 2, Color(0, 0, 0, 0))
				if rng.randf() < 0.4:
					img.set_pixel(x, tile_size - 3, Color(0, 0, 0, 0))
	
	# Left and right edges - heavily jagged sides with large protrusions and indentations
	for y in range(tile_size):
		# Left edge - much more dramatic (55% removal)
		var pixel_left = img.get_pixel(0, y)
		if pixel_left.a > 0 and rng.randf() < 0.55:
			img.set_pixel(0, y, Color(0, 0, 0, 0))
			# Create much deeper indentations (75% chance)
			if rng.randf() < 0.75:
				img.set_pixel(1, y, Color(0, 0, 0, 0))
				if rng.randf() < 0.6:
					img.set_pixel(2, y, Color(0, 0, 0, 0))
					if rng.randf() < 0.4:
						img.set_pixel(3, y, Color(0, 0, 0, 0))
						# Massive indentations (25% chance for 4 pixels)
						if rng.randf() < 0.25:
							img.set_pixel(4, y, Color(0, 0, 0, 0))
		
		# Right edge - much more dramatic (55% removal)
		var pixel_right = img.get_pixel(tile_size - 1, y)
		if pixel_right.a > 0 and rng.randf() < 0.55:
			img.set_pixel(tile_size - 1, y, Color(0, 0, 0, 0))
			# Create much deeper indentations (75% chance)
			if rng.randf() < 0.75:
				img.set_pixel(tile_size - 2, y, Color(0, 0, 0, 0))
				if rng.randf() < 0.6:
					img.set_pixel(tile_size - 3, y, Color(0, 0, 0, 0))
					if rng.randf() < 0.4:
						img.set_pixel(tile_size - 4, y, Color(0, 0, 0, 0))
						# Massive indentations (25% chance for 4 pixels)
						if rng.randf() < 0.25:
							img.set_pixel(tile_size - 5, y, Color(0, 0, 0, 0))

# Helper function to add sharp crystalline edges
static func _add_crystalline_edges(img: Image, rng: RandomNumberGenerator, tile_size: int, crystal_colors: Array) -> void:
	# Create dramatic sharp, angular crystal outline with pronounced facets - LARGE CRYSTAL FORMATIONS
	# Top edge - very sharp crystal points and valleys with massive irregularities
	for x in range(tile_size):
		var pixel = img.get_pixel(x, 0)
		if pixel.a > 0 and _is_similar_color(pixel, crystal_colors):
			# Much higher removal for dramatic angular gaps (70% removal on crystal areas)
			if rng.randf() < 0.7:
				img.set_pixel(x, 0, Color(0, 0, 0, 0))
				# Create much deeper angular cuts (85% chance)
				if rng.randf() < 0.85:
					img.set_pixel(x, 1, Color(0, 0, 0, 0))
					# Very deep facet cuts (75% chance for 2 pixels)
					if rng.randf() < 0.75:
						img.set_pixel(x, 2, Color(0, 0, 0, 0))
						# Massive crystal spikes and valleys (60% chance for 3 pixels)
						if rng.randf() < 0.6:
							img.set_pixel(x, 3, Color(0, 0, 0, 0))
							# Extremely deep facets (40% chance for 4 pixels)
							if rng.randf() < 0.4:
								img.set_pixel(x, 4, Color(0, 0, 0, 0))
				# Create dramatic diagonal facet patterns
				if x > 0 and rng.randf() < 0.65:
					img.set_pixel(x - 1, 1, Color(0, 0, 0, 0))
					if rng.randf() < 0.5:
						img.set_pixel(x - 1, 2, Color(0, 0, 0, 0))
				# Also cut on right side for angular facets
				if x < tile_size - 1 and rng.randf() < 0.55:
					img.set_pixel(x + 1, 1, Color(0, 0, 0, 0))
	
	# Bottom edge - dramatic crystalline points
	for x in range(tile_size):
		var pixel = img.get_pixel(x, tile_size - 1)
		if pixel.a > 0 and _is_similar_color(pixel, crystal_colors) and rng.randf() < 0.55:
			img.set_pixel(x, tile_size - 1, Color(0, 0, 0, 0))
			if rng.randf() < 0.7:
				img.set_pixel(x, tile_size - 2, Color(0, 0, 0, 0))
				if rng.randf() < 0.5:
					img.set_pixel(x, tile_size - 3, Color(0, 0, 0, 0))
	
	# Left and right edges - massive angular crystal faces
	for y in range(tile_size):
		# Left edge - sharp large facets (60% removal)
		var pixel_left = img.get_pixel(0, y)
		if pixel_left.a > 0 and _is_similar_color(pixel_left, crystal_colors) and rng.randf() < 0.6:
			img.set_pixel(0, y, Color(0, 0, 0, 0))
			if rng.randf() < 0.75:
				img.set_pixel(1, y, Color(0, 0, 0, 0))
				if rng.randf() < 0.65:
					img.set_pixel(2, y, Color(0, 0, 0, 0))
					if rng.randf() < 0.5:
						img.set_pixel(3, y, Color(0, 0, 0, 0))
						# Massive angular cuts (30% chance for 4 pixels)
						if rng.randf() < 0.3:
							img.set_pixel(4, y, Color(0, 0, 0, 0))
		
		# Right edge - sharp large facets (60% removal)
		var pixel_right = img.get_pixel(tile_size - 1, y)
		if pixel_right.a > 0 and _is_similar_color(pixel_right, crystal_colors) and rng.randf() < 0.6:
			img.set_pixel(tile_size - 1, y, Color(0, 0, 0, 0))
			if rng.randf() < 0.75:
				img.set_pixel(tile_size - 2, y, Color(0, 0, 0, 0))
				if rng.randf() < 0.65:
					img.set_pixel(tile_size - 3, y, Color(0, 0, 0, 0))
					if rng.randf() < 0.5:
						img.set_pixel(tile_size - 4, y, Color(0, 0, 0, 0))
						# Massive angular cuts (30% chance for 4 pixels)
						if rng.randf() < 0.3:
							img.set_pixel(tile_size - 5, y, Color(0, 0, 0, 0))

# Helper function to check if colors are similar
static func _is_similar_color(color: Color, color_array: Array) -> bool:
	for ref_color in color_array:
		var diff = abs(color.r - ref_color.r) + abs(color.g - ref_color.g) + abs(color.b - ref_color.b)
		if diff < 0.3:
			return true
	return false

static func _generate_grassland_tile(img: Image, tile_type: int, rng: RandomNumberGenerator, tile_size: int) -> Image:
	# Color palette for grassland
	var grass_colors = [
		Color(0.2, 0.6, 0.2),   # Dark grass
		Color(0.3, 0.7, 0.3),   # Medium grass
		Color(0.4, 0.8, 0.4),   # Light grass
	]
	var dirt_colors = [
		Color(0.4, 0.3, 0.2),   # Dark dirt
		Color(0.5, 0.4, 0.25),  # Medium dirt
		Color(0.6, 0.5, 0.3),   # Light dirt
	]
	
	match tile_type:
		0, 2: # GROUND or PLATFORM
			# Grass platform with irregular boundary
			for y in range(tile_size):
				for x in range(tile_size):
					# Irregular grass edge
					var grass_height = 8 + int(sin(x * 0.7 + rng.randf() * 3.14) * 1.5)
					if y < grass_height:  # Top grass layer with variation
						var grass_idx = (rng.randi() + x + y) % 3
						# Add grass blade details
						if y < 3 and rng.randf() < 0.2:
							img.set_pixel(x, y, grass_colors[2])
						else:
							img.set_pixel(x, y, grass_colors[grass_idx])
					else:  # Pure dirt subsurface
						var dirt_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, dirt_colors[dirt_idx])
			
			# Apply spiky grass edge effects to ground and platform tiles
			_add_spiky_grass_edges(img, rng, tile_size, grass_colors)
		
		1: # WALL
			# Mostly dirt with some grass patches
			for y in range(tile_size):
				for x in range(tile_size):
					if rng.randf() < 0.2:  # Occasional grass
						var grass_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, grass_colors[grass_idx])
					else:  # Mostly dirt
						var dirt_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, dirt_colors[dirt_idx])
		
		3: # ENDGOAL
			# Special golden grass flower
			img = Image.create(tile_size, 48, false, Image.FORMAT_RGBA8)
			var gold_colors = [
				Color(0.8, 0.7, 0.2),
				Color(1.0, 0.9, 0.3),
				Color(0.6, 0.5, 0.1),
			]
			for y in range(48):
				for x in range(tile_size):
					if y > 40:  # Stem at bottom
						img.set_pixel(x, y, grass_colors[1])
					elif y > 20:  # Flower
						var dist = sqrt(pow(x - tile_size/2, 2) + pow(y - 30, 2))
						if dist < 10:
							var gold_idx = (rng.randi() + x + y) % 3
							img.set_pixel(x, y, gold_colors[gold_idx])
						else:
							img.set_pixel(x, y, Color(0, 0, 0, 0))
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
		
		4: # SUBSURFACE
			# Pure dirt with no grass
			for y in range(tile_size):
				for x in range(tile_size):
					var dirt_idx = (rng.randi() + x + y) % 3
					img.set_pixel(x, y, dirt_colors[dirt_idx])
	
	return img

static func _generate_forest_tile(img: Image, tile_type: int, rng: RandomNumberGenerator, tile_size: int) -> Image:
	# Color palette for forest
	var leaf_colors = [
		Color(0.1, 0.4, 0.1),   # Dark leaves
		Color(0.2, 0.5, 0.2),   # Medium leaves
		Color(0.3, 0.6, 0.2),   # Light leaves
	]
	var bark_colors = [
		Color(0.3, 0.2, 0.1),   # Dark bark
		Color(0.4, 0.3, 0.15),  # Medium bark
		Color(0.5, 0.4, 0.2),   # Light bark
	]
	
	match tile_type:
		0, 2: # GROUND or PLATFORM
			# Branch platform with irregular moss surface
			for y in range(tile_size):
				for x in range(tile_size):
					# Irregular moss/leaf boundary
					var leaf_height = 12 + int(sin(x * 0.6 + rng.randf() * 3.14) * 2)
					if y < leaf_height:  # Moss/leaves layer with variation
						var leaf_idx = (rng.randi() + x + y) % 3
						# Add leaf texture
						if rng.randf() < 0.15:
							img.set_pixel(x, y, leaf_colors[(leaf_idx + 1) % 3])
						else:
							img.set_pixel(x, y, leaf_colors[leaf_idx])
					else:  # Dense wood/root subsurface with grain
						var bark_idx = (rng.randi() + x + y) % 3
						if x % 3 == 0 and rng.randf() < 0.2:
							img.set_pixel(x, y, bark_colors[bark_idx].darkened(0.3))
						else:
							img.set_pixel(x, y, bark_colors[bark_idx].darkened(0.2))
			
			# Apply organic leaf/moss edge effects to forest tiles
			_add_spiky_grass_edges(img, rng, tile_size, leaf_colors)
		
		1: # WALL
			# Tree trunk texture
			for y in range(tile_size):
				for x in range(tile_size):
					var bark_idx = (rng.randi() + x + int(y/4)) % 3
					img.set_pixel(x, y, bark_colors[bark_idx])
		
		3: # ENDGOAL
			# Glowing mushroom
			img = Image.create(tile_size, 48, false, Image.FORMAT_RGBA8)
			var glow_colors = [
				Color(0.8, 0.3, 0.8),
				Color(1.0, 0.4, 1.0),
				Color(0.6, 0.2, 0.6),
			]
			for y in range(48):
				for x in range(tile_size):
					if y > 35:  # Stem
						img.set_pixel(x, y, bark_colors[1])
					elif y > 20:  # Cap
						var dist_x = abs(x - tile_size/2)
						if dist_x < 12 - (y - 20) * 0.5:
							var glow_idx = (rng.randi() + x + y) % 3
							img.set_pixel(x, y, glow_colors[glow_idx])
						else:
							img.set_pixel(x, y, Color(0, 0, 0, 0))
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
		
		4: # SUBSURFACE
			# Dense wood/root texture
			for y in range(tile_size):
				for x in range(tile_size):
					var bark_idx = (rng.randi() + x + y) % 3
					img.set_pixel(x, y, bark_colors[bark_idx].darkened(0.2))
	
	return img

static func _generate_cave_tile(img: Image, tile_type: int, rng: RandomNumberGenerator, tile_size: int) -> Image:
	# Color palette for cave
	var rock_colors = [
		Color(0.1, 0.1, 0.1),   # Darkest
		Color(0.2, 0.2, 0.2),   # Dark
		Color(0.3, 0.3, 0.3),   # Medium
	]
	var mineral_colors = [
		Color(0.3, 0.4, 0.6),   # Blue mineral
		Color(0.5, 0.3, 0.6),   # Purple mineral
	]
	
	match tile_type:
		0, 2: # GROUND or PLATFORM
			# Rock platform with highly irregular surface
			for y in range(tile_size):
				for x in range(tile_size):
					# Very irregular surface using combined noise
					var noise1 = sin(x * 0.9 + rng.randf() * 6.28) * 2.5
					var noise2 = cos(x * 0.4) * 1.5
					var surface_height = 8 + int(noise1 + noise2)
					surface_height = clamp(surface_height, 6, 14)
					
					if y < surface_height:  # Surface layer with texture
						var depth_noise = sin(x * 0.7 + y * 0.5) * cos(x * 0.3 + y * 0.8)
						if rng.randf() < 0.12:  # Mineral vein clusters
							var mineral_idx = rng.randi() % 2
							img.set_pixel(x, y, mineral_colors[mineral_idx])
						else:  # Rock with protrusions and indentations
							var rock_idx = (rng.randi() + x + y) % 3
							if depth_noise > 0.4 and rng.randf() < 0.2:
								img.set_pixel(x, y, rock_colors[rock_idx].lightened(0.15))
							elif depth_noise < -0.4 and rng.randf() < 0.2:
								img.set_pixel(x, y, rock_colors[rock_idx].darkened(0.2))
							else:
								img.set_pixel(x, y, rock_colors[rock_idx])
					else:  # Deep dark subsurface
						var rock_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, rock_colors[rock_idx].darkened(0.1))
			
			# Apply jagged rock edge effects to cave tiles
			_add_jagged_rock_edges(img, rng, tile_size, rock_colors)
		
		1: # WALL
			# Cave wall with stalactites pattern
			for y in range(tile_size):
				for x in range(tile_size):
					if rng.randf() < 0.08:  # Mineral deposits
						img.set_pixel(x, y, mineral_colors[rng.randi() % 2])
					else:  # Dark rock
						var rock_idx = (rng.randi() + int(x/2) + int(y/2)) % 3
						img.set_pixel(x, y, rock_colors[rock_idx])
		
		3: # ENDGOAL
			# Glowing mineral formation
			img = Image.create(tile_size, 48, false, Image.FORMAT_RGBA8)
			for y in range(48):
				for x in range(tile_size):
					var center_dist = sqrt(pow(x - tile_size/2, 2) + pow(y - 30, 2))
					if center_dist < 12:  # Crystal formation
						if rng.randf() < 0.7:
							img.set_pixel(x, y, mineral_colors[0].lightened(0.3))
						else:
							img.set_pixel(x, y, mineral_colors[1].lightened(0.3))
					elif y > 40:  # Base rock
						img.set_pixel(x, y, rock_colors[1])
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
		
		4: # SUBSURFACE
			# Deep cave rock, very dark
			for y in range(tile_size):
				for x in range(tile_size):
					var rock_idx = (rng.randi() + x + y) % 3
					img.set_pixel(x, y, rock_colors[rock_idx].darkened(0.1))
	
	return img

static func _generate_disco_tile(img: Image, tile_type: int, rng: RandomNumberGenerator, tile_size: int) -> Image:
	# Color palette for disco - greyscale for iridescence visibility
	var floor_colors = [
		Color(0.9, 0.9, 0.9),   # Light grey/white
		Color(0.5, 0.5, 0.5),   # Medium grey
		Color(0.2, 0.2, 0.2),   # Dark grey
	]
	var dark_color = Color(0.05, 0.05, 0.1)
	
	match tile_type:
		0, 2: # GROUND or PLATFORM - checkered dance floor on top only
			# Define surface depth (checkered pattern depth)
			var surface_depth = 16
			
			for y in range(tile_size):
				for x in range(tile_size):
					if y < surface_depth:
						# Top surface - checkered pattern
						var checker = ((x / 8) + (y / 8)) % 2
						if checker == 0:
							img.set_pixel(x, y, floor_colors[0])  # White/light grey
						else:
							img.set_pixel(x, y, floor_colors[2])  # Dark grey
					else:
						# Below surface - solid underground color
						img.set_pixel(x, y, floor_colors[2].darkened(0.2))
		
		1: # WALL - dark with simple variation
			for y in range(tile_size):
				for x in range(tile_size):
					# Mostly dark with subtle grey variations
					if x % 8 < 2 and rng.randf() < 0.2:
						img.set_pixel(x, y, Color(0.15, 0.15, 0.2))
					else:
						img.set_pixel(x, y, dark_color)
		
		3: # ENDGOAL - disco ball
			img = Image.create(tile_size, 48, false, Image.FORMAT_RGBA8)
			for y in range(48):
				for x in range(tile_size):
					var center_y = 24
					var dist = sqrt(pow(x - tile_size/2, 2) + pow(y - center_y, 2))
					
					if dist < 10:  # Disco ball
						# Mirror facets
						var facet_x = int(x / 3)
						var facet_y = int(y / 3)
						if (facet_x + facet_y) % 2 == 0:
							img.set_pixel(x, y, Color(0.9, 0.9, 0.9))
						else:
							img.set_pixel(x, y, Color(0.7, 0.7, 0.7))
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
		
		4: # SUBSURFACE - dark floor continuation
			for y in range(tile_size):
				for x in range(tile_size):
					img.set_pixel(x, y, floor_colors[2].darkened(0.3))
	
	return img

static func _generate_crystal_cave_tile(img: Image, tile_type: int, rng: RandomNumberGenerator, tile_size: int) -> Image:
	# Color palette for crystal cave
	var crystal_colors = [
		Color(0.4, 0.8, 1.0),   # Bright cyan
		Color(0.3, 0.6, 0.9),   # Medium blue
		Color(0.5, 0.4, 0.9),   # Purple
	]
	var dark_colors = [
		Color(0.05, 0.05, 0.1),  # Very dark blue
		Color(0.1, 0.1, 0.15),   # Dark
	]
	
	match tile_type:
		0, 2: # GROUND or PLATFORM
			# Crystal platform with highly irregular jagged surface
			for y in range(tile_size):
				for x in range(tile_size):
					# Very irregular crystalline surface with peaks
					var noise1 = sin(x * 1.1 + rng.randf() * 6.28) * 3
					var noise2 = cos(x * 0.5 + rng.randf() * 3.14) * 2
					var surface_height = 8 + int(noise1 + noise2)
					surface_height = clamp(surface_height, 6, 16)
					
					if y < surface_height:  # Crystalline surface with jagged formations
						var crystal_pattern = sin(x * 0.6) * cos(y * 0.6) + sin(x * 1.2 + y * 0.8) * 0.5
						if rng.randf() < 0.65:  # Crystal formations with facets
							var crystal_idx = (rng.randi() + x + y) % 3
							# Add crystal facet highlights on protrusions
							if y < 8 and rng.randf() < 0.25:
								img.set_pixel(x, y, crystal_colors[crystal_idx].lightened(0.4))
							elif crystal_pattern > 0.3 and rng.randf() < 0.15:
								img.set_pixel(x, y, crystal_colors[crystal_idx].lightened(0.2))
							else:
								img.set_pixel(x, y, crystal_colors[crystal_idx])
						else:  # Dark cave rock between crystals
							var dark_idx = rng.randi() % 2
							img.set_pixel(x, y, dark_colors[dark_idx])
					else:  # Deep dark subsurface with sparse crystals
						if rng.randf() < 0.2:
							var crystal_idx = (rng.randi() + x + y) % 3
							img.set_pixel(x, y, crystal_colors[crystal_idx].darkened(0.3))
						else:
							var dark_idx = rng.randi() % 2
							img.set_pixel(x, y, dark_colors[dark_idx])
			
			# Apply sharp crystalline edge effects to crystal cave tiles
			_add_crystalline_edges(img, rng, tile_size, crystal_colors)
			# Also add some jaggedness for the cave rock parts
			_add_jagged_rock_edges(img, rng, tile_size, dark_colors)
		
		1: # WALL
			# Crystal wall
			for y in range(tile_size):
				for x in range(tile_size):
					if rng.randf() < 0.5:  # More crystals on walls
						var crystal_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, crystal_colors[crystal_idx])
					else:
						img.set_pixel(x, y, dark_colors[rng.randi() % 2])
		
		3: # ENDGOAL
			# Giant glowing crystal
			img = Image.create(tile_size, 48, false, Image.FORMAT_RGBA8)
			for y in range(48):
				for x in range(tile_size):
					# Create crystal shape pointing up
					var width_at_y = (48 - y) * 0.3
					var dist_from_center = abs(x - tile_size/2)
					if dist_from_center < width_at_y and y < 45:
						var crystal_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, crystal_colors[crystal_idx].lightened(0.3))
					elif y > 42:  # Small base
						img.set_pixel(x, y, dark_colors[0])
					else:
						img.set_pixel(x, y, Color(0, 0, 0, 0))
		
		4: # SUBSURFACE
			# Deep dark cave stone with few crystals
			for y in range(tile_size):
				for x in range(tile_size):
					if rng.randf() < 0.2:  # Fewer crystals than surface
						var crystal_idx = (rng.randi() + x + y) % 3
						img.set_pixel(x, y, crystal_colors[crystal_idx].darkened(0.3))
					else:
						var dark_idx = rng.randi() % 2
						img.set_pixel(x, y, dark_colors[dark_idx])
	
	return img
