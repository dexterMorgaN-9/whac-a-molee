extends Node2D

@onready var score_label: Label = $UI/ScoreLabel
@onready var high_score_label: Label = $UI/HighScoreLabel
@onready var timer_label: Label = $UI/TimerLabel
@onready var streak_label: Label = $UI/StreakLabel
@onready var game_over_panel = $UI/GameOverPanel
@onready var final_score_label: Label = $UI/GameOverPanel/FinalScoreLabel
@onready var restart_button: Button = $UI/GameOverPanel/RestartButton
@onready var game_timer: Timer = $GameTimer
@onready var bunny_spawn_timer: Timer = $BunnySpawnTimer
@onready var hole_grid: Node2D = $HoleGrid

# Effects nodes — add these to your scene!
@onready var camera: Camera2D = $Camera2D
@onready var flash_rect: ColorRect = $UI/FlashRect  # ColorRect, full rect, in CanvasLayer

var score := 0
var high_score := 0
var streak := 0
var _holes := []
var _last_spawn_interval := 2.0
var _game_running := false

func _ready():
	# Collect all hole nodes
	for child in hole_grid.get_children():
		if child is Node2D:
			_holes.append(child)
			child.bunny_hit.connect(_on_bunny_hit.bind(child))
			child.bunny_missed.connect(_on_bunny_missed)

	# Load high score
	_load_high_score()
	high_score_label.text = "High Score: " + str(high_score)

	# Setup flash rect
	flash_rect.visible = false
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 0, 0, 0)

	# Hide game over panel
	game_over_panel.visible = false

	# Start game
	_start_game()

func _start_game():
	score = 0
	streak = 0
	_game_running = true
	_last_spawn_interval = 2.0

	score_label.text = "SCORE: 0"
	streak_label.text = "Streak: 0x"
	streak_label.add_theme_color_override("font_color", Color.WHITE)
	game_over_panel.visible = false

	game_timer.wait_time = 60.0
	game_timer.start()

	bunny_spawn_timer.wait_time = _last_spawn_interval
	bunny_spawn_timer.start()

func _process(_delta):
	if _game_running:
		timer_label.text = "Time: " + str(int(game_timer.time_left))
		_update_spawn_speed()

func _update_spawn_speed():
	var time_left = game_timer.time_left

	if time_left <= 15.0 and _last_spawn_interval != 0.6:
		_last_spawn_interval = 0.6
		bunny_spawn_timer.wait_time = _last_spawn_interval

	elif time_left <= 30.0 and _last_spawn_interval != 1.0 and time_left > 15.0:
		_last_spawn_interval = 1.0
		bunny_spawn_timer.wait_time = _last_spawn_interval

func _spawn_random_bunny():
	var inactive_holes = _holes.filter(func(h): return not h._active)
	if inactive_holes.is_empty():
		return

	inactive_holes.shuffle()
	inactive_holes[0].pop_up()

	# Double spawn in last 15 seconds
	if game_timer.time_left <= 15.0 and inactive_holes.size() > 1:
		inactive_holes[1].pop_up()

func _on_bunny_spawn_timer_timeout():
	if _game_running:
		_spawn_random_bunny()

func _on_bunny_hit(hole: Node2D):
	streak += 1
	var is_streak_bonus = streak >= 5
	var points = 10 if is_streak_bonus else 3
	score += points

	score_label.text = "SCORE: " + str(score)
	streak_label.text = "Streak: " + str(streak) + "x"

	if streak >= 5:
		streak_label.add_theme_color_override("font_color", Color.YELLOW)
		_pulse_streak_label()
	else:
		streak_label.add_theme_color_override("font_color", Color.WHITE)

	# Save high score
	if score > high_score:
		high_score = score
		high_score_label.text = "High Score: " + str(high_score)
		_save_high_score()

	# Fire effects
	if has_node("Effects"):
		Effects.hit(hole.bunny_sprite.global_position, points, is_streak_bonus)

func _on_bunny_missed():
	streak = 0
	streak_label.text = "Streak: 0x"
	streak_label.add_theme_color_override("font_color", Color.WHITE)

	# Miss effects
	_flash_screen()
	_shake_camera()

func _pulse_streak_label():
	var tween = create_tween()
	tween.tween_property(streak_label, "scale", Vector2(1.3, 1.3), 0.1) \
		.set_trans(Tween.TRANS_BACK)
	tween.tween_property(streak_label, "scale", Vector2(1.0, 1.0), 0.1)

func _flash_screen():
	flash_rect.color = Color(1, 0, 0, 0.3)
	flash_rect.visible = true
	var tween = create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.2)
	tween.tween_callback(func(): flash_rect.visible = false)

func _shake_camera():
	if not camera:
		return
	var origin = camera.offset
	var tween = create_tween()
	for _i in 6:
		tween.tween_property(camera, "offset", origin + Vector2(randf_range(-5, 5), randf_range(-4, 4)), 0.04)
	tween.tween_property(camera, "offset", origin, 0.04)

func _on_game_timer_timeout():
	_game_running = false
	bunny_spawn_timer.stop()

	# Hide all active bunnies
	for hole in _holes:
		if hole._active:
			hole.hide_bunny()

	game_over_panel.visible = true
	final_score_label.text = "Final Score: " + str(score)

func _on_restart_button_pressed():
	_start_game()

func _save_high_score():
	var file = FileAccess.open("user://highscore.save", FileAccess.WRITE)
	file.store_32(high_score)
	file.close()

func _load_high_score():
	if FileAccess.file_exists("user://highscore.save"):
		var file = FileAccess.open("user://highscore.save", FileAccess.READ)
		high_score = file.get_32()
		file.close()
