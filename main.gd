extends Node2D

var score   = 0
var streak  = 0
var tleft   = 60.0
var running = false
var lastsec = -1

@onready var scorelbl   = $UI/ScoreLabel
@onready var timerlbl   = $UI/TimerLabel
@onready var streaklbl  = $UI/StreakLabel
@onready var gtimer     = $GameTimer
@onready var overpanel  = $UI/GameOverPanel
@onready var overdim    = $UI/GameOverDim
@onready var finallbl   = $UI/GameOverPanel/MarginContainer/VBox/FinalScoreLabel
@onready var restartbtn = $UI/GameOverPanel/MarginContainer/VBox/ButtonRow/RestartButton
@onready var homebtn    = $UI/GameOverPanel/MarginContainer/VBox/ButtonRow/HomeButton

@onready var musicplayer    = $AudioPlayers/Music
@onready var hitplayer      = $AudioPlayers/Hit
@onready var missplayer     = $AudioPlayers/Miss
@onready var gameoverplayer = $AudioPlayers/GameOver
@onready var cdplayer       = $AudioPlayers/Countdown
@onready var streakplayer   = $AudioPlayers/Streak
@onready var sfxplayer      = $AudioPlayers/Click

const SND_MUSIC    = preload("res://sounds/bg loop.mp3")
const SND_HIT      = preload("res://sounds/Hit Sound.mp3")
const SND_MISS     = preload("res://sounds/bunny escape.mp3")
const SND_GAMEOVER = preload("res://sounds/game over.mp3")
const SND_CD       = preload("res://sounds/countdown go!.mp3")
const SND_STREAK   = preload("res://sounds/streak 5x!.mp3")
const SND_CLICK    = preload("res://sounds/UI click.mp3")

var holes = []

func difflvl() -> int:
	return int(score / 10)
func visdur() -> float:
	var lvl = difflvl()
	var dur = randf_range(0.35, 0.45) - lvl * 0.02
	return clamp(dur, 0.35, 0.7)

func spawndelay() -> float:
	var lvl = difflvl()
	var mind = clamp(0.15 - lvl * 0.005, 0.08, 0.15)
	var maxd = clamp(0.35 - lvl * 0.01,  0.15, 0.35)
	return randf_range(mind, maxd)

func refreshui():
	scorelbl.text = "SCORE: " + str(score)
	timerlbl.text = "Time: " + str(int(ceil(tleft)))
	if streak >= 5:
		streaklbl.text = "STREAK! " + str(streak) + "x 🔥"
		streaklbl.modulate = Color(1.0, 0.4, 0.0)
	else:
		streaklbl.text = 'Streak: ' + str(streak) + "x"
		streaklbl.modulate = Color(1.0, 1.0, 0.0)

func punchscore():
	var tw = create_tween()
	tw.tween_property(scorelbl, "scale", Vector2(1.3, 1.3), 0.08)
	tw.tween_property(scorelbl, "scale", Vector2(1.0, 1.0), 0.1)

func onhit():
	streak += 1
	var pts = 10 if streak >= 5 else 3
	score += pts
	refreshui()
	punchscore()
	hitplayer.stream = SND_HIT
	hitplayer.play()
	if streak == 5:
		streakplayer.stream = SND_STREAK
		streakplayer.play()

func onmiss():
	streak = 0
	refreshui()
	var tw = create_tween()
	var x0 = scorelbl.position.x
	tw.tween_property(scorelbl, "position:x", x0 + 8, 0.05)
	tw.tween_property(scorelbl, "position:x", x0 - 8, 0.05)
	tw.tween_property(scorelbl, "position:x", x0, 0.05)
	missplayer.stream = SND_MISS
	missplayer.play()

func countdown():
	cdplayer.stream = SND_CD
	cdplayer.play()
	for i in [3, 2, 1]:
		streaklbl.text = str(i) + "..."
		streaklbl.scale = Vector2(1.5, 1.5)
		var tw = create_tween()
		tw.tween_property(streaklbl, "scale", Vector2(1.0, 1.0), 0.4)
		await get_tree().create_timer(1.0).timeout
	streaklbl.text = "GO!"
	streaklbl.scale = Vector2(2.0, 2.0)
	var tw2 = create_tween()
	tw2.tween_property(streaklbl, "scale", Vector2(1.0, 1.0), 0.3)
	await get_tree().create_timer(0.6).timeout
	streaklbl.text = "Streak: 0x"

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

func ontimeout():
	running = false
	tleft = 0
	for h in holes:
		if h.is_active:
			h.hide_bunny()
	musicplayer.stop()
	gameoverplayer.stream = SND_GAMEOVER
	gameoverplayer.play()
	await get_tree().create_timer(0.5).timeout
	finallbl.text = "Final Score: " + str(score)
	overdim.visible    = true
	overpanel.visible  = true

func restart():
	sfxplayer.stream = SND_CLICK
	sfxplayer.play()
	get_tree().reload_current_scene()

func gohome():
	sfxplayer.stream = SND_CLICK
	sfxplayer.play()
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

	gtimer.timeout.connect(ontimeout)
	restartbtn.pressed.connect(restart)
	homebtn.pressed.connect(gohome)

	tleft = 60.0
	overpanel.visible = false
	overdim.visible   = false
	refreshui()

	musicplayer.stream = SND_MUSIC
	musicplayer.play()

	await countdown()

	running = true
	gtimer.start(60.0)
	spawnloop()

func _process(_delta):
	if not running:
		return
	if gtimer.time_left <= 0:
		return
	tleft = gtimer.time_left
	var secleft = int(ceil(tleft))
	if secleft != lastsec:
		timerlbl.text = "Time: " + str(secleft)
		lastsec = secleft
	if tleft <= 10:
		timerlbl.modulate = Color(1.0, 0.2, 0.2) if int(tleft * 2) % 2 == 0 else Color(1, 1, 1)
	else:
		timerlbl.modulate = Color(1.0, 0.85, 0.0)
