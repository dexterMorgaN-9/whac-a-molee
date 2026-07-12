extends Node2D

signal hit
signal miss
signal gone

@onready var spr = $BunnyArea/BunnySprite
@onready var area = $BunnyArea
@onready var htimer = $HideTimer

var active = false
var tw: Tween = null

const SCL = Vector2(0.067, 0.067)
const YHIDE = 55.0
const YSHOW = 6.0

func popup(dur: float = 0.45):
	if active:
		return
	active = true
	spr.visible = true
	spr.position.y = YHIDE
	spr.scale = Vector2(SCL.x * 0.85, SCL.y * 0.25)
	htimer.wait_time = dur
	htimer.start()

	if tw:
		tw.kill()
	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, 'position:y', YSHOW, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(spr, 'scale', SCL, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func whack():
	if tw:
		tw.kill()
	spr.modulate = Color(1.5, 0.5, 0.5)
	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, 'scale', Vector2(SCL.x * 1.4, SCL.y * 0.5), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tw.finished
	spr.modulate = Color(1, 1, 1)
	godown()

func godown():
	active = false
	htimer.stop()
	if tw:
		tw.kill()

	tw = create_tween().set_parallel(true)
	tw.tween_property(spr, 'position:y', YHIDE, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(spr, 'scale', Vector2(SCL.x * 0.85, SCL.y * 0.2), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	spr.visible = false
	spr.scale = SCL
	spr.position.y = YHIDE
	gone.emit()

func onclick(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if active:
			hit.emit()
			whack()
func ontimeout():
	if active:
		miss.emit()
		godown()

func _ready():
	area.input_event.connect(onclick)
	htimer.timeout.connect(ontimeout)
	spr.visible = false
	spr.scale = SCL
	spr.position.y = YHIDE
	active = false
