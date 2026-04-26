extends Node2D
@onready var btn_start = $UI/CenterContainer/VBox/StartButton
@onready var btn_exit = $UI/CenterContainer/VBox/ExitButton
@onready var btn_info = $UI/BottomRight/InfoButton
@onready var btn_cfg = $UI/BottomRight/SettingsButton
@onready var cfg_panel = $UI/SettingsPanel
@onready var btn_close = $UI/SettingsPanel/VBox/TopRow/CloseButton
@onready var lang_opt = $UI/SettingsPanel/VBox/LanguageSection/LanguageOption
@onready var sld_mus = $UI/SettingsPanel/VBox/SoundSection/MusicRow/MusicSlider
@onready var sld_sfx = $UI/SettingsPanel/VBox/SoundSection/SFXRow/SFXSlider
@onready var sld_hit = $UI/SettingsPanel/VBox/SoundSection/HitRow/HitSlider
@onready var sld_go = $UI/SettingsPanel/VBox/SoundSection/GameOverRow/GameOverSlider
@onready var aud_mus = $AudioPlayers/AudioStreamPlayer
@onready var aud_sfx = $AudioPlayers/AudioStreamPlayer2
@onready var aud_hit = $AudioPlayers/AudioStreamPlayer3
@onready var aud_go = $AudioPlayers/AudioStreamPlayer4
@onready var ttl = $UI/TitleLabel
const SCENE_GAME = "res://main.tscn"
const URL_INFO = "https://github.com/YOUR_USERNAME/YOUR_REPO#readme"
const CFG_PATH = "user://settings.cfg"
const LANGS = [
	["English", "eng"],
	["हिन्दी", "hin"],
	["Español", "espn"],
	["Français", "frn"],
	["日本語", "jap"],
]
var cfg = {
	"lang": "en",
	"vol_mus": 0.8,
	"vol_sfx": 1.0,
	"vol_hit": 1.0,
	"vol_go": 1.0,
}
func _ready():
	_load_cfg()
	_apply_cfg()
	_setup()
	_ttl_anim()
	btn_start.pressed.connect(_start)
	btn_exit.pressed.connect(_quit)
	btn_info.pressed.connect(_info)
	btn_cfg.pressed.connect(_cfg_open)
	btn_close.pressed.connect(_cfg_close)
	lang_opt.item_selected.connect(_lang_chg)
	sld_mus.value_changed.connect(_vol_mus)
	sld_sfx.value_changed.connect(_vol_sfx)
	sld_hit.value_changed.connect(_vol_hit)
	sld_go.value_changed.connect(_vol_go)
	cfg_panel.visible = false
func _cfg_open():
	_btn_pop(btn_cfg)
	cfg_panel.visible = true
	cfg_panel.scale = Vector2(0.7, 0.7)
	cfg_panel.modulate.a = 0.0
	var t = create_tween().set_parallel(true)
	t.tween_property(cfg_panel, "scale", Vector2(1.0, 1.0), 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(cfg_panel, "modulate:a", 1.0, 0.15)
func _start():
	_btn_pop(btn_start)
	await get_tree().create_timer(0.15).timeout
	get_tree().change_scene_to_file(SCENE_GAME)
func _load_cfg():
	var f = ConfigFile.new()
	if f.load(CFG_PATH) != OK:
		return
	cfg["lang"]    = f.get_value("s", "lang",    "en")
	cfg["vol_mus"] = f.get_value("s", "vol_mus", 0.8)
	cfg["vol_sfx"] = f.get_value("s", "vol_sfx", 1.0)
	cfg["vol_hit"] = f.get_value("s", "vol_hit", 1.0)
	cfg["vol_go"]  = f.get_value("s", "vol_go",  1.0)
func _vol_mus(v):
	cfg["vol_mus"] = v
	aud_mus.volume_db = linear_to_db(v)
func _cfg_close():
	var t = create_tween().set_parallel(true)
	t.tween_property(cfg_panel, "scale", Vector2(0.7, 0.7), 0.15)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(cfg_panel, "modulate:a", 0.0, 0.15)
	await t.finished
	cfg_panel.visible = false
	_save_cfg()
func _setup():
	lang_opt.clear()
	var idx = 0
	for i in LANGS.size():
		lang_opt.add_item(LANGS[i][0])
		if LANGS[i][1] == cfg["lang"]:
			idx = i
	lang_opt.selected = idx
	sld_mus.value = cfg["vol_mus"]
	sld_sfx.value = cfg["vol_sfx"]
	sld_hit.value = cfg["vol_hit"]
	sld_go.value  = cfg["vol_go"]
func _quit():
	_btn_pop(btn_exit)
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
func _vol_sfx(v):
	cfg["vol_sfx"] = v
	aud_sfx.volume_db = linear_to_db(v)
func _ttl_anim():
	ttl.scale = Vector2(0.3, 0.3)
	ttl.modulate.a = 0.0
	var t = create_tween()
	t.tween_property(ttl, "scale", Vector2(1.05, 1.05), 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(ttl, "modulate:a", 1.0, 0.3)
	t.tween_property(ttl, "scale", Vector2(1.0, 1.0), 0.15)
	await t.finished
	_ttl_wobble()
func _save_cfg():
	var f = ConfigFile.new()
	f.set_value("s", "lang",    cfg["lang"])
	f.set_value("s", "vol_mus", cfg["vol_mus"])
	f.set_value("s", "vol_sfx", cfg["vol_sfx"])
	f.set_value("s", "vol_hit", cfg["vol_hit"])
	f.set_value("s", "vol_go",  cfg["vol_go"])
	f.save(CFG_PATH)
func _lang_chg(idx):
	cfg["lang"] = LANGS[idx][1]
	TranslationServer.set_locale(cfg["lang"])
func _info():
	_btn_pop(btn_info)
	OS.shell_open(URL_INFO)
func _vol_hit(v):
	cfg["vol_hit"] = v
	aud_hit.volume_db = linear_to_db(v)
func _apply_cfg():
	TranslationServer.set_locale(cfg["lang"])
	aud_mus.volume_db = linear_to_db(cfg["vol_mus"])
	aud_sfx.volume_db = linear_to_db(cfg["vol_sfx"])
	aud_hit.volume_db = linear_to_db(cfg["vol_hit"])
	aud_go.volume_db  = linear_to_db(cfg["vol_go"])
func _ttl_wobble():
	var t = create_tween().set_loops()
	t.tween_property(ttl, "rotation_degrees",  1.5, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(ttl, "rotation_degrees", -1.5, 1.2)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
func _vol_go(v):
	cfg["vol_go"] = v
	aud_go.volume_db = linear_to_db(v)
func _btn_pop(btn: Button):
	var t = create_tween()
	t.tween_property(btn, "scale", Vector2(0.88, 0.88), 0.07)
	t.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
