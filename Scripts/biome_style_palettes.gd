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

static func generate_crystal_cave_palette(rng: RandomNumberGenerator) -> Dictionary:
	# Crystal Cave - vibrant crystals, dark backgrounds
	var crystal_hue = rng.randf()  # Any hue for crystals
	var secondary_hue = fmod(crystal_hue + 0.3, 1.0)  # Complementary
	
	# Crystal colors (bright and saturated)
	var crystal_bright = Color.from_hsv(crystal_hue, 0.7, 0.9)
	var crystal_medium = Color.from_hsv(crystal_hue, 0.8, 0.7)
	var crystal_dark = Color.from_hsv(crystal_hue, 0.9, 0.5)
	
	# Secondary crystals
	var crystal_secondary = Color.from_hsv(secondary_hue, 0.6, 0.6)
	
	# Cave background (very dark)
	var cave_black = Color(0.05, 0.05, 0.08)
	var cave_shadow = Color(0.1, 0.1, 0.15)
	
	return {
		"crystal_bright": crystal_bright,
		"crystal_medium": crystal_medium,
		"crystal_dark": crystal_dark,
		"crystal_secondary": crystal_secondary,
		"cave_black": cave_black,
		"cave_shadow": cave_shadow
	}
