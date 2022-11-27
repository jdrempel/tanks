extends Spatial


export var detonate_time := 2
export var setup_time := 2

export(SpatialMaterial) var idle_material
export(SpatialMaterial) var triggered_material

var materials: Array
var light_colors: Array
var material_idx := 0
var flash_time := 0.05

var player_shot = false
var is_dying = false
var paused = false

export(PackedScene) var death_explosion


func _ready():
    randomize()
#    if randf() > 0.75:
#        $NavCollision.disabled = true
    materials = [idle_material, triggered_material]
    light_colors = [Color.yellow, Color.red]


func initialize(master_id: int, spawn_time: int, player_owned: bool):
    set_name("m_%d_%d" % [master_id, spawn_time])
    player_shot = player_owned
    if player_owned and is_network_master():
        GameState.add_player_mine(master_id)


func set_paused(val: bool) -> void:
    paused = val
    $SetupTimer.paused = val
    $DetonateTimer.paused = val


remotesync func destroy():
    if is_dying:
        return
    is_dying = true
    var bodies_inside = $TankDetectArea.get_overlapping_bodies()
    for body in bodies_inside:
        print(body.get_name())
        if (not body.is_in_group("static")) and body != self and body.has_method("destroy"):
            body.destroy()
        elif body.owner is CorkBlock:
            body.owner.destroy()
    var explosion = death_explosion.instance()
    get_parent().add_child(explosion)
    explosion.global_transform.origin = self.global_transform.origin
    for child in explosion.get_children():
        if not (child is CPUParticles):
            continue
        child.emitting = true
    Globals.camera.add_trauma(40.0)
    AudioManager.play_sound($DestroySound)
    queue_free()


func _on_ProjectileDetectArea_body_entered(body):
    if body is Projectile:
        body.rpc("destroy")
        rpc("destroy")


func _on_TankDetectArea_body_entered(body):
    if body is Player or body is Enemy:
        AudioManager.play_sound($TriggerSound)
        $DetonateTimer.start(detonate_time)
        $FlashTimer.start(flash_time)


func _on_SetupTimer_timeout():
    $OmniLight.show()
    $Body.material_override = idle_material
    $TankDetectArea/TankCollision.disabled = false
    $ProjectileDetectArea/ProjectileCollision.disabled = false
    var bodies_inside = $TankDetectArea.get_overlapping_bodies()
    for body in bodies_inside:
        if body is Player or body is Enemy:
            AudioManager.play_sound($TriggerSound)
            $DetonateTimer.start(detonate_time)
            break


func _on_DetonateTimer_timeout():
    rpc("destroy")


func _on_FlashTimer_timeout():
    material_idx = (material_idx + 1) % 2
    $Body.material_override = materials[material_idx]
    $OmniLight.light_color = light_colors[material_idx]
    $FlashTimer.start(flash_time)


func _on_LifeTimer_timeout() -> void:
    AudioManager.play_sound($TriggerSound)
    $DetonateTimer.start(detonate_time)
    $FlashTimer.start(flash_time)
