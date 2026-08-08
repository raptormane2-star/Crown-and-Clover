class_name PlayerCharacter
extends CharacterBody2D

signal interact_requested
signal attack_requested

@export var movement_speed: float = 142.0

var facing_vector: Vector2 = Vector2.DOWN
var facing_name: String = "down"
var animation_time: float = 0.0
var attack_time: float = 0.0
var movement_enabled: bool = true

func _physics_process(delta: float) -> void:
    animation_time += delta
    attack_time = maxf(0.0, attack_time - delta)
    if not movement_enabled:
        velocity = Vector2.ZERO
        return
    var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
    if input_vector.length() > 0.1:
        facing_vector = input_vector.normalized()
        if absf(facing_vector.x) > absf(facing_vector.y):
            facing_name = "side"
        else:
            facing_name = "down" if facing_vector.y > 0.0 else "up"
    velocity = input_vector.normalized() * movement_speed
    move_and_slide()
    if Input.is_action_just_pressed("interact"):
        interact_requested.emit()
    if Input.is_action_just_pressed("attack"):
        attack_time = 0.18
        attack_requested.emit()
