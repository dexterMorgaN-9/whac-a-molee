extends Node2D

var score = 0
var high_score = 0
var streak = 0
var time_left = 60.0
var _last_spawn_interval = 1.0
var _speed_phase = 2

@onready var score_label = $UI/ScoreLabel
@onready var high_score_label = $UI/HighScoreLabel
@onready var timer_label = $UI/TimerLabel
@onready var streak_label = $UI/StreakLabel
@onready var game_timer = $GameTimer
@onready var bunny_spawn_timer = $BunnySpawnTimer
@onready var game_over_panel = $UI/GameOverPanel
@onready var final_score_label = $UI/GameOverPanel/FinalScoreLabel
@onready var restart_button = $UI/GameOverPanel/RestartButton

const MAX_ACTIVE_BUNNIES = 1

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
				push_warning("Hole script missing on: " + hole_name)
		else:
			push_warning("Node not found: " + hole_name)
	game_timer.timeout.connect(_on_game_timer_timeout)
	bunny_spawn_timer.timeout.connect(_spawn_random_bunny)
	restart_button.pressed.connect(_restart_game)
	high_score = _load_high_score()
	time_left = 60.0
	_last_spawn_interval = 1.0
	_speed_phase = 0
	game_over_panel.visible = false
	_update_ui()
	game_timer.start(60.0)
	bunny_spawn_timer.wait_time = 1.0
	bunny_spawn_timer.one_shot = false
	bunny_spawn_timer.start()

func _process(_delta):
	if game_timer.time_left > 0:
		time_left = game_timer.time_left
		timer_label.text = "Time: " + str(int(ceil(time_left)))
		_update_spawn_speed()

func _update_spawn_speed():
	var new_phase: int
	if time_left < 15.0:
		new_phase = 2
	elif time_left < 30.0:
		new_phase = 1
	else:
		new_phase = 0

	if new_phase != _speed_phase:
		_speed_phase = new_phase
		var intervals = [1.0, 0.75, 0.5]
		_last_spawn_interval = intervals[new_phase]
		bunny_spawn_timer.stop()
		bunny_spawn_timer.wait_time = _last_spawn_interval
		bunny_spawn_timer.start()

func _spawn_random_bunny():
	if time_left <= 0:
		return

	# Hard cap — never go over MAX_ACTIVE_BUNNIES
	var active_count = holes.filter(func(h): return h.is_active).size()
	if active_count >= MAX_ACTIVE_BUNNIES:
		return

	var available_holes = holes.filter(func(h): return not h.is_active)
	if available_holes.size() == 0:
		return

	var random_hole = available_holes[randi() % available_holes.size()]
	random_hole.pop_up()

func _on_bunny_hit():
	streak += 1
	var points = 10 if streak >= 5 else 3
	score += points
	if score > high_score:
		high_score = score
	_update_ui()

func _on_bunny_missed():
	streak = 0
	_update_ui()

func _update_ui():
	score_label.text = "SCORE: " + str(score)
	high_score_label.text = "High Score: " + str(high_score)
	timer_label.text = "Time: " + str(int(ceil(time_left)))
	if streak >= 5:
		streak_label.text = "STREAK! " + str(streak) + "x"
		streak_label.modulate = Color(1.0, 0.4, 0.0)
	else:
		streak_label.text = "Streak: " + str(streak) + "x"
		streak_label.modulate = Color(1.0, 1.0, 0.0)

func _on_game_timer_timeout():
	time_left = 0
	bunny_spawn_timer.stop()
	for hole in holes:
		hole.hide_bunny()
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	game_over_panel.visible = true
	final_score_label.text = "Final Score: " + str(score) + "\nHigh Score: " + str(high_score)

func _restart_game():
	get_tree().reload_current_scene()

func _save_high_score(hs):
	var save_file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if save_file:
		save_file.store_var(hs)
		save_file.close()

func _load_high_score():
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	var save_file = FileAccess.open("user://highscore.save", FileAccess.READ)
	if save_file:
		var hs = save_file.get_var()
		save_file.close()
		return hs
	return 0
