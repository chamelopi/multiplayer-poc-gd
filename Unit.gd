extends CharacterBody3D


const SPEED = 100.0
var moving = false
var direction: Vector2
var moved = 0.0

# Workaround for https://github.com/godotengine/godot/issues/68516:
# Due to a bug we can only synchronize exported properties
@export var my_velocity := Vector3(0., 0., 0.):
	set(velo):
		velocity = velo  # to set mine
		my_velocity = velo  # to set theirs

# This runs on both the server and the client. Because the server owns the units, it has 
# authority and its position & velocity will be synced to the units.
# This combination results in smooth movement, which is also correct as per the authority.
func _process(delta):
	if not moving:
		var rand_angle = randf() * PI * 2
		direction = Vector2(sin(rand_angle), cos(rand_angle)).normalized()
		moving = true
	else:
		velocity.x = direction.x * SPEED * delta
		velocity.z = direction.y * SPEED * delta
		
		moved += delta
		
		if moved >= 2.0:
			moving = false
			moved = 0.0
			velocity = Vector3(0, 0, 0)
				
	move_and_slide()
