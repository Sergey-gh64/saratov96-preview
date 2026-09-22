extends Node2D

signal back_requested

const BuildInfo = preload("res://scripts/build_info.gd")

const VIEW_W: float = 390.0
const VIEW_H: float = 844.0
const TOUCH_RADIUS: float = 38.0

var level_title: String = ""
var level_subtitle: String = ""
var objective: String = ""
var nodes: Dictionary = {}
var adjacency: Dictionary = {}
var enemy_specs: Array = []
var goal_node: int = -1
var start_node: int = 0
var initial_enemy_phases: Array = []

var player_node: int = 0
var enemy_phases: Array = []
var turn: int = 0
var state: String = "playing"
var history: Array = []
var route_verified: bool = false
var dialogue_speaker: String = ""
var dialogue_text: String = ""
var dialogue_time: float = 0.0

var back_rect := Rect2(16, 24, 50, 44)
var sound_rect := Rect2(266, 24, 108, 44)
var undo_rect := Rect2(22, 772, 106, 50)
var restart_rect := Rect2(142, 772, 106, 50)
var wait_rect := Rect2(262, 772, 106, 50)

func _ready() -> void:
    _configure_level()
    restart_level()
    route_verified = has_winning_route()
    if not route_verified:
        push_error("S96_ROUTE_UNSOLVABLE: " + level_subtitle)
    AudioManager.state_changed.connect(_on_audio_state_changed)
    queue_redraw()

func _process(delta: float) -> void:
    if dialogue_time > 0.0 and state == "playing":
        dialogue_time = maxf(0.0, dialogue_time - delta)
        if dialogue_time <= 0.0:
            dialogue_speaker = ""
            dialogue_text = ""
            queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
    var pos := Vector2.ZERO
    var pressed: bool = false
    if event is InputEventScreenTouch:
        if event.pressed:
            pos = event.position
            pressed = true
    elif event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            pos = event.position
            pressed = true
    if not pressed:
        return
    _handle_tap(pos)

func _handle_tap(pos: Vector2) -> void:
    if back_rect.has_point(pos):
        back_requested.emit()
        return
    if sound_rect.has_point(pos):
        AudioManager.toggle()
        queue_redraw()
        return
    if undo_rect.has_point(pos):
        undo_move()
        return
    if restart_rect.has_point(pos):
        restart_level()
        return
    if state != "playing":
        restart_level()
        return
    if wait_rect.has_point(pos):
        _commit_move(player_node)
        return

    var options: Array = adjacency.get(player_node, [])
    for destination_variant in options:
        var destination: int = int(destination_variant)
        var point: Vector2 = nodes[destination]
        if point.distance_to(pos) <= TOUCH_RADIUS:
            _commit_move(destination)
            return

func _commit_move(destination: int) -> void:
    if state != "playing":
        return
    if destination != player_node and destination not in adjacency.get(player_node, []):
        return

    history.append(_snapshot())

    if _is_danger(destination, enemy_phases):
        _caught(_danger_name(destination, enemy_phases))
        return

    player_node = destination
    turn += 1
    enemy_phases = _advanced_phases(enemy_phases)
    AudioManager.play_sfx("move")

    if _is_danger(player_node, enemy_phases):
        _caught(_danger_name(player_node, enemy_phases))
        return

    if player_node == goal_node:
        state = "won"
        dialogue_speaker = "ГОТОВО"
        dialogue_text = _win_text()
        dialogue_time = 999.0
        AudioManager.play_sfx("win")
        queue_redraw()
        return

    _after_safe_move()
    queue_redraw()

func undo_move() -> void:
    if history.is_empty():
        return
    var snapshot: Dictionary = history.pop_back()
    player_node = int(snapshot["player_node"])
    enemy_phases = snapshot["enemy_phases"].duplicate()
    turn = int(snapshot["turn"])
    state = String(snapshot["state"])
    dialogue_speaker = String(snapshot["dialogue_speaker"])
    dialogue_text = String(snapshot["dialogue_text"])
    dialogue_time = float(snapshot["dialogue_time"])
    AudioManager.play_sfx("undo")
    queue_redraw()

func restart_level() -> void:
    player_node = start_node
    enemy_phases = initial_enemy_phases.duplicate()
    turn = 0
    state = "playing"
    history.clear()
    dialogue_speaker = ""
    dialogue_text = ""
    dialogue_time = 0.0
    queue_redraw()

func _snapshot() -> Dictionary:
    return {
        "player_node": player_node,
        "enemy_phases": enemy_phases.duplicate(),
        "turn": turn,
        "state": state,
        "dialogue_speaker": dialogue_speaker,
        "dialogue_text": dialogue_text,
        "dialogue_time": dialogue_time,
    }

func _advanced_phases(phases: Array) -> Array:
    var result: Array = []
    for i in range(enemy_specs.size()):
        var spec: Dictionary = enemy_specs[i]
        var patrol: Array = spec["patrol"]
        result.append((int(phases[i]) + 1) % patrol.size())
    return result

