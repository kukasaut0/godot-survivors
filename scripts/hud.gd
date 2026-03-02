extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var xp_bar: ProgressBar = $Panel/VBox/XPBar
@onready var level_label: Label = $Panel/VBox/InfoRow/LevelLabel
@onready var time_label: Label = $Panel/VBox/InfoRow/TimeLabel
@onready var kill_label: Label = $Panel/VBox/InfoRow/KillLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var result_label: Label = $GameOverPanel/VBox/ResultLabel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var char_select_button: Button = $GameOverPanel/VBox/CharSelectButton
@onready var boss_warning_label: Label = $BossWarningLabel

var _stage_label: Label
var _dps_label: Label
var _combo_label: Label
var _surge_label: Label

func _ready() -> void:
	game_over_panel.visible = false
	boss_warning_label.visible = false
	restart_button.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	char_select_button.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/character_select.tscn"))

	# Stage name label (top-right area)
	_stage_label = Label.new()
	_stage_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stage_label.add_theme_font_size_override("font_size", 12)
	_stage_label.modulate = Color(0.7, 0.7, 0.7, 0.8)
	_stage_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stage_label.offset_left = -200
	_stage_label.offset_top = 8
	_stage_label.offset_right = -8
	add_child(_stage_label)

	# DPS label
	_dps_label = Label.new()
	_dps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_dps_label.add_theme_font_size_override("font_size", 11)
	_dps_label.modulate = Color(1, 0.6, 0.3, 0.8)
	_dps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_dps_label.offset_left = -200
	_dps_label.offset_top = 26
	_dps_label.offset_right = -8
	add_child(_dps_label)

	# Combo label (center screen)
	_combo_label = Label.new()
	_combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_label.add_theme_font_size_override("font_size", 28)
	_combo_label.modulate = Color(1, 1, 0, 1)
	_combo_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_combo_label.offset_top = 80
	_combo_label.offset_left = -150
	_combo_label.offset_right = 150
	_combo_label.visible = false
	add_child(_combo_label)

	# Surge warning label
	_surge_label = Label.new()
	_surge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_surge_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_surge_label.add_theme_font_size_override("font_size", 24)
	_surge_label.modulate = Color(1, 0.3, 0.3, 1)
	_surge_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_surge_label.offset_top = 50
	_surge_label.offset_left = -200
	_surge_label.offset_right = 200
	_surge_label.visible = false
	_surge_label.text = "INCOMING SURGE!"
	add_child(_surge_label)

func update_hud(player: CharacterBody2D, time_elapsed: float, kills: int = 0, damage: float = 0.0, stage_name: String = "") -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = player.xp
	level_label.text = "LVL %d" % player.level
	time_label.text = "  %02d:%02d" % [int(time_elapsed) / 60, int(time_elapsed) % 60]
	kill_label.text = "  K:%d" % kills
	if _stage_label != null:
		_stage_label.text = stage_name
	if _dps_label != null and time_elapsed > 0.0:
		_dps_label.text = "DPS: %d" % int(damage / time_elapsed)

func show_game_over(time_elapsed: float, level_reached: int, kills: int = 0, damage: float = 0.0, weapon_names: Array = [], souls_earned: int = 0) -> void:
	game_over_panel.visible = true
	var weapons_str := ", ".join(weapon_names) if not weapon_names.is_empty() else "None"
	result_label.text = "GAME OVER\nTime: %02d:%02d\nLevel: %d\nKills: %d\nDamage: %d\nWeapons: %s\nSouls Earned: %d" % [
		int(time_elapsed) / 60, int(time_elapsed) % 60,
		level_reached, kills, int(damage), weapons_str, souls_earned
	]
	char_select_button.text = "Cash Out Souls"
	restart_button.grab_focus()

func show_victory(time_elapsed: float, level_reached: int, kills: int = 0, damage: float = 0.0, weapon_names: Array = [], souls_earned: int = 0) -> void:
	game_over_panel.visible = true
	var weapons_str := ", ".join(weapon_names) if not weapon_names.is_empty() else "None"
	result_label.text = "VICTORY!\nTime: %02d:%02d\nLevel: %d\nKills: %d\nDamage: %d\nWeapons: %s\nSouls Earned: %d" % [
		int(time_elapsed) / 60, int(time_elapsed) % 60,
		level_reached, kills, int(damage), weapons_str, souls_earned
	]
	restart_button.text = "Play Again"
	char_select_button.text = "Cash Out Souls"
	char_select_button.grab_focus()

func show_boss_warning() -> void:
	boss_warning_label.visible = true
	get_tree().create_timer(3.0).timeout.connect(func() -> void:
		if is_instance_valid(boss_warning_label):
			boss_warning_label.visible = false)

func show_surge_warning() -> void:
	if _surge_label != null:
		_surge_label.visible = true
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(_surge_label):
				_surge_label.visible = false)

func show_combo(count: int, text: String) -> void:
	if _combo_label != null:
		_combo_label.text = text
		_combo_label.visible = true

func hide_combo() -> void:
	if _combo_label != null:
		_combo_label.visible = false
