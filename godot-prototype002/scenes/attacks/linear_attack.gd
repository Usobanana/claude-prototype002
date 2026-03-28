extends Node2D
# Linear (straight line) melee attack — used by Spear.
# Thin rectangle extending forward from the attacker.

var damage: float = 0.0
var attacker: Node = null
var target_group: String = "damageable"

@onready var hit_area: Area2D = $HitArea
@onready var collision_shape: CollisionShape2D = $HitArea/CollisionShape2D


func setup(p_attacker: Node, p_damage: float, width_px: float, range_px: float) -> void:
	attacker = p_attacker
	damage = p_damage
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_px, range_px)
	collision_shape.shape = rect
	# Offset so the rectangle starts at the attacker and extends forward
	collision_shape.position = Vector2(0.0, -range_px / 2.0)


func _ready() -> void:
	if attacker:
		rotation = attacker.get_node("MovingParts").rotation
		global_position = attacker.global_position

	await get_tree().process_frame

	if is_multiplayer_authority() or multiplayer.is_server():
		for body in hit_area.get_overlapping_bodies():
			if body != attacker and body.is_in_group(target_group):
				body.getDamage(attacker, damage, "pierce")

	queue_free()