func _is_danger(node: int, phases: Array) -> bool:
    for i in range(enemy_specs.size()):
        var spec: Dictionary = enemy_specs[i]
        var patrol: Array = spec["patrol"]
        var phase: int = int(phases[i]) % patrol.size()
        var enemy_node: int = int(patrol[phase])
        if node == enemy_node:
            return true
        if bool(spec.get("detect_adjacent", false)):
            var around: Array = adjacency.get(enemy_node, [])
            if node in around:
                return true
    return false

func _danger_name(node: int, phases: Array) -> String:
    for i in range(enemy_specs.size()):
        var spec: Dictionary = enemy_specs[i]
        var patrol: Array = spec["patrol"]
        var phase: int = int(phases[i]) % patrol.size()
        var enemy_node: int = int(patrol[phase])
        if node == enemy_node:
            return String(spec["name"])
        if bool(spec.get("detect_adjacent", false)) and node in adjacency.get(enemy_node, []):
            return String(spec["name"])
    return "ПРОТИВНИК"

func _caught(who: String) -> void:
    state = "caught"
    dialogue_speaker = who
    dialogue_text = _caught_text(who)
    dialogue_time = 999.0
    AudioManager.play_sfx("caught")
    queue_redraw()

func has_winning_route() -> bool:
    var queue: Array = []
    queue.append({"player": start_node, "phases": initial_enemy_phases.duplicate()})
    var seen: Dictionary = {}
    seen[_state_key(start_node, initial_enemy_phases)] = true
    var cursor: int = 0

    while cursor < queue.size() and cursor < 12000:
        var current: Dictionary = queue[cursor]
        cursor += 1
        var current_player: int = int(current["player"])
        var current_phases: Array = current["phases"]
        var choices: Array = adjacency.get(current_player, []).duplicate()
        choices.append(current_player)

        for destination_variant in choices:
            var destination: int = int(destination_variant)
            if _is_danger(destination, current_phases):
                continue
            var next_phases: Array = _advanced_phases(current_phases)
            if _is_danger(destination, next_phases):
                continue
            if destination == goal_node:
                return true
            var key: String = _state_key(destination, next_phases)
            if not seen.has(key):
                seen[key] = true
                queue.append({"player": destination, "phases": next_phases})
    return false

func _state_key(player: int, phases: Array) -> String:
    var parts := PackedStringArray()
    parts.append(str(player))
    for phase_variant in phases:
        parts.append(str(int(phase_variant)))
    return ":".join(parts)

func _draw() -> void:
    _draw_world_backdrop()
    _draw_routes()
    _draw_enemies()
    _draw_player()
    _draw_hud()
    _draw_dialogue()
    if state != "playing":
        _draw_end_card()

func _draw_routes() -> void:
    for a_variant in adjacency.keys():
        var a: int = int(a_variant)
        for b_variant in adjacency[a]:
            var b: int = int(b_variant)
            if a < b:
                draw_line(nodes[a], nodes[b], Color(0.32, 0.35, 0.34, 0.46), 5.0, true)
                draw_line(nodes[a], nodes[b], Color(0.08, 0.10, 0.11, 0.88), 2.0, true)

    var reachable: Array = adjacency.get(player_node, [])
    for node_variant in nodes.keys():
        var node_id: int = int(node_variant)
        var p: Vector2 = nodes[node_id]
        if node_id == player_node:
            continue
        if node_id in reachable:
            _draw_diamond(p, 11.0, Color("#D8B14B"), Color("#13181A"))
        else:
            draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), Color(0.55, 0.58, 0.56, 0.42), true)

func _draw_diamond(center: Vector2, radius: float, fill: Color, outline: Color) -> void:
    var points := PackedVector2Array([
        center + Vector2(0, -radius),
        center + Vector2(radius * 1.55, 0),
        center + Vector2(0, radius),
        center + Vector2(-radius * 1.55, 0),
    ])
    draw_colored_polygon(points, fill)
    draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), outline, 2.0, true)

func _draw_player() -> void:
    _draw_person(nodes[player_node] + Vector2(0, -19), Color("#527EAF"), Color("#D8C0A5"), "ТЫ")

func _draw_enemies() -> void:
    for i in range(enemy_specs.size()):
        var spec: Dictionary = enemy_specs[i]
        var patrol: Array = spec["patrol"]
        var phase: int = int(enemy_phases[i]) % patrol.size()
        var enemy_node: int = int(patrol[phase])
        var coat: Color = spec.get("color", Color("#684A46"))
        _draw_person(nodes[enemy_node] + Vector2(0, -19), coat, Color("#C8AE93"), String(spec["label"]))

func _draw_person(pos: Vector2, coat: Color, skin: Color, label: String) -> void:
    draw_circle(pos + Vector2(0, -16), 7.0, skin)
    draw_colored_polygon(PackedVector2Array([
        pos + Vector2(-10, -7),
        pos + Vector2(10, -7),
        pos + Vector2(13, 18),
        pos + Vector2(-13, 18),
    ]), coat)
    draw_line(pos + Vector2(-6, 17), pos + Vector2(-8, 31), Color("#15191B"), 5.0)
    draw_line(pos + Vector2(6, 17), pos + Vector2(8, 31), Color("#15191B"), 5.0)
    draw_string(ThemeDB.fallback_font, pos + Vector2(-18, 44), label, HORIZONTAL_ALIGNMENT_CENTER, 36, 10, Color("#E4E1D7"))

