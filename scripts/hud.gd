extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var xp_bar: ProgressBar = $Panel/VBox/XPBar
@onready var level_label: Label = $Panel/VBox/InfoRow/LevelLabel
@onready var time_label: Label = $Panel/VBox/InfoRow/TimeLabel
@onready var kill_label: Label = $Panel/VBox/InfoRow/KillLabel
@onready var _weapons_label: Label = $Panel/VBox/WeaponsLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var result_label: Label = $GameOverPanel/VBox/ResultLabel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton
@onready var char_select_button: Button = $GameOverPanel/VBox/CharSelectButton
@onready var boss_warning_label: Label = $BossWarningLabel

var _stage_label: Label
var _dps_label: Label
var _combo_label: Label
var _surge_label: Label
var _review_vbox: VBoxContainer

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

	# Review container inserted between result_label and buttons
	_review_vbox = VBoxContainer.new()
	_review_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	$GameOverPanel/VBox.add_child(_review_vbox)
	$GameOverPanel/VBox.move_child(_review_vbox, 1)

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
	if _weapons_label != null:
		var parts: Array[String] = []
		if "weapons" in player:
			for w in player.weapons:
				parts.append("%s Lv%d" % [w.weapon_name, w.level])
		if "passives" in player:
			for p in player.passives:
				if p.is_acquired():
					parts.append("%s Lv%d" % [p.weapon_name, p.level])
		_weapons_label.text = "  |  ".join(parts)

func show_game_over(time_elapsed: float, player, kills: int = 0, damage: float = 0.0, souls_earned: int = 0) -> void:
	game_over_panel.visible = true
	result_label.text = "GAME OVER"
	result_label.modulate = Color(1.0, 0.35, 0.35, 1.0)
	_build_review(player, time_elapsed, kills, damage, souls_earned)
	char_select_button.text = "Cash Out Souls"
	restart_button.grab_focus()

func show_victory(time_elapsed: float, player, kills: int = 0, damage: float = 0.0, souls_earned: int = 0) -> void:
	game_over_panel.visible = true
	result_label.text = "VICTORY!"
	result_label.modulate = Color(0.35, 1.0, 0.5, 1.0)
	_build_review(player, time_elapsed, kills, damage, souls_earned)
	restart_button.text = "Play Again"
	char_select_button.text = "Cash Out Souls"
	char_select_button.grab_focus()

func _build_review(player, time_elapsed: float, kills: int, damage: float, souls: int) -> void:
	for child in _review_vbox.get_children():
		_review_vbox.remove_child(child)
		child.queue_free()

	_add_sep()

	_add_stat("Time",    "%02d:%02d" % [int(time_elapsed) / 60, int(time_elapsed) % 60])
	_add_stat("Level",   str(player.level))
	_add_stat("Kills",   str(kills))
	_add_stat("Damage",  "%d" % int(damage))
	if time_elapsed > 0.0:
		_add_stat("Avg DPS", "%d" % int(damage / time_elapsed))

	if not player.weapons.is_empty():
		_add_sep()
		_add_section("WEAPONS")
		for w in player.weapons:
			_add_item(w.weapon_name, "Lv.%d" % w.level, Color(1.0, 0.85, 0.4, 1.0))

	var acquired: Array = player.passives.filter(func(p) -> bool: return p.is_acquired())
	if not acquired.is_empty():
		_add_sep()
		_add_section("PASSIVES")
		for p in acquired:
			_add_item(p.weapon_name, "Lv.%d" % p.level, Color(0.6, 0.9, 1.0, 1.0))

	_add_sep()
	var souls_lbl := Label.new()
	souls_lbl.text = "Souls Earned: +%d" % souls
	souls_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	souls_lbl.modulate = Color(0.65, 0.65, 1.0, 1.0)
	souls_lbl.add_theme_font_size_override("font_size", 14)
	_review_vbox.add_child(souls_lbl)

func _add_sep() -> void:
	_review_vbox.add_child(HSeparator.new())

func _add_section(text: String) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.modulate = Color(0.75, 0.75, 0.75, 1.0)
	lbl.add_theme_font_size_override("font_size", 12)
	_review_vbox.add_child(lbl)

func _add_stat(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(lbl)
	row.add_child(val)
	_review_vbox.add_child(row)

func _add_item(name_text: String, level_text: String, level_color: Color) -> void:
	var row := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = "  " + name_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lvl := Label.new()
	lvl.text = level_text
	lvl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	lvl.modulate = level_color
	row.add_child(lbl)
	row.add_child(lvl)
	_review_vbox.add_child(row)

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
