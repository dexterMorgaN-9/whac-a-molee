extends Node2D

var score = 0
var high_score = 0
var streak = 0
var time_left = 60.0
var _last_spawn_interval = 1.0
var _game_running = false

@onready var score_label = $UI/ScoreLabel
@onready var high_score_label = $UI/HighScoreLabel
@onready var timer_label = $UI/TimerLabel
@onready var streak_label = $UI/StreakLabel
@onready var game_timer = $GameTimer
@onready var bunny_spawn_timer = $BunnySpawnTimer
@onready var game_over_panel = $UI/GameOverPanel
@onready var final_score_label = $UI/GameOverPanel/FinalScoreLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton

var holes = []

func _ready():
	for i in range(1, 10):
		var hole_name = "Hole" + str(i)
		if $HoleGrid.has_node(hole_name):
			var hole = $HoleGrid.get_node(hole_name)
			if hole.has_signal("bunny_hit"):
				holes.append(hole)
				hole.bunny_hit.connect(_on_bunny_hit)
				hole.bunny_missed.connect(_on_bunny_missed)
			else:
				push_warning("No script on: " + hole_name)
		else:
			push_warning("Missing node: " + hole_name)

	print("Holes connected: ", holes.size())  # should print 9

	game_timer.timeout.connect(_on_game_timer_timeout)
	bunny_spawn_timer.timeout.connect(_spawn_random_bunny)
	restart_button.pressed.connect(_restart_game)

	high_score = _load_high_score()
	time_left = 60.0
	game_over_panel.visible = false
	_update_ui()

	# Countdown before game starts so player is ready
	await _start_countdown()

	_game_running = true
	game_timer.start(60.0)
	bunny_spawn_timer.wait_time = 1.0
	bunny_spawn_timer.start()


func _start_countdown():
	# Flash "3... 2... 1... GO!" on the streak label
	for i in [3, 2, 1]:
		streak_label.text = str(i) + "..."
		streak_label.scale = Vector2(1.5, 1.5)
		var t = create_tween()
		t.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.4)
		await get_tree().create_timer(1.0).timeout

	streak_label.text = "GO!"
	streak_label.scale = Vector2(2.0, 2.0)
	var t = create_tween()
	t.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.3)
	await get_tree().create_timer(0.6).timeout
	streak_label.text = "Streak: 0x"


func _process(_delta):
	if not _game_running:
		return
	if game_timer.time_left > 0:
		time_left = game_timer.time_left
		timer_label.text = "Time: " + str(int(ceil(time_left)))

		# Flash timer red in last 10 seconds
		if time_left <= 10:
			timer_label.modulate = Color(1.0, 0.2, 0.2) if int(time_left * 2) % 2 == 0 else Color(1, 1, 1)
		else:
			timer_label.modulate = Color(1.0, 0.85, 0.0)

		_update_spawn_speed()


func _update_spawn_speed():
	var new_interval: float
	if time_left < 15.0:
		new_interval = 0.5
	elif time_left < 30.0:
		new_interval = 0.75
	else:
		new_interval = 1.0

	if new_interval != _last_spawn_interval:
		_last_spawn_interval = new_interval
		bunny_spawn_timer.wait_time = new_interval


func _spawn_random_bunny():
	if not _game_running or time_left <= 0:
		return

	var available = holes.filter(func(h): return not h.is_active)
	if available.size() == 0:
		return

	var picked = available[randi() % available.size()]
	picked.pop_up()

	# Double spawn in last 15 seconds
	if time_left < 15.0 and available.size() > 1:
		available.erase(picked)
		available[randi() % available.size()].pop_up()


func _on_bunny_hit():
	streak += 1
	var points = 10 if streak >= 5 else 3
	score += points
	if score > high_score:
		high_score = score
	_update_ui()
	_punch_score_label()


func _on_bunny_missed():
	streak = 0
	_update_ui()
	# Shake score label on miss
	var t = create_tween()
	t.tween_property(score_label, "position:x", score_label.position.x + 8, 0.05)
	t.tween_property(score_label, "position:x", score_label.position.x - 8, 0.05)
	t.tween_property(score_label, "position:x", score_label.position.x, 0.05)


func _punch_score_label():
	var t = create_tween()
	t.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.08)
	t.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.1)


func _update_ui():
	score_label.text = "SCORE: " + str(score)
	high_score_label.text = "High Score: " + str(high_score)
	timer_label.text = "Time: " + str(int(ceil(time_left)))

	if streak >= 5:
		streak_label.text = "STREAK! " + str(streak) + "x 🔥"
		streak_label.modulate = Color(1.0, 0.4, 0.0)
	else:
		streak_label.text = "Streak: " + str(streak) + "x"
		streak_label.modulate = Color(1.0, 1.0, 0.0)


func _on_game_timer_timeout():
	_game_running = false
	time_left = 0
	bunny_spawn_timer.stop()

	for hole in holes:
		hole.hide_bunny()

	if score > high_score:
		high_score = score
		_save_high_score(high_score)

	await get_tree().create_timer(0.5).timeout
	game_over_panel.visible = true
	final_score_label.text = "Final Score: " + str(score) + "\nHigh Score: " + str(high_score)


func _restart_game():
	get_tree().reload_current_scene()


func _save_high_score(hs):
	var f = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if f:
		f.store_var(hs)
		f.close()


func _load_high_score():
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	var f = FileAccess.open("user://highscore.save", FileAccess.READ)
	if f:
		var hs = f.get_var()
		f.close()
		return hs
	return 0
