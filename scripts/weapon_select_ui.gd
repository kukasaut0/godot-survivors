extends CanvasLayer
class_name WeaponSelectUI

signal weapon_chosen(weapon: WeaponBase)

@onready var _options_container: VBoxContainer = $Panel/VBox/OptionsContainer

func show_options(options: Array) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	var first_btn: Button = null
	for weapon in options:
		var btn := Button.new()
		var prefix := "[LVL %d]" % weapon.level if weapon.is_acquired() else "[NEW]"
		btn.text = "%s %s — %s" % [prefix, weapon.weapon_name, weapon.get_next_upgrade_description()]
		btn.pressed.connect(_on_option_pressed.bind(weapon))
		_options_container.add_child(btn)
		if first_btn == null:
			first_btn = btn
	visible = true
	if first_btn:
		first_btn.grab_focus()

func _on_option_pressed(weapon: WeaponBase) -> void:
	visible = false
	weapon_chosen.emit(weapon)
