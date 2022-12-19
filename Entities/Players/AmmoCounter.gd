extends Spatial


func initialize(max_bullets: int) -> void:
    for bullet in max_bullets:
        var new_bullet = $BulletSprite.duplicate()
        new_bullet.offset.x = (bullet - ceil(bullet / max_bullets) - max_bullets / 2) * 200
        add_child(new_bullet)
    $BulletSprite.queue_free()


func add_live_round() -> void:
    var bullet_to_hide = null
    for bullet in get_children():
        if bullet.visible:
            bullet_to_hide = bullet
    if bullet_to_hide != null:
        bullet_to_hide.hide()


func subtract_live_round() -> void:
    var bullet_to_show = null
    for bullet in get_children():
        if not bullet.visible:
            bullet_to_show = bullet
            break
    if bullet_to_show != null:
        bullet_to_show.show()
