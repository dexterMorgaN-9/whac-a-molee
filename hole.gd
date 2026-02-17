extends Node2D

# Signals to communicate with Main scene
signal bunny_hit
signal bunny_missed

# Node references
@onready var bunny_sprite = $BunnyArea/BunnySprite
@onready var bunny_area = $BunnyArea
@onready var hide_timer = $HideTimer

var is_active = false

func _ready():
	# Connect signals
	bunny_area.input_event.connect(_on_bunny_clicked)
	hide_timer.timeout.connect(_on_hide_timer_timeout)
	
	# Start with bunny hidden
	bunny_sprite.visible = false
	is_active = false

# Show the bunny
func pop_up():
	if is_active:
		return  # Already active, don't pop up again
	
	bunny_sprite.visible = true
	is_active = true
	hide_timer.start()  # Start 0.9 second timer

# Hide the bunny
func hide_bunny():
	bunny_sprite.visible = false
	is_active = false
	hide_timer.stop()

# When bunny is clicked
func _on_bunny_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active:
			bunny_hit.emit()  # Tell Main we hit the bunny
			hide_bunny()

# When timer runs out (bunny wasn't hit in time)
func _on_hide_timer_timeout():
	if is_active:
		bunny_missed.emit()  # Tell Main we missed
		hide_bunny()
