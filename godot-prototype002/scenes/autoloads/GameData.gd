extends Node
# Central data store for all static game definitions.
# Replaces the old Items.gd.

# ---------------------------------------------------------------------------
# Classes
# ---------------------------------------------------------------------------
var classes := {
	"warrior": {
		"name": "戦士",
		"role": "melee_attacker",
		"weapon": "sword",
		"base_hp": 300.0,
		"base_speed": 200.0,
		"base_damage": 30.0,
		"sprite_body": "0.png",
	},
	"knight": {
		"name": "騎士",
		"role": "melee_tank",
		"weapon": "spear",
		"base_hp": 450.0,
		"base_speed": 150.0,
		"base_damage": 20.0,
		"sprite_body": "1.png",
	},
	"mage": {
		"name": "魔術師",
		"role": "mid_attacker",
		"weapon": "staff",
		"base_hp": 180.0,
		"base_speed": 210.0,
		"base_damage": 40.0,
		"sprite_body": "2.png",
	},
	"archer": {
		"name": "射手",
		"role": "ranged_attacker",
		"weapon": "bow",
		"base_hp": 220.0,
		"base_speed": 230.0,
		"base_damage": 25.0,
		"sprite_body": "3.png",
	},
	"cleric": {
		"name": "僧侶",
		"role": "supporter",
		"weapon": "club",
		"base_hp": 260.0,
		"base_speed": 190.0,
		"base_damage": 15.0,
		"sprite_body": "4.png",
	},
}

# ---------------------------------------------------------------------------
# Weapons
# ---------------------------------------------------------------------------
# attack_type values:
#   "fan_aoe"      - sword: wide arc in front (fan_attack scene)
#   "linear_aoe"   - spear: narrow long line (linear_attack scene)
#   "frontal_aoe"  - club:  short wide rectangle (frontal_aoe_attack scene)
#   "projectile"   - staff/bow: spawns a projectile
var weapons := {
	"sword": {
		"attack_type": "fan_aoe",
		"angle_deg": 120.0,
		"range": 90.0,
		"cooldown": 0.6,
		"anim": "swinging",
	},
	"spear": {
		"attack_type": "linear_aoe",
		"width": 30.0,
		"range": 200.0,
		"cooldown": 0.8,
		"anim": "swinging",
	},
	"club": {
		"attack_type": "frontal_aoe",
		"angle_deg": 80.0,
		"range": 70.0,
		"cooldown": 1.0,
		"anim": "swinging",
	},
	"staff": {
		"attack_type": "projectile",
		"projectile": "magic_bolt",
		"range": 400.0,
		"cooldown": 0.9,
		"anim": "swinging",
	},
	"bow": {
		"attack_type": "projectile",
		"projectile": "arrow",
		"range": 600.0,
		"cooldown": 1.1,
		"anim": "swinging",
	},
}

# ---------------------------------------------------------------------------
# Projectiles
# ---------------------------------------------------------------------------
var projectiles := {
	"magic_bolt": {
		"speed": 400.0,
		"time": 1.5,
		"sprite": "res://assets/characters/attacks/magicBolt.png",
		"max_hits": 1,
	},
	"arrow": {
		"speed": 600.0,
		"time": 1.2,
		"sprite": "res://assets/characters/attacks/icebolt.png",
		"max_hits": 1,
	},
	"fireball": {
		"speed": 300.0,
		"time": 2.0,
		"sprite": "res://assets/characters/attacks/fireball.png",
		"max_hits": 3,
	},
}

# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------
var mobs := {
	"zombie": {
		"name": "ゾンビ",
		"max_hp": 80.0,
		"speed": 60.0,
		"attack_type": "melee",
		"damage": 10.0,
		"attack_range": 55.0,
		"attack_cooldown": 1.5,
		"xp_reward": Constants.ENEMY_KILL_XP,
		"sprite": "res://assets/characters/enemy/zombie.png",
	},
	"spider": {
		"name": "スパイダー",
		"max_hp": 120.0,
		"speed": 110.0,
		"attack_type": "projectile",
		"projectile": "magic_bolt",
		"damage": 15.0,
		"attack_range": 350.0,
		"attack_cooldown": 2.0,
		"xp_reward": Constants.ENEMY_KILL_XP,
		"sprite": "res://assets/characters/enemy/spider.png",
	},
	"elite_zombie": {
		"name": "エリートゾンビ",
		"max_hp": 300.0,
		"speed": 70.0,
		"attack_type": "melee",
		"damage": 25.0,
		"attack_range": 60.0,
		"attack_cooldown": 1.2,
		"xp_reward": Constants.ENEMY_KILL_XP * 3,
		"sprite": "res://assets/characters/enemy/zombie.png",
	},
}

