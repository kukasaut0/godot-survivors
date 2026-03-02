extends Control

signal closed

var _souls_label: Label
var _pip_labels: Dictionary = {}
var _buy_buttons: Dictionary = {}

func _ready() -> void:
	# Dark overlay panel
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.85)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)

	# Centered content
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "META SHOP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_souls_label = Label.new()
	_souls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_souls_label.modulate = Color(1, 0.85, 0, 1)
	vbox.add_child(_souls_label)

	for id in GameState.UPGRADE_IDS:
		vbox.add_child(_make_row(id))

	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_on_close)
	vbox.add_child(close_btn)

	_wire_focus(close_btn)
	close_btn.grab_focus()

	_refresh()

func _wire_focus(close_btn: Button) -> void:
	var buttons: Array[Button] = []
	for id in GameState.UPGRADE_IDS:
		buttons.append(_buy_buttons[id])
	buttons.append(close_btn)
	var n := buttons.size()
	for i in n:
		var btn := buttons[i]
		btn.focus_neighbor_top = buttons[(i - 1 + n) % n].get_path()
		btn.focus_neighbor_bottom = buttons[(i + 1) % n].get_path()
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()

func _make_row(id: String) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(220, 0)
	var name_lbl := Label.new()
	name_lbl.text = GameState.UPGRADE_NAMES[id]
	var desc_lbl := Label.new()
	desc_lbl.text = GameState.UPGRADE_DESCS[id]
	desc_lbl.add_theme_font_size_override("font_size", 10)
	desc_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
	info.add_child(name_lbl)
	info.add_child(desc_lbl)
	hbox.add_child(info)

	var pip_lbl := Label.new()
	pip_lbl.custom_minimum_size = Vector2(80, 0)
	_pip_labels[id] = pip_lbl
	hbox.add_child(pip_lbl)

	var buy_btn := Button.new()
	buy_btn.custom_minimum_size = Vector2(110, 0)
	buy_btn.pressed.connect(_on_buy.bind(id))
	_buy_buttons[id] = buy_btn
	hbox.add_child(buy_btn)

	return hbox

func _refresh() -> void:
	_souls_label.text = "Souls: %d" % GameState.get_souls()
	for id in GameState.UPGRADE_IDS:
		var tier := GameState.get_upgrade_level(id)
		var pips := ""
		for i in GameState.UPGRADE_MAX_TIER:
			pips += "[*]" if i < tier else "[ ]"
		_pip_labels[id].text = pips

		var cost := GameState.get_upgrade_cost(id)
		var btn: Button = _buy_buttons[id]
		if cost == -1:
			btn.text = "MAXED"
			btn.disabled = true
		else:
			btn.text = "Buy (%d)" % cost
			btn.disabled = GameState.get_souls() < cost

func _on_buy(id: String) -> void:
	var cost := GameState.get_upgrade_cost(id)
	if cost == -1:
		return
	if GameState.spend_souls(cost):
		GameState.set_upgrade_level(id, GameState.get_upgrade_level(id) + 1)
		_refresh()

func _on_close() -> void:
	emit_signal("closed")
