extends Node2D

var score = 0
var streak = 0
var tleft = 60.0
var running = false
var lastSec = -1

@onready var scoreLbl = $UI/ScoreLabel
@onready var timerLbl = $UI/TimerLabel
@onready var streakLbl = $UI/StreakLabel
@onready var gTimer = $GameTimer
@onready var overPanel = $UI/GameOverPanel
@onready var overDim = $UI/GameOverDim
@onready var finalLbl = $UI/GameOverPanel/MarginContainer/VBox/FinalScoreLabel
@onready var restartBtn = $UI/GameOverPanel/MarginContainer/VBox/ButtonRow/RestartButton
@onready var homeBtn = $UI/GameOverPanel/MarginContainer/VBox/ButtonRow/HomeButton

var holes = []
func difflvl() -> int:
	return int(score / 10)

func visdur() -> float:
	var lvl = difflvl()
	var dur = randf_range(0.35, 0.45) - lvl * 0.02
	return clamp(dur, 0.35, 0.7)

func spawndelay() -> float:
	var lvl = difflvl()
	var minD = clamp(0.15 - lvl * 0.005, 0.08, 0.15)
	var maxD = clamp(0.35 - lvl * 0.01, 0.15, 0.35)
	return randf_range(minD, maxD)


func punchscore():
	var tw = create_tween()
	tw.tween_property(scoreLbl, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(scoreLbl, "scale", Vector2(1.0, 1.0), 0.1)


func onhit():
	streak += 1
	var pts = 10 if streak >= 5 else 3
	score += pts
	refreshui()
	punchscore()

func onmiss():
	streak = 0
	refreshui()
	var tw = create_tween()
	var x0 = scoreLbl.position.x
	tw.tween_property(scoreLbl, "position:x", x0 + 8, 0.05)
	tw.tween_property(scoreLbl, "position:x", x0 - 8, 0.05)
	tw.tween_property(scoreLbl, "position:x", x0, 0.05)

func refreshui():
	scoreLbl.text = "SCORE: " + str(score)
	timerLbl.text = "Time: " + str(int(ceil(tleft)))
	if streak >= 5:
		streakLbl.text = "STREAK! " + str(streak) + "x 🔥"
		streakLbl.modulate = Color(1.0, 0.4, 0.0)
	else:
		streakLbl.text = 'Streak: ' + str(streak) + "x"
		streakLbl.modulate = Color(1.0, 1.0, 0.0)


func spawnloop() -> void:
	while running:
		var hole = holes[randi() % holes.size()]
		if hole.is_active:
			await get_tree().process_frame
			continue
		hole.pop_up(visdur())
		await hole.bunny_hidden
		if not running:
			break
		await get_tree().create_timer(spawndelay()).timeout

func countdown():
	for i in [1]:
		streakLbl.text = str(i) + "..."
		streakLbl.scale = Vector2(1.5, 1.5)
		var tw = create_tween()
		tw.tween_property(streakLbl, "scale", Vector2(1.0, 1.0), 0.4)
		await get_tree().create_timer(1.0).timeout
	streakLbl.text = "GO!"
	streakLbl.scale = Vector2(2.0, 2.0)
	var tw2 = create_tween()
	tw2.tween_property(streakLbl, "scale", Vector2(1.0, 1.0), 0.3)
	await get_tree().create_timer(0.6).timeout
	streakLbl.text = "Streak: 0x"

func ontimeout():
	running = false
	tleft = 0
	for h in holes:
		if h.is_active:
			h.hide_bunny()
	await get_tree().create_timer(0.5).timeout
	finalLbl.text = "Final Score: " + str(score)
	overDim.visible = true
	overPanel.visible = true

func restart():
	get_tree().reload_current_scene()

func gohome():
	get_tree().change_scene_to_file("res://main_menu.tscn")

func _ready():
	for i in range(1, 10):
		var hname = "Hole" + str(i)
		if not $HoleGrid.has_node(hname):
			continue
		var h = $HoleGrid.get_node(hname)
		if not h.has_signal("bunny_hit"):
			continue
		holes.append(h)
		h.bunny_hit.connect(onhit)
		h.bunny_missed.connect(onmiss)

	gTimer.timeout.connect(ontimeout)
	restartBtn.pressed.connect(restart)
	homeBtn.pressed.connect(gohome)

	tleft = 60.0
	overPanel.visible = false
	overDim.visible = false
	refreshui()

	await countdown()

	running = true
	gTimer.start(60.0)
	spawnloop()


func _process(_delta):
	if not running:
		return
	if gTimer.time_left <= 0:
		return
	tleft = gTimer.time_left
	var secLeft = int(ceil(tleft))
	if secLeft != lastSec:
		timerLbl.text = "Time: " + str(secLeft)
		lastSec = secLeft
	if tleft <= 10:
		timerLbl.modulate = Color(1.0, 0.2, 0.2) if int(tleft * 2) % 2 == 0 else Color(1, 1, 1)
	else:
		timerLbl.modulate = Color(1.0, 0.85, 0.0)
