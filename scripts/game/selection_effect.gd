class_name SelectionEffect
extends Node2D

const ANIMATION_NAME := &"selected"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	sprite.play(ANIMATION_NAME)
