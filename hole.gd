extends Node2D

signal bunny_hit
signal bunny_missed
signal bunny_hidden

@onready var spr    = $BunnyArea/BunnySprite
@onready var area   = $BunnyArea
@onready var htimer = $HideTimer

var is_active = false
var tw: Tween = null
var _popped = 0

const SCL   = Vector2(0.067, 0.067)
const YHIDE = 55.0
const YSHOW = 6.0
const SQ_IN  = Vector2(SCL.x * 0.85, SCL.y * 0.25)
const SQ_OUT = Vector2(SCL.x * 0.85, SCL.y * 0.2)
const SQ_HIT = Vector2(SCL.x * 1.4,  SCL.y * 0.5)

func _ready():
	area.input_event.connect(onclick)
	htimer.timeout.connect(ontimeout)
	spr.visible = false
	spr.scale = SCL
	spr.position.y = YHIDE
	is_active = false

func onclick(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active:
			bunny_hit.emit()
			whack()

func ontimeout():
	if is_active:
		bunny_missed.emit()
		hide_bunny()

func pop_up(dur: float = 0.45):
	if is_active:
		return
	is_active = true
	_popped += 1
	spr.visible = true
	spr.modulate = Color(1, 1, 1)
	spr.position.y = YHIDE
	spr.scale = SQ_IN
	htimer.wait_time = dur
	htimer.start()
	if tw:
		tw.kill()
	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, "position:y", YSHOW, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, 'scale', SCL, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func whack():
	if tw:
		tw.kill()
	spr.modulate = Color(1.5, 0.5, 0.5)
	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, "scale", SQ_HIT, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	spr.modulate = Color(1, 1, 1)
	hide_bunny()

func hide_bunny():
	is_active = false
	htimer.stop()
	if tw:
		tw.kill()
	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, 'position:y', YHIDE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, "scale", SQ_OUT, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	spr.visible = false
	spr.scale = SCL
	spr.position.y = YHIDE
	bunny_hidden.emit()