# ---------------------------------------------------------------------------
# Skills
# ---------------------------------------------------------------------------
# type:
#   "active_replace" - replaces a base active skill slot with a new behavior
#   "active_enhance" - upgrades an existing active skill (damage, cooldown, etc.)
#   "passive"        - always-on stat or behavior modifier
#   "stat_boost"     - increases base stats
#
# class_filter: which classes can receive this skill (empty = all classes)
var skills := {
	# Warrior skills
	"warrior_whirlwind": {
		"name": "旋風斬",
		"description": "通常攻撃が360度の範囲攻撃に変化する",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["warrior"],
		"evolution_of": "",
	},
	"warrior_charge": {
		"name": "突撃",
		"description": "前方に素早くダッシュし、通過した敵にダメージ",
		"type": "active_replace",
		"slot": 1,
		"class_filter": ["warrior"],
		"evolution_of": "",
	},
	"warrior_battle_cry": {
		"name": "雄叫び",
		"description": "一時的に攻撃力を50%増加させる",
		"type": "active_replace",
		"slot": 2,
		"class_filter": ["warrior"],
		"evolution_of": "",
	},
	"warrior_whirlwind_ex": {
		"name": "烈風斬",
		"description": "旋風斬が2回転し、ダメージが増加する",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["warrior"],
		"evolution_of": "warrior_whirlwind",
	},
	"warrior_tough_skin": {
		"name": "鋼の皮膚",
		"description": "被ダメージを10%軽減する",
		"type": "passive",
		"slot": 0,
		"class_filter": ["warrior"],
		"stat_mod": {"damage_reduction": 0.10},
		"evolution_of": "",
	},
	"warrior_berserker": {
		"name": "狂戦士",
		"description": "HP50%以下で攻撃力が20%増加する",
		"type": "passive",
		"slot": 1,
		"class_filter": ["warrior"],
		"evolution_of": "",
	},
	# Knight skills
	"knight_shield_bash": {
		"name": "シールドバッシュ",
		"description": "前方の敵を盾で弾き飛ばし、スタンさせる",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["knight"],
		"evolution_of": "",
	},
	"knight_taunt": {
		"name": "挑発",
		"description": "周囲の敵の注意を自分に向ける",
		"type": "active_replace",
		"slot": 1,
		"class_filter": ["knight"],
		"evolution_of": "",
	},
	"knight_iron_wall": {
		"name": "鉄壁",
		"description": "被ダメージを15%軽減する",
		"type": "passive",
		"slot": 0,
		"class_filter": ["knight"],
		"stat_mod": {"damage_reduction": 0.15},
		"evolution_of": "",
	},
	"knight_fortress": {
		"name": "要塞化",
		"description": "鉄壁強化：軽減率25%、HP30以下で効果2倍",
		"type": "passive",
		"slot": 0,
		"class_filter": ["knight"],
		"stat_mod": {"damage_reduction": 0.25},
		"evolution_of": "knight_iron_wall",
	},
	# Mage skills
	"mage_fireball": {
		"name": "ファイアボール",
		"description": "着弾時に範囲爆発するファイアボールを放つ",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["mage"],
		"evolution_of": "",
	},
	"mage_blizzard": {
		"name": "ブリザード",
		"description": "前方範囲に氷嵐を発生させ、敵を凍結させる",
		"type": "active_replace",
		"slot": 1,
		"class_filter": ["mage"],
		"evolution_of": "",
	},
	"mage_arcane_surge": {
		"name": "魔力解放",
		"description": "次の攻撃の威力が3倍になる",
		"type": "active_replace",
		"slot": 2,
		"class_filter": ["mage"],
		"evolution_of": "",
	},
	"mage_mana_shield": {
		"name": "魔法の盾",
		"description": "被ダメージを魔力で5%吸収する",
		"type": "passive",
		"slot": 0,
		"class_filter": ["mage"],
		"stat_mod": {"damage_reduction": 0.05},
		"evolution_of": "",
	},
	# Archer skills
	"archer_multishot": {
		"name": "マルチショット",
		"description": "1回の攻撃で3本の矢を同時に放つ",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["archer"],
		"evolution_of": "",
	},
	"archer_snipe": {
		"name": "スナイプ",
		"description": "長射程の高威力単体攻撃",
		"type": "active_replace",
		"slot": 1,
		"class_filter": ["archer"],
		"evolution_of": "",
	},
	"archer_wind_step": {
		"name": "風歩き",
		"description": "移動速度が15%増加する",
		"type": "passive",
		"slot": 0,
		"class_filter": ["archer"],
		"stat_mod": {"speed_bonus": 0.15},
		"evolution_of": "",
	},
	# Cleric skills
	"cleric_heal": {
		"name": "ヒール",
		"description": "自分または近くの味方のHPを回復する",
		"type": "active_replace",
		"slot": 0,
		"class_filter": ["cleric"],
		"evolution_of": "",
	},
	"cleric_holy_light": {
		"name": "聖光",
		"description": "周囲の味方全員のHPを小回復する",
		"type": "active_replace",
		"slot": 1,
		"class_filter": ["cleric"],
		"evolution_of": "",
	},
	"cleric_divine_shield": {
		"name": "ディバインシールド",
		"description": "一時的にダメージを無効化するバリアを張る",
		"type": "active_replace",
		"slot": 2,
		"class_filter": ["cleric"],
		"evolution_of": "",
	},
	"cleric_blessed": {
		"name": "祝福",
		"description": "HPが毎秒2回復する",
		"type": "passive",
		"slot": 0,
		"class_filter": ["cleric"],
		"evolution_of": "",
	},
	# Universal stat boosts (available to all classes)
	"stat_hp_up": {
		"name": "HP強化",
		"description": "最大HPが50増加する",
		"type": "stat_boost",
		"slot": -1,
		"class_filter": [],
		"stat_mod": {"max_hp": 50.0},
		"evolution_of": "",
	},
	"stat_speed_up": {
		"name": "俊足",
		"description": "移動速度が10%増加する",
		"type": "stat_boost",
		"slot": -1,
		"class_filter": [],
		"stat_mod": {"speed_bonus": 0.10},
		"evolution_of": "",
	},
	"stat_damage_up": {
		"name": "攻撃強化",
		"description": "攻撃力が15%増加する",
		"type": "stat_boost",
		"slot": -1,
		"class_filter": [],
		"stat_mod": {"damage_bonus": 0.15},
		"evolution_of": "",
	},
}

