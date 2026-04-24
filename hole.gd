extends Node2D

signal bunny_hit
signal bunny_missed

@onready var bunny_sprite = $BunnyArea/BunnySprite
@onready var bunny_area = $BunnyArea
@onready var hide_timer = $HideTimer

var is_active = false
var _tween: Tween = null

func _ready():
	bunny_area.input_event.connect(_on_bunny_clicked)
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	bunny_sprite.visible = false
	bunny_sprite.position.y = 60  # start below hole
	bunny_sprite.scale = Vector2(1.0, 1.0)
	is_active = false


func pop_up():
	if is_active:
		return

	is_active = true
	bunny_sprite.visible = true
	bunny_sprite.scale = Vector2(0.8, 0.3)   # squished flat to start (like coming from underground)
	bunny_sprite.position.y = 60             # below the hole center

	hide_timer.wait_time = randf_range(1.5, 2.8)
	hide_timer.start()

	# Kill any existing tween
	if _tween:
		_tween.kill()

	# Rise up with bounce overshoot
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(bunny_sprite, "position:y", -10.0, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(bunny_sprite, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func hide_bunny():
	is_active = false
	hide_timer.stop()

	if _tween:
		_tween.kill()

	# Squish down back into the hole
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(bunny_sprite, "position:y", 60.0, 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(bunny_sprite, "scale", Vector2(0.8, 0.2), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await _tween.finished
	bunny_sprite.visible = false
	bunny_sprite.scale = Vector2(1.0, 1.0)
	bunny_sprite.position.y = 60


func _whack_effect():
	# Satisfying squish punch on click before hiding
	if _tween:
		_tween.kill()

	bunny_sprite.modulate = Color(1.5, 0.5, 0.5)  # red flash
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(bunny_sprite, "scale", Vector2(1.4, 0.5), 0.07)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _tween.finished
	bunny_sprite.modulate = Color(1, 1, 1)
	hide_bunny()


func _on_bunny_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active:
			bunny_hit.emit()
			_whack_effect()


func _on_hide_timer_timeout():
	if is_active:
		bunny_missed.emit()
		hide_bunny()
