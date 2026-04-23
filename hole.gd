extends Node2D

signal bunny_hit
signal bunny_missed

@export var bunny_texture: Texture2D = preload("res://assets/1.png")

@onready var bunny_sprite: Sprite2D = $BunnyArea/BunnySprite
@onready var hide_timer: Timer = $HideTimer

var _active := false

func pop_up():
	_active = true
	bunny_sprite.texture = bunny_texture
	bunny_sprite.visible = true
	bunny_sprite.scale = Vector2(0.5, 0.5)

	var tween = create_tween()
	tween.tween_property(bunny_sprite, "scale", Vector2(1.0, 1.0), 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	hide_timer.wait_time = randf_range(1.5, 3.0)
	hide_timer.start()

func hide_bunny():
	_active = false
	hide_timer.stop()

	var tween = create_tween()
	tween.tween_property(bunny_sprite, "scale", Vector2(0.0, 0.0), 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): bunny_sprite.visible = false)

func _on_bunny_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and _active:
			_active = false
			bunny_hit.emit()
			hide_bunny()

func _on_hide_timer_timeout():
	if _active:
		bunny_missed.emit()
	hide_bunny()
