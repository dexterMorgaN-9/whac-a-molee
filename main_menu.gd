extends Node

@onready var settingsbtn  = $UI/TopBar/TopBarHBox/SettingsButton
@onready var infobtn      = $UI/TopBar/TopBarHBox/InfoButton
@onready var startbtn     = $UI/CenterLayout/ButtonCard/CardMargin/CardVBox/StartButton
@onready var exitbtn      = $UI/CenterLayout/ButtonCard/CardMargin/CardVBox/ExitButton

@onready var dimoverlay   = $UI/DimOverlay
@onready var fadeoverlay  = $UI/FadeOverlay
@onready var settingspanel = $UI/SettingsPanel
@onready var closebtn     = $UI/SettingsPanel/VBox/TopRow/CloseButton
@onready var infopanel    = $UI/InfoPanel
@onready var infoclosebtn = $UI/InfoPanel/VBox/TopRow/InfoCloseButton

@onready var masterslider   = $UI/SettingsPanel/VBox/SoundSection/MasterRow/MasterSlider
@onready var musicslider    = $UI/SettingsPanel/VBox/SoundSection/MusicRow/MusicSlider
@onready var musictoggle    = $UI/SettingsPanel/VBox/SoundSection/MusicRow/MusicToggle
@onready var sfxslider      = $UI/SettingsPanel/VBox/SoundSection/SFXRow/SFXSlider
@onready var sfxtoggle      = $UI/SettingsPanel/VBox/SoundSection/SFXRow/SFXToggle
@onready var hitslider      = $UI/SettingsPanel/VBox/SoundSection/HitRow/HitSlider
@onready var gameoverslider = $UI/SettingsPanel/VBox/SoundSection/GameOverRow/GameOverSlider

@onready var musicplayer    = $AudioPlayers/Music
@onready var hitplayer      = $AudioPlayers/Hit
@onready var missplayer     = $AudioPlayers/Miss
@onready var gameoverplayer = $AudioPlayers/GameOver
@onready var cdplayer       = $AudioPlayers/Countdown
@onready var streakplayer   = $AudioPlayers/Streak
@onready var sfxplayer      = $AudioPlayers/Click
@onready var decortimer     = $DecorSpawnTimer
@onready var decorholes     = $DecorHoles

const GAME_SCENE = "res://main.tscn"
const SAVE_PATH  := 'user://settings.cfg'
const FADE_TIME  = 0.4
const MIN_VOL    = 0.0001

const SND_MUSIC    = preload("res://sounds/bg loop.mp3")
const SND_HIT      = preload("res://sounds/Hit Sound.mp3")
const SND_MISS     = preload("res://sounds/bunny escape.mp3")
const SND_GAMEOVER = preload("res://sounds/game over.mp3")
const SND_CD       = preload("res://sounds/countdown go!.mp3")
const SND_STREAK   = preload("res://sounds/streak 5x!.mp3")
const SND_CLICK    = preload("res://sounds/UI click.mp3")

var _settings_open = false

func _ready():
	loadsettings()
	_hook()
	fadein()
	decortimer.start()
	musicplayer.stream = SND_MUSIC
	if musicplayer.stream is AudioStreamMP3 or musicplayer.stream is AudioStreamOggVorbis:
		musicplayer.stream.loop = true
	musicplayer.play()

func _hook():
	startbtn.pressed.connect(onstart)
	exitbtn.pressed.connect(onexit)
	settingsbtn.pressed.connect(onsettingsbtn)
	infobtn.pressed.connect(oninfobtn)
	closebtn.pressed.connect(closesettings)
	infoclosebtn.pressed.connect(closeinfo)
	dimoverlay.gui_input.connect(ondimclick)
	masterslider.value_changed.connect(onmastervol)
	musicslider.value_changed.connect(onmusicvol)
	sfxslider.value_changed.connect(onsfxvol)
	hitslider.value_changed.connect(onhitvol)
	gameoverslider.value_changed.connect(ongameovervol)
	musictoggle.toggled.connect(onmusictoggle)
	sfxtoggle.toggled.connect(onsfxtoggle)
	decortimer.timeout.connect(ondecortick)

func playclick():
	sfxplayer.stream = SND_CLICK
	sfxplayer.play()

func fadein():
	fadeoverlay.modulate.a = 1.0
	var tw = create_tween()
	tw.tween_property(fadeoverlay, "modulate:a", 0.0, FADE_TIME)

