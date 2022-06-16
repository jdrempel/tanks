extends Spatial


func initialize():
	pass


func _on_ProjectileDetectArea_body_entered(body):
	if body.is_in_group("projectiles"):
		print("projectile entered")


func _on_TankDetectArea_body_entered(body):
	if body.is_in_group("tanks"):
		print("tank entered")


func _on_SetupTimer_timeout():
	$TankDetectArea/TankCollision.disabled = false
	$ProjectileDetectArea/ProjectileCollision.disabled = false
