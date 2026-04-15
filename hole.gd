extends Node2D

signal bunny_hit
signal bunny_missed
@onready var bunny_sprite = $BunnyArea/BunnySprite
@onready var bunny_area = $BunnyArea
@onready var hide_timer = $HideTimer

var is_active = false

func _ready():
	bunny_area.input_event.connect(_on_bunny_clicked)
	hide_timer.timeout.connect(_on_hide_timer_timeout)

	bunny_sprite.visible = false
	is_active = false
func pop_up():
	if is_active:
		return 
	
	bunny_sprite.visible = true
	is_active = true
	hide_timer.start()  


func hide_bunny():
	bunny_sprite.visible = false
	is_active = false
	hide_timer.stop()
func _on_bunny_clicked(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if is_active:
			bunny_hit.emit()  
			hide_bunny()
func _on_hide_timer_timeout():
	if is_active:
		bunny_missed.emit() 
		hide_bunny()
