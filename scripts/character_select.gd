extends Control

const CHARACTER_FILES: Array[String] = [
	"res://data/characters/default.tres",
	"res://data/characters/speeder_hero.tres",
	"res://data/characters/tank_hero.tres",
	"res://data/characters/mage.tres",
]

const CHARACTER_UNLOCK_KEYS: Array[String] = [
	"",
	"char_speeder_hero",
	"char_tank_hero",
	"char_mage",
]

const CHARACTER_UNLOCK_HINTS: Array[String] = [
	"",
	"LOCKED\nKill 500 enemies\nin a single run",
	"LOCKED\nSurvive 10 minutes",
	"LOCKED\nReach level 20\nin a single run",
]

const LEVEL_FILES: Array[String] = [
	"res://data/levels/default.tres",
	"res://data/levels/crypt.tres",
	"res://data/levels/abyss.tres",
]

const LEVEL_UNLOCK_KEYS: Array[String] = [
	"",
	"stage_fields_clear",
	"stage_crypt_clear",
]

@onready var _grid: HBoxContainer = $VBox/CharacterGrid
@onready var _hint_label: Label = $VBox/HintLabel

var _select_buttons: Array[Button] = []
var _souls_label: Label
var _shop_button: Button
var _stage_panel: Control = null
var _selected_character_idx: int = -1

func _ready() -> void:
	_build_cards()

	var vbox := $VBox as VBoxContainer
	_souls_label = Label.new()
	_souls_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_souls_label.modulate = Color(1, 0.85, 0, 1)
	vbox.add_child(_souls_label)
	vbox.move_child(_souls_label, 1)
	_update_souls_label()

	_shop_button = Button.new()
	_shop_button.text = "Meta Shop"
	_shop_button.custom_minimum_size = Vector2(0, 64)
	_shop_button.add_theme_font_size_override("font_size", 20)
	_shop_button.pressed.connect(_open_shop)
	vbox.add_child(_shop_button)

	_wire_focus_neighbors()
	if _select_buttons.size() > 0:
		_select_buttons[0].grab_focus()

func _build_cards() -> void:
	for i in CHARACTER_FILES.size():
		var path: String = CHARACTER_FILES[i]
		var unlock_key: String = CHARACTER_UNLOCK_KEYS[i]
		var is_unlocked: bool = unlock_key.is_empty() or GameState.get_unlock(unlock_key, false)
		var data: CharacterData = load(path) as CharacterData
		if data == null:
			continue
		var card := _make_card(data, i, is_unlocked)
		_grid.add_child(card)

func _make_card(data: CharacterData, idx: int, is_unlocked: bool) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(200, 300)
	var vbox := VBoxContainer.new()
	card.add_child(vbox)
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)

	# Icon
	var icon := TextureRect.new()
	icon.texture = load("res://icon.svg")
	icon.custom_minimum_size = Vector2(80, 80)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.modulate = data.modulate_color if is_unlocked else Color(0.3, 0.3, 0.3, 1)
	vbox.add_child(icon)

	# Name
	var name_label := Label.new()
	name_label.text = data.display_name if is_unlocked else "???"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	if is_unlocked:
		var stats_label := Label.new()
		stats_label.text = "SPD: %d  HP: %d" % [int(data.speed), int(data.max_health)]
		stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(stats_label)

		var btn := Button.new()
		btn.text = "Select"
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 64)
		btn.add_theme_font_size_override("font_size", 20)
		btn.pressed.connect(_on_character_selected.bind(idx))
		vbox.add_child(btn)
		_select_buttons.append(btn)
	else:
		var locked_label := Label.new()
		locked_label.text = CHARACTER_UNLOCK_HINTS[idx]
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(locked_label)

	return card

