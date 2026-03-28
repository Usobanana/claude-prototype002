extends Node2D
# Frontal wide-arc attack — used by Club (Cleric/Knight).
# Similar to fan_attack but shorter and wider.

var damage: float = 0.0
var attacker: Node = null
var target_group: String = "damageable"

@onready var hit_area: Area2D = $HitArea
@onready var collision_poly: CollisionPolygon2D = $HitArea/CollisionPolygon2D


func setup(p_attacker: Node, p_damage: float, angle_deg: float, range_px: float) -> void:
	attacker = p_attacker
	damage = p_damage
	_build_polygon(angle_deg, range_px)


func _build_polygon(angle_deg: float, range_px: float) -> void:
	var half_rad := deg_to_rad(angle_deg / 2.0)
	var segments := 6
	var points: PackedVector2Array = [Vector2.ZERO]
	for i in range(segments + 1):
		var a := lerp(-half_rad, half_rad, float(i) / float(segments))
		points.append(Vector2(cos(a), sin(a)) * range_px)
	collision_poly.polygon = points


func _ready() -> void:
	if attacker:
		rotation = attacker.get_node("MovingParts").rotation
		global_position = attacker.global_position

	await get_tree().process_frame

	if is_multiplayer_authority() or multiplayer.is_server():
		for body in hit_area.get_overlapping_bodies():
			if body != attacker and body.is_in_group(target_group):
				body.getDamage(attacker, damage, "blunt")

	queue_free()
