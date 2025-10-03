extends RefCounted
class_name BiomeStylePalettes

# Generate nature/biome-based color palettes
static func generate_grassland_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Grassland - greens and earth tones
	var grass_hue = rng.randf_range(0.25, 0.35)  # Green range
	var earth_hue = rng.randf_range(0.08, 0.12)  # Brown range
	
	# Grass colors
	var grass_light = Color.from_hsv(grass_hue, 0.5, 0.7)
	var grass_medium = Color.from_hsv(grass_hue, 0.6, 0.5)
	var grass_dark = Color.from_hsv(grass_hue + 0.02, 0.7, 0.3)
	
	# Earth colors
	var earth_light = Color.from_hsv(earth_hue, 0.4, 0.5)
	var earth_dark = Color.from_hsv(earth_hue, 0.5, 0.3)
	
	# Sky/atmosphere hint
	var sky_hint = Color.from_hsv(0.55, 0.2, 0.9)
	
	return {
		"grass_light": grass_light,
		"grass_medium": grass_medium,
		"grass_dark": grass_dark,
		"earth_light": earth_light,
		"earth_dark": earth_dark,
		"sky_hint": sky_hint
	}

static func generate_forest_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Forest - deep greens, browns, and shadows
	var tree_hue = rng.randf_range(0.28, 0.33)  # Deep green
	var bark_hue = rng.randf_range(0.05, 0.08)  # Dark brown
	
	# Tree/leaf colors
	var canopy_light = Color.from_hsv(tree_hue, 0.4, 0.6)
	var canopy_medium = Color.from_hsv(tree_hue, 0.6, 0.4)
	var canopy_dark = Color.from_hsv(tree_hue + 0.03, 0.7, 0.2)
	
	# Bark/wood colors
	var bark_light = Color.from_hsv(bark_hue, 0.3, 0.4)
	var bark_dark = Color.from_hsv(bark_hue, 0.4, 0.2)
	
	# Forest floor
	var moss_color = Color.from_hsv(0.3, 0.5, 0.35)
	
	return {
		"canopy_light": canopy_light,
		"canopy_medium": canopy_medium,
		"canopy_dark": canopy_dark,
		"bark_light": bark_light,
		"bark_dark": bark_dark,
		"moss_color": moss_color
	}

static func generate_ruins_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Ruins - stone, moss, ancient materials
	var stone_value = rng.randf_range(0.3, 0.5)
	var moss_hue = rng.randf_range(0.25, 0.35)
	
	# Stone colors
	var stone_light = Color(stone_value + 0.2, stone_value + 0.2, stone_value + 0.15)
	var stone_medium = Color(stone_value, stone_value, stone_value - 0.05)
	var stone_dark = Color(stone_value - 0.15, stone_value - 0.15, stone_value - 0.2)
	
	# Weathered/moss covered stones
	var moss_stone = Color.from_hsv(moss_hue, 0.3, 0.4)
	
	# Accent colors (ancient metals, gems)
	var accent_copper = Color(0.7, 0.45, 0.3)
	var accent_jade = Color.from_hsv(0.33, 0.4, 0.5)
	
	return {
		"stone_light": stone_light,
		"stone_medium": stone_medium,
		"stone_dark": stone_dark,
		"moss_stone": moss_stone,
		"accent_copper": accent_copper,
		"accent_jade": accent_jade
	}

static func generate_cave_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Cave - dark stones, minerals
	var base_value = rng.randf_range(0.15, 0.25)
	
	# Cave rock colors
	var rock_darkest = Color(base_value - 0.05, base_value - 0.05, base_value)
	var rock_dark = Color(base_value, base_value, base_value + 0.05)
	var rock_medium = Color(base_value + 0.1, base_value + 0.1, base_value + 0.15)
	
	# Mineral hints
	var mineral_blue = Color.from_hsv(0.6, 0.3, 0.4)
	var mineral_purple = Color.from_hsv(0.75, 0.25, 0.35)
	
	# Wet rock shimmer
	var wet_highlight = Color(base_value + 0.25, base_value + 0.25, base_value + 0.3)
	
	return {
		"rock_darkest": rock_darkest,
		"rock_dark": rock_dark,
		"rock_medium": rock_medium,
		"mineral_blue": mineral_blue,
		"mineral_purple": mineral_purple,
		"wet_highlight": wet_highlight
	}

static func generate_disco_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Disco - greyscale floor for iridescence visibility
	
	# Neon spotlight colors (high saturation, high brightness)
	var neon_pink = Color.from_hsv(0.92, 0.9, 1.0)
	var neon_blue = Color.from_hsv(0.6, 0.9, 1.0)
	var neon_green = Color.from_hsv(0.33, 0.9, 1.0)
	var neon_purple = Color.from_hsv(0.75, 0.9, 1.0)
	
	# Greyscale dance floor colors (black, white, grey)
	var floor_light = Color(0.9, 0.9, 0.9)  # Light grey/white
	var floor_medium = Color(0.5, 0.5, 0.5)  # Medium grey
	var floor_dark = Color(0.2, 0.2, 0.2)  # Dark grey
	
	# Dark base (nightclub darkness)
	var club_black = Color(0.02, 0.02, 0.05)
	var club_shadow = Color(0.05, 0.05, 0.1)
	
	# Mirror ball sparkle
	var mirror_sparkle = Color(1.0, 1.0, 1.0)
	
	return {
		"neon_pink": neon_pink,
		"neon_blue": neon_blue,
		"neon_green": neon_green,
		"neon_purple": neon_purple,
		"floor_light": floor_light,
		"floor_medium": floor_medium,
		"floor_dark": floor_dark,
		"club_black": club_black,
		"club_shadow": club_shadow,
		"mirror_sparkle": mirror_sparkle
	}
