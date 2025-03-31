class_name ObjectManager
extends RigidBody3D

@export var health = 10000

# When bullets collide with the object.
@rpc("any_peer")
func take_damage(amount: int, pt, nrml):
	# Moving the obj
	self.apply_impulse(-nrml * 5.0 / self.mass, pt - self.global_position)
	health -= amount
	print(health)
	if health <= 0:
		self.queue_free()
