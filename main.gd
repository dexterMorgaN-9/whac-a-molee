extends Node2D

var score = 0
var high_score = 0
var streak = 0
var time_left = 60


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
		var hole = $HoleGrid.get_node("Hole" + str(i))
		holes.append(hole)
		# Connect signals from each hole
		hole.bunny_hit.connect(_on_bunny_hit)
		hole.bunny_missed.connect(_on_bunny_missed)
	
	print(" DEBUG: Found ", holes.size(), " holes")  
	
	game_timer.timeout.connect(_on_game_timer_timeout)
	bunny_spawn_timer.timeout.connect(_spawn_random_bunny)
	restart_button.pressed.connect(_restart_game)
	
	high_score = _load_high_score()
	
	time_left = 60  
	_update_ui()
	game_over_panel.visible = false
	
	print(" DEBUG: Game ready! Starting timers...")  

func _process(_delta):
	time_left = int(game_timer.time_left)
	timer_label.text = "Time: " + str(time_left)
func _spawn_random_bunny():
	print(" DEBUG: Spawn timer triggered!")
	
	if time_left <= 0:
		return
	
	var available_holes = []
	for hole in holes:
		if not hole.is_active:
			available_holes.append(hole)
	
	print(" DEBUG: Available holes: ", available_holes.size())  
	
	if available_holes.size() > 0:
		var random_hole = available_holes[randi() % available_holes.size()]
		print(" DEBUG: Spawning bunny!") 
		random_hole.pop_up()
func _on_bunny_hit():
	streak += 1
	var points = 3
	if streak >= 5:
		points = 8 
	
	score += points
	_update_ui()


func _on_bunny_missed():
	streak = 0  
	_update_ui()

func _update_ui():
	score_label.text = "Score: " + str(score)
	high_score_label.text = "High Score: " + str(high_score)
	
	if streak >= 5:
		streak_label.text = "STREAK BONUS! " + str(streak) + "x"
	else:
		streak_label.text = "Streak: " + str(streak) + "x"

func _on_game_timer_timeout():
	bunny_spawn_timer.stop()
	
	if score > high_score:
		high_score = score
		_save_high_score(high_score)
	
	game_over_panel.visible = true
	final_score_label.text = "Final Score: " + str(score) + "\nHigh Score: " + str(high_score)

func _restart_game():
	get_tree().reload_current_scene()

func _save_high_score(hs):
	var save_file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	save_file.store_var(hs)
	save_file.close()


func _load_high_score():
	if not FileAccess.file_exists("user://highscore.save"):
		return 0
	
	var save_file = FileAccess.open("user://highscore.save", FileAccess.READ)
	var hs = save_file.get_var()
	save_file.close()
	return hs
