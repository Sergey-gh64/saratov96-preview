extends "res://scripts/gameplay_controller.gd"

func _configure_level() -> void:
    level_title = "До ларька с играми"
    level_subtitle = "УРОВЕНЬ 1 · ДВОРЫ"
    objective = "Дойди до ларька и не попадись гопникам"
    start_node = 0
    goal_node = 14

    nodes = {
        0: Vector2(195, 704),
        1: Vector2(145, 655), 2: Vector2(245, 655),
        3: Vector2(108, 592), 4: Vector2(195, 582), 5: Vector2(282, 592),
        6: Vector2(88, 514), 7: Vector2(155, 505), 8: Vector2(235, 505), 9: Vector2(305, 514),
        10: Vector2(124, 426), 11: Vector2(195, 421), 12: Vector2(266, 426),
        13: Vector2(158, 340), 14: Vector2(232, 332),
    }
    adjacency = {
        0: [1, 2],
        1: [0, 3, 4], 2: [0, 4, 5],
        3: [1, 6, 7], 4: [1, 2, 7, 8], 5: [2, 8, 9],
        6: [3, 10], 7: [3, 4, 10, 11], 8: [4, 5, 11, 12], 9: [5, 12],
        10: [6, 7, 13], 11: [7, 8, 13, 14], 12: [8, 9, 14],
        13: [10, 11, 14], 14: [11, 12, 13],
    }
    enemy_specs = [
        {
            "name": "ГОПНИК В КЕПКЕ",
            "label": "ГОП",
            "patrol": [4, 7, 10, 7],
            "color": Color("#5F5143"),
            "caught_line": "Э, стой. Мелочь есть?",
        },
        {
            "name": "ГОПНИК У ГАРАЖЕЙ",
            "label": "ГОП",
            "patrol": [8, 12, 9, 5, 2, 5],
            "color": Color("#66454A"),
            "caught_line": "Куда собрался так быстро?",
        },
    ]
    initial_enemy_phases = [1, 0]

func _draw_world_backdrop() -> void:
    draw_rect(Rect2(0, 176, VIEW_W, 574), Color("#182126"), true)

    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 228), Vector2(144, 196), Vector2(150, 430), Vector2(0, 470)
    ]), Color("#4D4A43"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(390, 210), Vector2(255, 192), Vector2(248, 440), Vector2(390, 474)
    ]), Color("#454742"))

    for y in [244.0, 294.0, 344.0]:
        draw_rect(Rect2(18, y, 36, 22), Color("#202D32"), true)
        draw_rect(Rect2(78, y - 8, 40, 24), Color("#202D32"), true)
        draw_rect(Rect2(302, y - 4, 42, 24), Color("#1D2B30"), true)

    draw_colored_polygon(PackedVector2Array([
        Vector2(72, 742), Vector2(132, 388), Vector2(258, 388), Vector2(328, 742)
    ]), Color("#303537"))
    draw_line(Vector2(194, 742), Vector2(194, 392), Color("#5A5B54"), 2.0)

    for y in range(430, 710, 64):
        draw_line(Vector2(102, y), Vector2(288, y - 12), Color(0.45, 0.43, 0.38, 0.18), 2.0)

    draw_rect(Rect2(192, 278, 122, 76), Color("#2B2118"), true)
    draw_rect(Rect2(201, 287, 104, 58), Color("#76522D"), true)
    draw_rect(Rect2(210, 296, 86, 24), Color("#D6B34E"), true)
    draw_string(ThemeDB.fallback_font, Vector2(217, 314), "ИГРЫ · CD", HORIZONTAL_ALIGNMENT_LEFT, 74, 12, Color("#241A12"))
    draw_rect(Rect2(230, 320, 38, 25), Color("#131719"), true)

    draw_string(ThemeDB.fallback_font, Vector2(18, 500), "ГАРАЖИ", HORIZONTAL_ALIGNMENT_LEFT, 80, 11, Color("#8C989A"))
    draw_string(ThemeDB.fallback_font, Vector2(284, 548), "ДВОР", HORIZONTAL_ALIGNMENT_LEFT, 74, 11, Color("#8C989A"))
    draw_string(ThemeDB.fallback_font, Vector2(18, 724), "1996", HORIZONTAL_ALIGNMENT_LEFT, 70, 12, Color("#C9A950"))

func _after_safe_move() -> void:
    if player_node in [3, 4, 5] and turn % 2 == 1:
        _say("ГОПНИК", "Эй, пацан. Иди сюда.", 2.0)
    elif player_node in [10, 11, 12]:
        _say("ЛАРЁК", "До витрины уже недалеко.", 1.8)

func _say(speaker: String, text_value: String, seconds: float) -> void:
    dialogue_speaker = speaker
    dialogue_text = text_value
    dialogue_time = seconds

func _caught_text(who: String) -> String:
    for spec_variant in enemy_specs:
        var spec: Dictionary = spec_variant
        if String(spec["name"]) == who:
            return String(spec["caught_line"])
    return "Попался во дворе."

func _win_text() -> String:
    return "Ларёк достигнут. Диск с игрой почти твой."
