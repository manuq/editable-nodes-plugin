extends CharacterBody2D


var walk_speed := 300.0
var stopping_step := 1500.0
var moving_step := 4000.0

var target_velocity: Vector2


func _unhandled_input(_event: InputEvent) -> void:
	var axis := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	target_velocity = axis * walk_speed


func _physics_process(delta: float) -> void:
	var step := (
		stopping_step
		if velocity.length_squared() > target_velocity.length_squared()
		else moving_step
	)
	velocity = velocity.move_toward(target_velocity, step * delta)
	move_and_slide()
