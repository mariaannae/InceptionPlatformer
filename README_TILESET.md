# Procedurally Generated Tileset System

This project features a runtime shader-based procedurally generated tileset system that creates unique visual styles for your platformer game.

## Features

- **Three Visual Styles**: 
  - **Minimalist**: Clean geometric patterns with solid colors
  - **Pixel Art**: Retro dithered patterns with limited color palettes
  - **Smooth/Modern**: Gradient-based organic textures

- **Random Style Selection**: Each generation randomly selects one of the three styles
- **Procedural Color Palettes**: Harmonious color schemes generated automatically
- **Three Tile Types**:
  - Ground tiles (full collision)
  - Wall tiles (full collision)
  - Platform tiles (one-way collision, top-only)

- **Web-Optimized**: Shader-based generation runs on GPU for excellent web performance
- **Caching System**: Generated tiles are cached to avoid redundant rendering
- **Seed-Based Generation**: Reproducible results with specific seeds

## How It Works

1. **TileStyleConfig.gd**: Manages style types, generates color palettes, and configuration
2. **Shaders**: Three shader files create the visual appearance:
   - `minimalist_tile.gdshader`
   - `pixel_tile.gdshader`
   - `smooth_tile.gdshader`
3. **TilesetGenerator.gd**: Orchestrates generation, creates textures, and sets up collision

## Usage

### Running the Game

1. Open the project in Godot 4.x
2. Run the Dream scene (F5 or Play button)
3. The tileset will automatically generate on startup
4. A test level will be painted showing all three tile types

### Regenerating Tiles

**Press 'R'** at any time during gameplay to regenerate the tileset with a new random style and color palette.

### Configuration

In the TileMap node (Scripts/TilesetGenerator.gd), you can adjust:

- `tile_size`: Size of each tile (default: 32x32)
- `initial_seed`: Specific seed for reproducible generation (default: -1 for random)
- `auto_generate`: Whether to generate on scene start (default: true)

### Programmatic Control

```gdscript
# Access the TileMap node
var tilemap = $TileMap

# Regenerate with random style
await tilemap.regenerate_tileset()

# Regenerate with specific seed
await tilemap.regenerate_tileset(123.456)

# Get current style info
print(tilemap.get_current_style())  # e.g., "Minimalist"
print(tilemap.get_current_seed())   # e.g., 347.821
```

## File Structure

```
Shaders/
  ├── minimalist_tile.gdshader  # Clean geometric shader
  ├── pixel_tile.gdshader       # Retro pixel art shader
  └── smooth_tile.gdshader      # Modern gradient shader

Scripts/
  ├── TileStyleConfig.gd        # Style configuration and palette generation
  └── TilesetGenerator.gd       # Main tileset generation system

Scenes/
  └── Dream.tscn               # Main scene with TileMap
```

## Technical Details

### Shader-Based Generation

- Tiles are generated at runtime using GPU shaders
- Each shader receives color palette and seed parameters
- 32x32 textures are rendered to SubViewport then captured
- Results are cached to avoid regeneration

### Collision Setup

- Ground tiles: Full collision polygon
- Wall tiles: Full collision polygon
- Platform tiles: Top-only collision with one-way enabled

### Web Deployment

The system is optimized for web:
- Lightweight shaders for 60fps performance
- Texture caching reduces overhead
- WebGL 2.0/WebGPU compatible
- Limited tile count prevents memory issues

## Next Steps

This system provides the foundation for:
- Procedural level generation (future feature)
- Additional tile types (decorations, hazards)
- More visual styles
- Tile variations within each style
- Auto-tiling support for seamless connections

## Controls

- **Arrow Keys / WASD**: Move player
- **Space**: Jump
- **R**: Regenerate tileset with new style
