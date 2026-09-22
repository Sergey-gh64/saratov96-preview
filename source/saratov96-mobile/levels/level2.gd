extends "res://scripts/gameplay_controller.gd"

func _configure_level() -> void:
    level_title = "Без сменки"
    level_subtitle = "УРОВЕНЬ 2 · ШКОЛА"
    objective = "Доберись до класса без сменной обуви"
    start_node = 0
    goal_node = 17

    nodes = {
        0: Vector2(72, 704), 1: Vector2(128, 674), 2: Vector2(56, 638), 3: Vector2(116, 606),
        4: Vector2(188, 568), 5: Vector2(146, 526), 6: Vector2(226, 526), 7: Vector2(188, 486),
        8: Vector2(126, 444), 9: Vector2(250, 444), 10: Vector2(160, 404), 11: Vector2(230, 392),
        12: Vector2(192, 350), 13: Vector2(132, 306), 14: Vector2(192, 292), 15: Vector2(250, 306),
        16: Vector2(192, 246), 17: Vector2(192, 204),
    }
    adjacency = {
        0: [1, 2], 1: [0, 3], 2: [0, 3], 3: [1, 2, 4], 4: [3, 5, 6],
        5: [4, 7], 6: [4, 7], 7: [5, 6, 8, 9], 8: [7, 10],
        9: [7, 10, 11], 10: [8, 9, 12], 11: [9, 12], 12: [10, 11, 13, 14],
        13: [12, 15], 14: [12, 15], 15: [13, 14, 16], 16: [15, 17], 17: [16],
    }
    enemy_specs = [
        {
            "name": "ОХРАННИК",
            "label": "ОХР",
            "patrol": [4, 5, 6, 5],
            "color": Color("#495246"),
            "caught_line": "Сменка где? Назад, герой.",
        },
        {
            "name": "ЗАВУЧ",
            "label": "ЗАВ",
            "patrol": [10, 11, 10, 9, 8, 9],
            "color": Color("#7A4A50"),
            "caught_line": "Молодой человек! Стоять!",
        },
        {
            "name": "ДИРЕКТОР",
            "label": "ДИР",
            "patrol": [13, 14, 15, 16, 15, 14],
            "color": Color("#37485D"),
            "caught_line": "Так. А теперь спокойно объясняем.",
        },
    ]
    initial_enemy_phases = [0, 2, 2]

func _draw_world_backdrop() -> void:
    draw_rect(Rect2(0, 176, VIEW_W, 574), Color("#1B2225"), true)
    draw_rect(Rect2(0, 176, VIEW_W, 126), Color("#3B4142"), true)
    draw_rect(Rect2(28, 194, 334, 92), Color("#847763"), true)

    for x in [58.0, 120.0, 244.0, 306.0]:
        draw_rect(Rect2(x, 211, 34, 44), Color("#172227"), true)
        draw_line(Vector2(x + 17, 211), Vector2(x + 17, 255), Color("#677277"), 2.0)

    draw_rect(Rect2(165, 226, 60, 76), Color("#272C2F"), true)
    draw_string(ThemeDB.fallback_font, Vector2(112, 191), "ШКОЛА №5 · 1996", HORIZONTAL_ALIGNMENT_LEFT, 190, 16, Color("#E0D5BD"))

    draw_colored_polygon(PackedVector2Array([
        Vector2(44, 318), Vector2(346, 318), Vector2(370, 642), Vector2(20, 642)
    ]), Color("#514E47"))
    for y in range(348, 636, 46):
        draw_line(Vector2(34, y), Vector2(356, y), Color("#656159"), 1.0)
    draw_line(Vector2(194, 318), Vector2(194, 642), Color("#656159"), 1.0)

    draw_rect(Rect2(0, 642, VIEW_W, 108), Color("#171D20"), true)
    draw_string(ThemeDB.fallback_font, Vector2(20, 666), "ВХОД", HORIZONTAL_ALIGNMENT_LEFT, 70, 11, Color("#99A2A5"))
    draw_string(ThemeDB.fallback_font, Vector2(20, 446), "КОРИДОР", HORIZONTAL_ALIGNMENT_LEFT, 90, 11, Color("#C0B8AA"))
    draw_string(ThemeDB.fallback_font, Vector2(20, 330), "ДИРЕКЦИЯ", HORIZONTAL_ALIGNMENT_LEFT, 90, 11, Color("#C0B8AA"))

func _after_safe_move() -> void:
    if player_node in [3, 4, 5, 6] and turn % 3 == 1:
        _say("ОХРАННИК", "Сменка где?", 2.1)
    elif player_node in [8, 9, 10, 11, 12] and turn % 4 == 0:
        _say("ЗАВУЧ", "Я всё вижу!", 2.1)
    elif player_node in [13, 14, 15, 16]:
        _say("ДИРЕКТОР", "До звонка две минуты.", 2.1)

func _say(speaker: String, text_value: String, seconds: float) -> void:
    dialogue_speaker = speaker
    dialogue_text = text_value
    dialogue_time = seconds

func _caught_text(who: String) -> String:
    for spec_variant in enemy_specs:
        var spec: Dictionary = spec_variant
        if String(spec["name"]) == who:
            return String(spec["caught_line"])
    return "Попался в коридоре."

func _win_text() -> String:
    return "Успел в класс. Сменку так никто и не увидел."
