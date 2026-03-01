extends CanvasLayer

@onready var health_bar: ProgressBar = $Panel/VBox/HealthBar
@onready var xp_bar: ProgressBar = $Panel/VBox/XPBar
@onready var level_label: Label = $Panel/VBox/InfoRow/LevelLabel
@onready var time_label: Label = $Panel/VBox/InfoRow/TimeLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var result_label: Label = $GameOverPanel/VBox/ResultLabel
@onready var restart_button: Button = $GameOverPanel/VBox/RestartButton

func _ready() -> void:
	game_over_panel.visible = false
	restart_button.pressed.connect(func(): get_tree().reload_current_scene())

func update_hud(player: CharacterBody2D, time_elapsed: float) -> void:
	health_bar.max_value = player.max_health
	health_bar.value = player.health
	xp_bar.max_value = player.xp_to_next
	xp_bar.value = player.xp
	level_label.text = "LVL %d" % player.level
	time_label.text = "  %02d:%02d" % [int(time_elapsed) / 60, int(time_elapsed) % 60]

func show_game_over(time_elapsed: float, level_reached: int) -> void:
	game_over_panel.visible = true
	result_label.text = "GAME OVER\nTime: %02d:%02d\nLevel: %d" % [
		int(time_elapsed) / 60, int(time_elapsed) % 60, level_reached
	]
	restart_button.grab_focus()
