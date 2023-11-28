extends CharacterBody3D


const SPEED = 100.0
var moving = false
var direction: Vector2
var moved = 0.0


func _process(delta):
	# Only need to run this on the server, it will get synced to the client automatically
	if multiplayer and multiplayer.get_unique_id() == 1:
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

