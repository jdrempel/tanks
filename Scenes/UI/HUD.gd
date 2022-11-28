extends Control


func add_live_round() -> void:
    var bullet_to_hide = null
    for bullet in $BulletCountFrame/Bullets.get_children():
        if bullet.visible:
            bullet_to_hide = bullet
    if bullet_to_hide != null:
        bullet_to_hide.hide()


func subtract_live_round() -> void:
    var bullet_to_show = null
    for bullet in $BulletCountFrame/Bullets.get_children():
        if not bullet.visible:
            bullet_to_show = bullet
            break
    if bullet_to_show != null:
        bullet_to_show.show()
