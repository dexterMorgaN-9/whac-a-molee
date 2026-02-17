extends Node2D

var score = 0
var high_score = 0
var streak = 0
var time_left = 60

# Node references
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
	# Get all hole instances
	for i in range(1, 10):
		var hole = $HoleGrid.get_node("Hole" + str(i))
		holes.append(hole)
		# Connect signals from each hole
		hole.bunny_hit.connect(_on_bunny_hit)
		hole.bunny_missed.connect(_on_bunny_missed)
	
	# Connect timers
	game_timer.timeout.connect(_on_game_timer_timeout)
	bunny_spawn_timer.timeout.connect(_spawn_random_bunny)
	restart_button.pressed.connect(_restart_game)
	
	# Load high score
	high_score = _load_high_score()
	
	# Initialize UI
	_update_ui()
	game_over_panel.visible = false

func _process(_delta):
	# Update timer display
	time_left = int(game_timer.time_left)
	timer_label.text = "Time: " + str(time_left)

# Spawn bunny at random hole
func _spawn_random_bunny():
	if time_left <= 0:
		return
	
	# Find holes that aren't active
	var available_holes = []
	for hole in holes:
		if not hole.is_active:
			available_holes.append(hole)
	
	# Pop up random bunny
	if available_holes.size() > 0:
		var random_hole = available_holes[randi() % available_holes.size()]
		random_hole.pop_up()

# When bunny is hit
func _on_bunny_hit():
	streak += 1
	
	# Base points + streak bonus
	var points = 3
	if streak >= 5:
		points = 8  # 3 base + 5 bonus
	
	score += points
	_update_ui()

# When bunny is missed
func _on_bunny_missed():
	streak = 0  # Reset streak
	_update_ui()

# Update all UI labels
func _update_ui():
	score_label.text = "Score: " + str(score)
	high_score_label.text = "High Score: " + str(high_score)
	
	# Show streak with bonus indicator
	if streak >= 5:
		streak_label.text = "STREAK BONUS! " + str(streak) + "x"
	else:
		streak_label.text = "Streak: " + str(streak) + "x"

# When 60 seconds are up
func _on_game_timer_timeout():
	bunny_spawn_timer.stop()
	
	# Update high score if needed
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	
	# Show game over
	game_over_panel.visible = true
	final_score_label.text = "Final Score: " + str(score) + "\nHigh Score: " + str(high_score)

# Restart the game
func _restart_game():
	get_tree().reload_current_scene()

# Save high score to file
func _save_high_score(hs):
	var save_file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	save_file.store_var(hs)
	save_file.close()

# Load high score from file
func _load_high_score():
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	
	var save_file = FileAccess.open("user://highscore.save", FileAccess.READ)
	var hs = save_file.get_var()
	save_file.close()
	return hs
