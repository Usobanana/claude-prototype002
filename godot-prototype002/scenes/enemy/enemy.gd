extends CharacterBody2D

var spawner : Node2D
var targetPlayer : CharacterBody2D
@export var targetPlayerId : int:
	set(value):
		targetPlayerId = value
		targetPlayer = get_node("../../Players/"+str(value))

#stats
@export var enemyId := "":
	set(value):
		enemyId = value
		if value not in GameData.mobs:
			return
		var data: Dictionary = GameData.mobs[value]
		if is_node_ready():
			%Sprite2D.texture = load(data.get("sprite", "res://assets/characters/enemy/zombie.png"))
		maxhp   = data.get("max_hp",       100.0)
		speed   = data.get("speed",         60.0)
		attackRange  = data.get("attack_range",  55.0)
		attackDamage = data.get("damage",        10.0)
		attack  = data.get("attack_type",  "melee")

var maxhp := 100.0:
	set(value):
		maxhp = value
		hp = value
var hp := maxhp:
	set(value):
		hp = value
		$EnemyUI/HPBar.value = hp/maxhp
var speed := 2000.0
var attack := ""
var attackRange := 50.0
var attackDamage := 20.0
var drops := {}

func _process(_delta):
	if !multiplayer.is_server():
		return
	if is_instance_valid(targetPlayer):
		rotateToTarget()
		if position.distance_to(targetPlayer.position) > attackRange:
			move_towards_position()
		else:
			tryAttack()
	else:
		die(false)

func rotateToTarget():
	$MovingParts.look_at(targetPlayer.position)

func move_towards_position():
	var direction = (targetPlayer.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

func tryAttack():
	if not multiplayer.is_server() or not $AttackCooldown.is_stopped():
		return
	$AttackCooldown.start()
	if attack == "melee":
		if is_instance_valid(targetPlayer):
			targetPlayer.getDamage(self, attackDamage, "normal")
	elif attack == "projectile":
		var mob_data: Dictionary = GameData.mobs.get(enemyId, {})
		var proj_id: String = mob_data.get("projectile", "magic_bolt")
		GameData.spawn_projectile(self, proj_id, targetPlayer.global_position, "player")
		
func hitPlayer(body):
	if multiplayer.is_server():
		body.getDamage(self, attackDamage, "normal")
	
func getDamage(causer, amount, _type):
	hp -= amount
	$bloodParticles.emitting = true
	if hp <= 0:
		if causer.is_in_group("player"):
			causer.mob_killed.emit()
		die(true)

func die(dropLoot):
	if multiplayer.is_server():
		spawner.decreasePlayerEnemyCount(targetPlayerId)
		queue_free()
		if dropLoot:
			dropLoots()

func dropLoots():
	for drop in drops.keys():
		Items.spawnPickups(drop, position, randi_range(drops[drop]["min"],drops[drop]["max"]))
