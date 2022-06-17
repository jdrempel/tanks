extends Spatial


export var detonate_time := 2
export var setup_time := 2

export(SpatialMaterial) var idle_material
export(SpatialMaterial) var triggered_material

var materials: Array
var material_idx := 0
var flash_time := 0.05


func _ready():
	materials = [idle_material, triggered_material]


func initialize():
	pass


func destroy():
	var bodies_inside = $TankDetectArea.get_overlapping_bodies()
	for body in bodies_inside:
		if not body.is_in_group("static"):
			body.destroy()
	queue_free()


func _on_ProjectileDetectArea_body_entered(body):
	if body.is_in_group("projectiles"):
		body.destroy()
		destroy()


func _on_TankDetectArea_body_entered(body):
	if body.is_in_group("tanks"):
		$DetonateTimer.start(detonate_time)
		$FlashTimer.start(flash_time)


func _on_SetupTimer_timeout():
	$TankDetectArea/TankCollision.disabled = false
	$ProjectileDetectArea/ProjectileCollision.disabled = false
	# Below is bugged - only triggers if one of the tanks inside moves
	var bodies_inside = $TankDetectArea.get_overlapping_bodies()
	for body in bodies_inside:
		if body.is_in_group("tanks"):
			$DetonateTimer.start(detonate_time)
			break


func _on_DetonateTimer_timeout():
	destroy()


func _on_FlashTimer_timeout():
	material_idx = (material_idx + 1) % 2
	$Body.material_override = materials[material_idx]
	$FlashTimer.start(flash_time)
