extends KinematicBody

class_name AbstractTank


export(float) var move_speed = 1.5  # m/s
export(float) var turn_speed = 0.8  # rad/s

var velocity = Vector3.ZERO
var ordnance_speed: float

# Network stuff
puppet var p_origin := Vector3.ZERO
puppet var p_basis := Basis.IDENTITY
puppet var p_velocity := Vector3.ZERO

# Body movement and rotation
var target_location: Vector3
var last_target_direction: Vector3
var target_rotation: Basis
var opposite_rotation: Basis
var rotation_lerp := 0.0


signal destroyed()


func _post_init() -> void:
    pass


func set_target_location(new_target: Vector3):
    target_location = new_target * 1000 + global_transform.origin
    rotation_lerp = 0


func rotate_body(delta, target_direction):
    target_rotation = transform.looking_at(target_location, Vector3.UP).basis
    var target_quat = target_rotation.get_rotation_quat()
    var angle_to_target = transform.basis.get_rotation_quat().angle_to(target_quat)
    opposite_rotation = target_rotation.rotated(Vector3.UP, PI)

    var opposite_quat = opposite_rotation.get_rotation_quat()
    var angle_to_opposite = transform.basis.get_rotation_quat().angle_to(opposite_quat)
    if angle_to_target > angle_to_opposite:
        target_rotation = opposite_rotation

    var facing_vector := -transform.basis.z.normalized()
    var opposing_vector := transform.basis.z.normalized()
    if facing_vector.dot(target_direction) < 1 and opposing_vector.dot(target_direction) < 1:
        if rotation_lerp < 1:
            rotation_lerp += delta * turn_speed
        elif rotation_lerp > 1:
            rotation_lerp = 1
        transform.basis = transform.basis.slerp(target_rotation, rotation_lerp).orthonormalized()

    return [facing_vector, opposing_vector]


remotesync func destroy():
    pass


remote func update_pvr(pos, vel, rot):
    p_origin = pos
    p_basis = rot
    p_velocity = vel
