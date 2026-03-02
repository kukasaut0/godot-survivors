extends Control

const CHARACTER_FILES: Array[String] = [
	"res://data/characters/default.tres",
	"res://data/characters/speeder_hero.tres",
	"res://data/characters/tank_hero.tres",
]

const CHARACTER_UNLOCK_KEYS: Array[String] = [
	"",
	"char_speeder_hero",
	"char_tank_hero",
]

@onready var _grid: HBoxContainer = $VBox/CharacterGrid
@onready var _hint_label: Label = $VBox/HintLabel

var _select_buttons: Array[Button] = []
var _souls_label: Label
var _shop_button: Button

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
	card.custom_minimum_size = Vector2(180, 240)
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
		btn.pressed.connect(_on_character_selected.bind(idx))
		vbox.add_child(btn)
		_select_buttons.append(btn)
	else:
		var locked_label := Label.new()
		locked_label.text = "LOCKED\nSurvive 5 min"
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
	var data: CharacterData = load(CHARACTER_FILES[idx]) as CharacterData
	GameState.selected_character_data = data
	get_tree().change_scene_to_file("res://scenes/main.tscn")
