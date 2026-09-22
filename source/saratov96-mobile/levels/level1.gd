extends "res://scripts/gameplay_controller.gd"

const COURTYARD: Texture2D = preload("res://assets/legacy/courtyard_clean.webp")
const CHARACTERS: Texture2D = preload("res://assets/legacy/characters.webp")
const WORLD_REGION := Rect2(188, 390, 753, 1110)
const WORLD_RECT := Rect2(0, 176, 390, 574)

func _configure_level() -> void:
    level_title = "До ларька с играми"
    level_subtitle = "УРОВЕНЬ 1 · ДВОРЫ"
    objective = "Дойди до ларька и не попадись гопникам"
    start_node = 0
    goal_node = 14

    nodes = {
        0: Vector2(198, 704),
        1: Vector2(145, 655), 2: Vector2(252, 655),
        3: Vector2(108, 592), 4: Vector2(195, 584), 5: Vector2(292, 592),
        6: Vector2(92, 520), 7: Vector2(157, 508), 8: Vector2(239, 505), 9: Vector2(312, 516),
        10: Vector2(120, 446), 11: Vector2(198, 432), 12: Vector2(276, 428),
        13: Vector2(196, 356), 14: Vector2(304, 300),
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
    draw_texture_rect_region(COURTYARD, WORLD_RECT, WORLD_REGION)

    # Dark tactical grade hides the baked screenshot treatment and lets live
    # path/characters read as game objects rather than another layer of noise.
    draw_rect(WORLD_RECT, Color(0.01, 0.018, 0.022, 0.16), true)

    # Turn the two legacy soft-mask zones into deliberate deep courtyard
    # shadows instead of leaving them as bright blurred artifacts.
    draw_colored_polygon(PackedVector2Array([
        Vector2(0, 176), Vector2(94, 176), Vector2(116, 284),
        Vector2(70, 345), Vector2(0, 326)
    ]), Color(0.025, 0.035, 0.038, 0.48))
    draw_colored_polygon(PackedVector2Array([
        Vector2(126, 236), Vector2(342, 230), Vector2(365, 360),
        Vector2(306, 430), Vector2(155, 414), Vector2(110, 328)
    ]), Color(0.025, 0.030, 0.032, 0.36))

    # The kiosk is the objective, keep it visually legible.
    draw_circle(nodes[goal_node], 28.0, Color(0.96, 0.70, 0.20, 0.07))
    draw_arc(nodes[goal_node], 21.0, 0.0, TAU, 48, Color(0.94, 0.73, 0.31, 0.55), 1.5, true)

func _draw_routes() -> void:
    for a_variant in adjacency.keys():
        var a: int = int(a_variant)
        for b_variant in adjacency[a]:
            var b: int = int(b_variant)
            if a < b:
                draw_line(nodes[a], nodes[b], Color(0.85, 0.67, 0.30, 0.24), 1.4, true)

    var reachable: Array = adjacency.get(player_node, [])
    for destination_variant in reachable:
        var destination: int = int(destination_variant)
        var p: Vector2 = nodes[destination]
        var pulse := 13.0 + sin(Time.get_ticks_msec() * 0.004 + float(destination)) * 1.6
        draw_circle(p, pulse, Color(0.95, 0.71, 0.24, 0.10))
        draw_circle(p, 6.0, Color(0.95, 0.72, 0.25, 0.92))
        draw_arc(p, 10.0, 0.0, TAU, 32, Color(0.98, 0.80, 0.45, 0.90), 1.6, true)

func _draw_player() -> void:
    _draw_character_region(nodes[player_node], Rect2(10, 20, 350, 1040), 0.105, true)

func _draw_enemies() -> void:
    var regions := [
        Rect2(370, 20, 320, 1040),
        Rect2(700, 20, 390, 1020),
        Rect2(1080, 150, 340, 860),
    ]
    for i in range(enemy_specs.size()):
        var spec: Dictionary = enemy_specs[i]
        var patrol: Array = spec["patrol"]
        var phase: int = int(enemy_phases[i]) % patrol.size()
        var enemy_node: int = int(patrol[phase])
        _draw_character_region(nodes[enemy_node], regions[mini(i, regions.size() - 1)], 0.108, false)

func _draw_character_region(feet: Vector2, region: Rect2, scale_value: float, hero: bool) -> void:
    var width: float = region.size.x * scale_value
    var height: float = region.size.y * scale_value
    var dest := Rect2(feet.x - width * 0.5, feet.y - height + 20.0, width, height)

    draw_set_transform(feet + Vector2(0, 7), 0.0, Vector2(1.0, 0.36))
    draw_circle(Vector2.ZERO, 18.0 if hero else 20.0, Color(0, 0, 0, 0.46))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

    if hero:
        draw_circle(feet + Vector2(0, 4), 16.0, Color(0.23, 0.55, 0.86, 0.16))
        draw_arc(feet + Vector2(0, 4), 16.0, 0.0, TAU, 32, Color(0.45, 0.72, 0.96, 0.72), 1.4, true)

    draw_texture_rect_region(CHARACTERS, dest, region)

func _after_safe_move() -> void:
    if player_node in [3, 4, 5] and turn % 2 == 1:
        _say("ГОПНИК", "Эй, пацан. Иди сюда.", 2.0)
        AudioManager.play_voice("near_" + str((turn % 4) + 1))
    elif player_node in [10, 11, 12]:
        _say("ЛАРЁК", "До витрины уже недалеко.", 1.8)

func _say(speaker: String, text_value: String, seconds: float) -> void:
    dialogue_speaker = speaker
    dialogue_text = text_value
    dialogue_time = seconds

func _caught_text(who: String) -> String:
    AudioManager.play_voice("catch_" + str((turn % 3) + 1))
    for spec_variant in enemy_specs:
        var spec: Dictionary = spec_variant
        if String(spec["name"]) == who:
            return String(spec["caught_line"])
    return "Попался во дворе."

func _win_text() -> String:
    return "Ларёк достигнут. Диск с игрой почти твой."