# ---------------------------------------------------------------------------
# Default skill loadouts per class (before any level-up choices)
# ---------------------------------------------------------------------------
var class_base_skills := {
	"warrior": {
		"active": ["warrior_whirlwind", "warrior_charge", "warrior_battle_cry"],
		"passive": ["warrior_tough_skin", "warrior_berserker"],
	},
	"knight": {
		"active": ["knight_shield_bash", "knight_taunt", ""],
		"passive": ["knight_iron_wall", ""],
	},
	"mage": {
		"active": ["mage_fireball", "mage_blizzard", "mage_arcane_surge"],
		"passive": ["mage_mana_shield", ""],
	},
	"archer": {
		"active": ["archer_multishot", "archer_snipe", ""],
		"passive": ["archer_wind_step", ""],
	},
	"cleric": {
		"active": ["cleric_heal", "cleric_holy_light", "cleric_divine_shield"],
		"passive": ["cleric_blessed", ""],
	},
}

# ---------------------------------------------------------------------------
# Helper: get candidate upgrade options for level-up picker
# Returns an array of skill IDs valid for the given class and current skill state.
# ---------------------------------------------------------------------------
func get_levelup_options(player_class: String, current_skills: Array) -> Array:
	var candidates: Array = []

	for skill_id in skills:
		var s: Dictionary = skills[skill_id]

		# Class filter
		if s["class_filter"].size() > 0 and player_class not in s["class_filter"]:
			continue

		# Skip if already owned
		if skill_id in current_skills:
			continue

		# Evolution: only offer if base skill is already owned
		if s["evolution_of"] != "" and s["evolution_of"] not in current_skills:
			continue

		candidates.append(skill_id)

	candidates.shuffle()
	return candidates.slice(0, Constants.SKILL_CHOICES_ON_LEVELUP)


# ---------------------------------------------------------------------------
# Helper: spawn a projectile into the scene tree
# ---------------------------------------------------------------------------
func spawn_projectile(shooter: Node, projectile_id: String, target_pos: Vector2, target_group: String) -> void:
	if not multiplayer.is_server():
		return
	if projectile_id not in projectiles:
		return

	var proj_data: Dictionary = projectiles[projectile_id]
	var proj_scene := preload("res://scenes/attacks/projectile_attack.tscn")
	var proj := proj_scene.instantiate()
	shooter.get_parent().add_child(proj, true)
	proj.global_position = shooter.global_position
	proj.setup(shooter, proj_data, target_pos, target_group)