func _wire_focus_neighbors() -> void:
	for i in _select_buttons.size():
		var btn := _select_buttons[i]
		var prev := _select_buttons[i - 1].get_path() if i > 0 else _select_buttons[-1].get_path()
		var next := _select_buttons[(i + 1) % _select_buttons.size()].get_path()
		btn.focus_neighbor_left = prev
		btn.focus_neighbor_right = next
		btn.focus_neighbor_top = _shop_button.get_path()
		btn.focus_neighbor_bottom = _shop_button.get_path()
	if _shop_button != null:
		var first := _select_buttons[0].get_path() if _select_buttons.size() > 0 else _shop_button.get_path()
		_shop_button.focus_neighbor_top = first
		_shop_button.focus_neighbor_bottom = first
		_shop_button.focus_neighbor_left = _shop_button.get_path()
		_shop_button.focus_neighbor_right = _shop_button.get_path()

func _update_souls_label() -> void:
	_souls_label.text = "Souls: %d" % GameState.get_souls()

func _open_shop() -> void:
	var shop = load("res://scripts/meta_shop.gd").new()
	shop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shop)
	shop.closed.connect(_close_shop.bind(shop))

func _close_shop(shop: Node) -> void:
	shop.queue_free()
	_update_souls_label()
	if _shop_button != null:
		_shop_button.grab_focus()

func _on_character_selected(idx: int) -> void:
	_selected_character_idx = idx
	_show_stage_select()

func _show_stage_select() -> void:
	if _stage_panel != null:
		_stage_panel.queue_free()

	_stage_panel = Panel.new()
	_stage_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	_stage_panel.add_theme_stylebox_override("panel", style)
	add_child(_stage_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_stage_panel.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "SELECT STAGE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	var stage_buttons: Array[Button] = []

	for i in LEVEL_FILES.size():
		var level_data: LevelData = load(LEVEL_FILES[i]) as LevelData
		if level_data == null:
			continue
		var unlock_key: String = LEVEL_UNLOCK_KEYS[i]
		var is_unlocked: bool = unlock_key.is_empty() or GameState.get_unlock(unlock_key, false)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		vbox.add_child(hbox)

		var info := VBoxContainer.new()
		info.custom_minimum_size = Vector2(250, 0)
		var name_lbl := Label.new()
		name_lbl.text = level_data.display_name if is_unlocked else "???"
		name_lbl.add_theme_font_size_override("font_size", 16)
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		if is_unlocked:
			var minutes := int(level_data.win_time) / 60
			desc_lbl.text = "%d min | x%.1f souls" % [minutes, level_data.soul_multiplier]
		else:
			desc_lbl.text = "Beat the previous stage to unlock"
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.7, 0.7, 0.7, 1)
		info.add_child(desc_lbl)
		hbox.add_child(info)

		var btn := Button.new()
		if is_unlocked:
			btn.text = "Play"
			btn.pressed.connect(_on_stage_selected.bind(i))
		else:
			btn.text = "Locked"
			btn.disabled = true
		btn.custom_minimum_size = Vector2(120, 64)
		btn.add_theme_font_size_override("font_size", 20)
		hbox.add_child(btn)
		stage_buttons.append(btn)

	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(0, 64)
	back_btn.add_theme_font_size_override("font_size", 20)
	back_btn.pressed.connect(func():
		_stage_panel.queue_free()
		_stage_panel = null
		if _select_buttons.size() > 0:
			_select_buttons[0].grab_focus())
	vbox.add_child(back_btn)
	stage_buttons.append(back_btn)

	# Wire focus for stage buttons
	var n := stage_buttons.size()
	for i in n:
		var btn := stage_buttons[i]
		btn.focus_neighbor_top = stage_buttons[(i - 1 + n) % n].get_path()
		btn.focus_neighbor_bottom = stage_buttons[(i + 1) % n].get_path()
		btn.focus_neighbor_left = btn.get_path()
		btn.focus_neighbor_right = btn.get_path()

	# Focus first enabled stage button
	for btn in stage_buttons:
		if not btn.disabled:
			btn.grab_focus()
			break

func _on_stage_selected(idx: int) -> void:
	var data: CharacterData = load(CHARACTER_FILES[_selected_character_idx]) as CharacterData
	GameState.selected_character_data = data
	GameState.selected_level_data = load(LEVEL_FILES[idx]) as LevelData
	get_tree().change_scene_to_file("res://scenes/main.tscn")
