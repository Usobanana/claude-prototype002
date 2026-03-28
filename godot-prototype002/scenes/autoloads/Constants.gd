extends Node

# Multiplayer
const SERVER_IP := "localhost"
const PORT := 3131
const USE_SSL := false
const TRUSTED_CHAIN_PATH := ""
const PRIVATE_KEY_PATH := ""

# Map
const MAP_SIZE := Vector2i(200, 200)
const TILE_SIZE := 64  # pixels per tile (isometric tile width)

# Match
const MATCH_DURATION := 1200.0        # 20 minutes in seconds
const EXTRACTION_REVEAL_TIME := 180.0  # 3 minutes until extraction points appear
const EXTRACTION_COUNT := 5
const EXTRACT_CHANNEL_TIME := 5.0     # seconds to channel extraction
const REVIVE_CHANNEL_TIME := 10.0     # seconds to revive a downed teammate
const FINISHOFF_HOLD_TIME := 1.5      # seconds to hold finish-off
const DOWN_DRAIN_TIME := 30.0         # seconds before downed player auto-dies
const REVIVE_HP_PERCENT := 0.30       # HP fraction restored on revive

# Shrinking circle phases: [duration_sec, damage_per_sec, end_radius_fraction]
# radius fraction is relative to the initial full-map radius
const CIRCLE_PHASES := [
	{"duration": 300.0, "damage": 3.0,  "end_radius": 0.70},  # Phase 1: 0-5min
	{"duration": 300.0, "damage": 8.0,  "end_radius": 0.40},  # Phase 2: 5-10min
	{"duration": 300.0, "damage": 18.0, "end_radius": 0.15},  # Phase 3: 10-15min
	{"duration": 300.0, "damage": 35.0, "end_radius": 0.0},   # Phase 4: 15-20min
]

# Enemy spawning
const MAX_ENEMIES_PER_PLAYER := 3
const ENEMY_SPAWN_RADIUS_MIN := 10
const ENEMY_SPAWN_RADIUS_MAX := 14

# Match-internal skill system
const MAX_MATCH_LEVEL := 10
const SKILL_CHOICES_ON_LEVELUP := 3
# Cumulative XP thresholds to reach each level (index = target level)
const XP_THRESHOLDS := [0, 100, 250, 450, 700, 1000, 1350, 1750, 2200, 2700]
const ENEMY_KILL_XP := 100

# Insurance slots
const BASE_INSURANCE_SLOTS := 1
const MAX_INSURANCE_SLOTS := 3  # max with season pass
