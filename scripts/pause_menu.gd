extends CanvasLayer

signal cash_out_requested

func _ready() -> void:
	visible = false
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/RestartButton.pressed.connect(_on_restart)
	$Panel/VBox/CashOutButton.pressed.connect(_on_cash_out)

func show_menu() -> void:
	visible = true
	$Panel/VBox/ResumeButton.grab_focus()

func hide_menu() -> void:
	visible = false

func _on_resume() -> void:
	visible = false
	get_tree().paused = false

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_cash_out() -> void:
	emit_signal("cash_out_requested")
