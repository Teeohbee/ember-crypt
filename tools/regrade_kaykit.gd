extends SceneTree
# Regrades KayKit's bright toy-box atlases into something grimmer: colour drained, shadows pushed to rust
# and highlights to old bone, the brightest whites knocked back, and a mottle of grime. The atlases are
# gradient swatches every face samples, so this carries straight onto the models.
#
# Reads the untouched atlases in assets/kaykit_originals/ (ignored by Godot) and writes over the live ones
# in assets/kaykit/, so it can be tuned and rerun as often as you like:
#
#   godot --headless --path . -s tools/regrade_kaykit.gd
#   godot --headless --path . --import

const ORIGINALS := "res://assets/kaykit_originals/"
const LIVE := "res://assets/kaykit/"

const RUST := Color(0.30, 0.17, 0.11)
const BONE := Color(0.84, 0.78, 0.64)
# Above this brightness, values are squashed by HIGHLIGHT_SQUASH, so nothing glows white like new paint
const HIGHLIGHT_KNEE := 0.72
const HIGHLIGHT_SQUASH := 0.45
# How much of its own colour skin keeps through the drain and the tone (0-1)
const SKIN_KEEPS := 0.75

# Atlas: how much colour to drain (0-1), how far to pull toward the rust-to-bone ramp (0-1), how much
# grime darkens the dirtiest spots (0-1)
const GRADES := {
	"adventurers/characters/barbarian_texture.png": [0.45, 0.22, 0.16],
	"adventurers/characters/knight_texture.png": [0.45, 0.22, 0.16],
	"adventurers/characters/mage_texture.png": [0.40, 0.20, 0.16],
	"adventurers/characters/rogue_texture.png": [0.45, 0.22, 0.16],
	"adventurers/weapons/barbarian_texture.png": [0.45, 0.22, 0.16],
	"adventurers/weapons/knight_texture.png": [0.45, 0.22, 0.16],
	"adventurers/weapons/mage_texture.png": [0.40, 0.20, 0.16],
	"adventurers/weapons/rogue_texture.png": [0.45, 0.22, 0.16],
	# Skeletons go furthest: yellowed, filthy bone
	"skeletons/characters/skeleton_texture.png": [0.55, 0.38, 0.22],
	"skeletons/weapons/skeleton_texture.png": [0.55, 0.38, 0.22],
	# The crypt is already in the dark, so it needs less draining
	"dungeon/dungeon_texture.png": [0.35, 0.18, 0.20],
}

func _initialize() -> void:
	var grime := FastNoiseLite.new()
	grime.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	grime.fractal_type = FastNoiseLite.FRACTAL_FBM
	grime.fractal_octaves = 4
	grime.frequency = 0.012
	grime.seed = 7
	for atlas: String in GRADES:
		var grade: Array = GRADES[atlas]
		var image := Image.load_from_file(ProjectSettings.globalize_path(ORIGINALS + atlas))
		image.convert(Image.FORMAT_RGBA8)
		regrade(image, grade[0], grade[1], grade[2], grime)
		image.save_png(ProjectSettings.globalize_path(LIVE + atlas))
		print("regraded ", atlas)
	quit()

static func regrade(image: Image, drain: float, tone: float, dirt: float, grime: FastNoiseLite) -> void:
	for y in image.get_height():
		for x in image.get_width():
			var colour := image.get_pixel(x, y)
			var luminance := colour.r * 0.299 + colour.g * 0.587 + colour.b * 0.114
			# Skin keeps most of its warmth, or the heroes look as dead as what they're fighting
			var keep := SKIN_KEEPS if is_skin(colour) else 0.0
			var graded := colour.lerp(Color(luminance, luminance, luminance, colour.a), drain * (1.0 - keep))
			graded = graded.lerp(RUST.lerp(BONE, luminance), tone * (1.0 - keep))
			graded.r = lerpf(_squash(graded.r), graded.r, keep)
			graded.g = lerpf(_squash(graded.g), graded.g, keep)
			graded.b = lerpf(_squash(graded.b), graded.b, keep)
			# Noise is -1..1; only the darker half leaves dirt, so clean patches stay clean
			var filth := clampf(-grime.get_noise_2d(x, y), 0.0, 1.0)
			graded = graded.darkened(filth * dirt * (1.0 - keep))
			graded.a = colour.a
			image.set_pixel(x, y, graded)

# Light, warm and gently saturated: the peach swatches faces and hands sample
static func is_skin(colour: Color) -> bool:
	return colour.h > 0.02 and colour.h < 0.11 and colour.s > 0.18 and colour.s < 0.55 and colour.v > 0.6

static func _squash(value: float) -> float:
	return value if value <= HIGHLIGHT_KNEE else HIGHLIGHT_KNEE + (value - HIGHLIGHT_KNEE) * HIGHLIGHT_SQUASH
