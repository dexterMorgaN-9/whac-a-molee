extends Node

@onready var settingsbtn = $UI/TopBar/TopBarHBox/SettingsButton
@onready var infobtn = $UI/TopBar/TopBarHBox/InfoButton
@onready var startbtn = $UI/CenterLayout/ButtonCard/CardMargin/CardVBox/StartButton
@onready var exitbtn = $UI/CenterLayout/ButtonCard/CardMargin/CardVBox/ExitButton

@onready var dimoverlay = $UI/DimOverlay
@onready var fadeoverlay = $UI/FadeOverlay
@onready var settingsPanel = $UI/SettingsPanel
@onready var closebtn = $UI/SettingsPanel/VBox/TopRow/CloseButton
@onready var infopanel = $UI/InfoPanel
@onready var infoCloseBtn = $UI/InfoPanel/VBox/TopRow/InfoCloseButton

@onready var masterslider = $UI/SettingsPanel/VBox/SoundSection/MasterRow/MasterSlider
@onready var musicslider = $UI/SettingsPanel/VBox/SoundSection/MusicRow/MusicSlider
@onready var musictoggle = $UI/SettingsPanel/VBox/SoundSection/MusicRow/MusicToggle
@onready var sfxSlider = $UI/SettingsPanel/VBox/SoundSection/SFXRow/SFXSlider
@onready var sfxtoggle = $UI/SettingsPanel/VBox/SoundSection/SFXRow/SFXToggle
@onready var hitslider = $UI/SettingsPanel/VBox/SoundSection/HitRow/HitSlider
@onready var gameOverSlider = $UI/SettingsPanel/VBox/SoundSection/GameOverRow/GameOverSlider

@onready var musicplayer = $AudioPlayers/AudioStreamPlayer
@onready var sfxplayer = $AudioPlayers/AudioStreamPlayer2
@onready var hitplayer = $AudioPlayers/AudioStreamPlayer3
@onready var gameoverplayer = $AudioPlayers/AudioStreamPlayer4
@onready var decorTimer = $DecorSpawnTimer
@onready var decorholes = $DecorHoles

const GAME_SCENE = "res://main.tscn"
const SAVE_PATH := 'user://settings.cfg'
const FADE_TIME = 0.4
const MIN_VOL = 0.0001 # avoid -inf db

func _ready():
	loadsettings()
	hooksignals()
	fadein()
	decorTimer.start()


func hooksignals():
	startbtn.pressed.connect(onstart)
	exitbtn.pressed.connect(onexit)
	settingsbtn.pressed.connect(onsettingsbtn)
	infobtn.pressed.connect(oninfobtn)
	closebtn.pressed.connect(closesettings)
	infoCloseBtn.pressed.connect(closeinfo)
	dimoverlay.gui_input.connect(ondimclick)
	masterslider.value_changed.connect(onmastervol)
	musicslider.value_changed.connect(onmusicvol)
	sfxSlider.value_changed.connect(onsfxvol)
	hitslider.value_changed.connect(onhitvol)
	gameOverSlider.value_changed.connect(ongameovervol)
	musictoggle.toggled.connect(onmusictoggle)
	sfxtoggle.toggled.connect(onsfxtoggle)
	decorTimer.timeout.connect(ondecortick)

func fadein():
	fadeoverlay.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(fadeoverlay, "modulate:a", 0.0, FADE_TIME)

func fadeoutthen(cb):
	fadeoverlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(fadeoverlay, "modulate:a", 1.0, FADE_TIME)
	tw.tween_callback(cb)


func onstart():
	startbtn.disabled = true
	fadeoutthen(func(): get_tree().change_scene_to_file(GAME_SCENE))

func onexit():
	fadeoutthen(func():
		get_tree().quit()
	)

func onsettingsbtn():
	dimoverlay.visible = true
	settingsPanel.visible = true
func oninfobtn():
	dimoverlay.visible = true
	infopanel.visible = true

func closesettings():
	settingsPanel.visible = false
	dimoverlay.visible = false
	savesettings()

func closeinfo():
	infopanel.visible = false
	dimoverlay.visible = false


func ondimclick(e):
	if e is InputEventMouseButton and e.pressed:
		if settingsPanel.visible:
			closesettings()
		if infopanel.visible:
			closeinfo()

func onmastervol(v):
	var busIdx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(busIdx, linear_to_db(max(v, MIN_VOL)))

func onmusicvol(val: float):
	var idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(val, MIN_VOL)))

func onsfxvol(v):
	var i = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(i, linear_to_db(max(v, MIN_VOL)))
func onhitvol(v):
	hitplayer.volume_db = linear_to_db(max(v, MIN_VOL))

func ongameovervol(v):
	gameoverplayer.volume_db = linear_to_db(max(v, MIN_VOL))


func onmusictoggle(on):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), not on)
	musicslider.editable = on

func onsfxtoggle(isOn):
	AudioServer.set_bus_mute(AudioServer.get_bus_index('SFX'), !isOn)
	sfxSlider.editable = isOn


func savesettings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master", masterslider.value)
	cfg.set_value("audio", "music", musicslider.value)
	cfg.set_value("audio", "sfx", sfxSlider.value)
	cfg.set_value("audio", "hit", hitslider.value)
	cfg.set_value("audio", "game_over", gameOverSlider.value)
	cfg.set_value("audio", "music_on", musictoggle.button_pressed)
	cfg.set_value("audio", "sfx_on", sfxtoggle.button_pressed)
	cfg.save(SAVE_PATH)

func loadsettings():
	var cfg = ConfigFile.new()
	var loadOk = cfg.load(SAVE_PATH)
	if loadOk != OK:
		masterslider.value = 1.0
		musicslider.value = 0.8
		sfxSlider.value = 1.0
		hitslider.value = 1.0
		gameOverSlider.value = 1.0
		musictoggle.button_pressed = true
		sfxtoggle.button_pressed = true
		return

	masterslider.value = cfg.get_value("audio", "master", 1.0)
	musicslider.value = cfg.get_value("audio", "music", 0.8)
	sfxSlider.value = cfg.get_value("audio", "sfx", 1.0)
	hitslider.value = cfg.get_value("audio", "hit", 1.0)
	gameOverSlider.value = cfg.get_value('audio', 'game_over', 1.0)
	musictoggle.button_pressed = cfg.get_value("audio", "music_on", true)
	sfxtoggle.button_pressed = cfg.get_value("audio", "sfx_on", true)

	# reapply so audio bus actually reflects loaded values
	onmastervol(masterslider.value)
	onmusicvol(musicslider.value)
	onsfxvol(sfxSlider.value)
	onhitvol(hitslider.value)
	ongameovervol(gameOverSlider.value)
	onmusictoggle(musictoggle.button_pressed)
	onsfxtoggle(sfxtoggle.button_pressed)

func ondecortick():
	var holes = decorholes.get_children()
	if holes.size() == 0:
		return
	var randIdx = randi() % holes.size()
	var h = holes[randIdx]
	if h.has_method("pop_up"):
		h.pop_up()