func _draw_hud() -> void:
    draw_rect(Rect2(0, 0, VIEW_W, 176), Color(0.025, 0.035, 0.04, 0.97), true)
    draw_rect(Rect2(0, 176, VIEW_W, 2), Color("#3A4548"), true)

    _draw_button(back_rect, "‹", 22)
    _draw_button(sound_rect, "ЗВУК: " + ("ВКЛ" if AudioManager.enabled else "ВЫКЛ"), 11)

    draw_string(ThemeDB.fallback_font, Vector2(78, 53), "САРАТОВ ’96 GO", HORIZONTAL_ALIGNMENT_LEFT, 174, 19, Color("#F1E7CD"))
    draw_string(ThemeDB.fallback_font, Vector2(78, 76), level_subtitle, HORIZONTAL_ALIGNMENT_LEFT, 220, 11, Color("#C9A950"))

    draw_rect(Rect2(20, 100, 350, 58), Color(0.055, 0.07, 0.075, 0.94), true)
    draw_rect(Rect2(20, 100, 350, 58), Color("#596568"), false, 1.0)
    draw_string(ThemeDB.fallback_font, Vector2(32, 122), "ЦЕЛЬ", HORIZONTAL_ALIGNMENT_LEFT, 48, 10, Color("#C9A950"))
    draw_string(ThemeDB.fallback_font, Vector2(32, 147), objective, HORIZONTAL_ALIGNMENT_LEFT, 326, 14, Color("#ECE6D9"))

    draw_rect(Rect2(0, 750, VIEW_W, 94), Color(0.025, 0.035, 0.04, 0.98), true)
    _draw_button(undo_rect, "ОТМЕНИТЬ", 11, not history.is_empty())
    _draw_button(restart_rect, "ЗАНОВО", 12)
    _draw_button(wait_rect, "ПРОПУСТИТЬ", 10)

    var route_mark: String = "✓" if route_verified else "!"
    var status: String = "ХОД %d · %s · %s" % [turn, route_mark, BuildInfo.short_commit()]
    draw_string(ThemeDB.fallback_font, Vector2(24, 742), status, HORIZONTAL_ALIGNMENT_LEFT, 340, 10, Color("#7E8A8D"))

func _draw_button(rect: Rect2, text_value: String, font_size: int, active: bool = true) -> void:
    var fill: Color = Color("#242D31") if active else Color("#171D20")
    var ink: Color = Color("#EEE7D7") if active else Color("#667074")
    draw_rect(rect, fill, true)
    draw_rect(rect, Color("#596568"), false, 1.0)
    var baseline: float = rect.position.y + rect.size.y * 0.62
    draw_string(ThemeDB.fallback_font, Vector2(rect.position.x, baseline), text_value, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, ink)

func _draw_dialogue() -> void:
    if dialogue_text.is_empty():
        return
    var panel := Rect2(34, 190, 322, 72)
    draw_rect(panel, Color(0.025, 0.03, 0.035, 0.96), true)
    draw_rect(panel, Color("#8E7C59"), false, 2.0)
    draw_string(ThemeDB.fallback_font, Vector2(48, 214), dialogue_speaker, HORIZONTAL_ALIGNMENT_LEFT, 292, 10, Color("#C9A950"))
    draw_string(ThemeDB.fallback_font, Vector2(48, 242), dialogue_text, HORIZONTAL_ALIGNMENT_LEFT, 292, 14, Color("#F0ECE2"))

func _draw_end_card() -> void:
    var panel := Rect2(34, 304, 322, 210)
    draw_rect(panel, Color(0.02, 0.025, 0.03, 0.97), true)
    draw_rect(panel, Color("#8E7C59"), false, 3.0)
    var title: String = "ДОБРАЛСЯ" if state == "won" else "ПОПАЛСЯ"
    var hint: String = "Нажми ЗАНОВО или верни ход." if state == "caught" else "Уровень пройден. Можно выбрать другой."
    draw_string(ThemeDB.fallback_font, Vector2(54, 358), title, HORIZONTAL_ALIGNMENT_CENTER, 282, 28, Color("#F1E7CD"))
    draw_string(ThemeDB.fallback_font, Vector2(58, 409), dialogue_text, HORIZONTAL_ALIGNMENT_CENTER, 274, 14, Color("#CDD2D0"))
    draw_string(ThemeDB.fallback_font, Vector2(58, 468), hint, HORIZONTAL_ALIGNMENT_CENTER, 274, 12, Color("#C9A950"))

func _on_audio_state_changed(_enabled: bool) -> void:
    queue_redraw()

func _configure_level() -> void:
    pass

func _draw_world_backdrop() -> void:
    draw_rect(Rect2(0, 176, VIEW_W, 574), Color("#12191C"), true)

func _after_safe_move() -> void:
    pass

func _caught_text(who: String) -> String:
    return "%s тебя заметил." % who

func _win_text() -> String:
    return "Маршрут пройден."
