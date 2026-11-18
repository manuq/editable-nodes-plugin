extends AnimatedSprite2D

@onready var player: CharacterBody2D = get_parent()


func _process(_delta: float) -> void:
	if player.velocity.is_zero_approx():
		play("idle")
	else:
		play("walk")
		if not is_zero_approx(player.velocity.x):
			flip_h = player.velocity.x < 0