func fadeoutthen(cb):
	fadeoverlay.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(fadeoverlay, 'modulate:a', 1.0, FADE_TIME)
	tw.tween_callback(cb)

func onstart():
	playclick()
	startbtn.disabled = true
	fadeoutthen(func(): get_tree().change_scene_to_file(GAME_SCENE))

func onexit():
	playclick()
	fadeoutthen(func():
		get_tree().quit()
	)

func onsettingsbtn():
	playclick()
	dimoverlay.visible   = true
	settingspanel.visible = true
	_settings_open = true
func oninfobtn():
	playclick()
	dimoverlay.visible = true
	infopanel.visible  = true

func closesettings():
	playclick()
	settingspanel.visible = false
	dimoverlay.visible   = false
	_settings_open = false
	savesettings()

func closeinfo():
	playclick()
	infopanel.visible  = false
	dimoverlay.visible = false

func ondimclick(e):
	if e is InputEventMouseButton and e.pressed:
		if settingspanel.visible:
			closesettings()
		if infopanel.visible:
			closeinfo()

func onmastervol(v):
	var busidx = AudioServer.get_bus_index("Master")
	if busidx == -1:
		return
	AudioServer.set_bus_volume_db(busidx, linear_to_db(max(v, MIN_VOL)))

func onmusicvol(val: float):
	var idx = AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(max(val, MIN_VOL)))

func onsfxvol(v):
	var i = AudioServer.get_bus_index("SFX")
	if i == -1: return
	AudioServer.set_bus_volume_db(i, linear_to_db(max(v, MIN_VOL)))

func onhitvol(v):
	hitplayer.volume_db = linear_to_db(max(v, MIN_VOL))

func ongameovervol(v):
	gameoverplayer.volume_db = linear_to_db(max(v, MIN_VOL))

func onmusictoggle(on):
	var idx = AudioServer.get_bus_index("Music")
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, not on)
	musicslider.editable = on

func onsfxtoggle(ison):
	var idx = AudioServer.get_bus_index("SFX")
	if idx == -1:
		return
	AudioServer.set_bus_mute(idx, !ison)
	sfxslider.editable = ison

func savesettings():
	var cfg = ConfigFile.new()
	cfg.set_value("audio", "master",   masterslider.value)
	cfg.set_value("audio", "music",    musicslider.value)
	cfg.set_value("audio", "sfx",      sfxslider.value)
	cfg.set_value("audio", "hit",      hitslider.value)
	cfg.set_value("audio", "game_over", gameoverslider.value)
	cfg.set_value("audio", "music_on", musictoggle.button_pressed)
	cfg.set_value("audio", "sfx_on",   sfxtoggle.button_pressed)
	cfg.save(SAVE_PATH)

func loadsettings():
	var cfg = ConfigFile.new()
	var loadok = cfg.load(SAVE_PATH)
	if loadok != OK:
		masterslider.value   = 1.0
		musicslider.value    = 0.8
		sfxslider.value      = 1.0
		hitslider.value      = 1.0
		gameoverslider.value = 1.0
		musictoggle.button_pressed = true
		sfxtoggle.button_pressed   = true
		return

	masterslider.value   = cfg.get_value("audio", "master",   1.0)
	musicslider.value    = cfg.get_value("audio", "music",    0.8)
	sfxslider.value      = cfg.get_value("audio", "sfx",      1.0)
	hitslider.value      = cfg.get_value("audio", "hit",      1.0)
	gameoverslider.value = cfg.get_value('audio', 'game_over', 1.0)
	musictoggle.button_pressed = cfg.get_value("audio", "music_on", true)
	sfxtoggle.button_pressed   = cfg.get_value("audio", "sfx_on",   true)

	onmastervol(masterslider.value)
	onmusicvol(musicslider.value)
	onsfxvol(sfxslider.value)
	onhitvol(hitslider.value)
	ongameovervol(gameoverslider.value)
	onmusictoggle(musictoggle.button_pressed)
	onsfxtoggle(sfxtoggle.button_pressed)

func ondecortick():
	var holes = decorholes.get_children()
	if holes.size() == 0:
		return
	var idx = randi() % holes.size()
	var h = holes[idx]
	if h.has_method("pop_up"):
		h.pop_up()
