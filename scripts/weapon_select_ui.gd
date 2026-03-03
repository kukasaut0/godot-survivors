extends CanvasLayer
class_name WeaponSelectUI

signal item_chosen(item)

@onready var _options_container: VBoxContainer = $Panel/VBox/OptionsContainer

func show_options(options: Array) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	var first_btn: Button = null
	for item in options:
		var btn := Button.new()
		var prefix: String
		if item is EvolutionOffer:
			prefix = "[EVOLVE]"
		elif item.is_acquired():
			prefix = "[LVL %d]" % (item.level + 1)
		else:
			prefix = "[LVL 1]"
		btn.text = "%s %s — %s" % [prefix, item.weapon_name, item.get_next_upgrade_description()]
		btn.pressed.connect(_on_option_pressed.bind(item))
		_options_container.add_child(btn)
		if first_btn == null:
			first_btn = btn
	visible = true
	if first_btn:
		first_btn.grab_focus()

func _on_option_pressed(item) -> void:
	visible = false
	item_chosen.emit(item)
