extends Control

signal level_requested(level_id: int)

const BuildInfo = preload("res://scripts/build_info.gd")

func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_ui()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.color = Color("#071015")
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(bg)
    move_child(bg, 0)

    var skyline := ColorRect.new()
    skyline.color = Color("#162026")
    skyline.position = Vector2(0, 116)
    skyline.size = Vector2(390, 112)
    skyline.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(skyline)

    var title := Label.new()
    title.text = "САРАТОВ ’96 GO"
    title.position = Vector2(28, 58)
    title.size = Vector2(334, 42)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("#F1E7CD"))
    add_child(title)

    var subtitle := Label.new()
    subtitle.text = "ТАКТИЧЕСКИЕ ИСТОРИИ · 1996"
    subtitle.position = Vector2(28, 104)
    subtitle.size = Vector2(334, 28)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 12)
    subtitle.add_theme_color_override("font_color", Color("#C9A950"))
    add_child(subtitle)

    var prompt := Label.new()
    prompt.text = "ВЫБЕРИ УРОВЕНЬ"
    prompt.position = Vector2(28, 190)
    prompt.size = Vector2(334, 30)
    prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt.add_theme_font_size_override("font_size", 14)
    prompt.add_theme_color_override("font_color", Color("#AEB8BB"))
    add_child(prompt)

    var level1 := _make_button("Level1Button", "1 · ДО ЛАРЬКА С ИГРАМИ", Vector2(28, 246))
    level1.tooltip_text = "Саратов середины 90-х"
    level1.pressed.connect(_on_level1)
    add_child(level1)

    var level2 := _make_button("Level2Button", "2 · БЕЗ СМЕНКИ", Vector2(28, 366))
    level2.tooltip_text = "Школа"
    level2.pressed.connect(_on_level2)
    add_child(level2)

    var note := Label.new()
    note.text = "Один ход твой → один ход мира\nПродумай маршрут и не попадись."
    note.position = Vector2(38, 512)
    note.size = Vector2(314, 72)
    note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    note.add_theme_font_size_override("font_size", 15)
    note.add_theme_color_override("font_color", Color("#C7D0D2"))
    add_child(note)

    var build := Label.new()
    build.text = "%s · %s" % [BuildInfo.BUILD_VERSION, BuildInfo.short_commit()]
    build.position = Vector2(24, 786)
    build.size = Vector2(342, 28)
    build.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    build.add_theme_font_size_override("font_size", 10)
    build.add_theme_color_override("font_color", Color("#657278"))
    add_child(build)

func _make_button(node_name: String, text_value: String, pos: Vector2) -> Button:
    var button := Button.new()
    button.name = node_name
    button.text = text_value
    button.position = pos
    button.size = Vector2(334, 92)
    button.focus_mode = Control.FOCUS_NONE
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_color_override("font_color", Color("#F3E9D0"))
    button.add_theme_color_override("font_hover_color", Color("#FFF4D4"))
    button.add_theme_stylebox_override("normal", _style(Color("#202A2E"), Color("#8E7C52"), 2))
    button.add_theme_stylebox_override("hover", _style(Color("#273338"), Color("#C9A950"), 2))
    button.add_theme_stylebox_override("pressed", _style(Color("#151C20"), Color("#E5C76B"), 3))
    return button

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(width)
    style.set_corner_radius_all(10)
    return style

func _on_level1() -> void:
    level_requested.emit(1)

func _on_level2() -> void:
    level_requested.emit(2)
