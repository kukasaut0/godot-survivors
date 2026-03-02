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

func _ready() -> void:
	game_over_panel.visible = false
	boss_warning_label.visible = false
	restart_button.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene())
	char_select_button.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/character_select.tscn"))

func update_hud(player: CharacterBody2D, time_elapsed: float, kills: int = 0) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = player.xp
	level_label.text = "LVL %d" % player.level
	time_label.text = "  %02d:%02d" % [int(time_elapsed) / 60, int(time_elapsed) % 60]
	kill_label.text = "  K:%d" % kills

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
