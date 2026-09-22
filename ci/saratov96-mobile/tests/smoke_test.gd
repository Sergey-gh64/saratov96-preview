extends SceneTree

var failures: Array = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    await process_frame
    _check(AudioManager.enabled == false, "audio must start OFF")

    var select_scene: PackedScene = load("res://scenes/level_select.tscn")
    _check(select_scene != null, "level select scene loads")
    if select_scene != null:
        var select = select_scene.instantiate()
        root.add_child(select)
        await process_frame
        _check(select.find_child("Level1Button", true, false) != null, "Level 1 button exists")
        _check(select.find_child("Level2Button", true, false) != null, "Level 2 button exists")
        select.queue_free()
        await process_frame

    await _check_level("res://scenes/level1.tscn", "Level 1")
    await _check_level("res://scenes/level2.tscn", "Level 2")

    var main_scene: PackedScene = load("res://scenes/main.tscn")
    _check(main_scene != null, "Main scene loads")
    if main_scene != null:
        var main = main_scene.instantiate()
        root.add_child(main)
        await process_frame
        _check(main.current_screen != null, "Main opens Level Select")
        main.open_level(1)
        await process_frame
        _check(main.current_screen != null and main.current_screen.name == "Level1", "Level Select routes to Level 1")
        main.open_level(2)
        await process_frame
        _check(main.current_screen != null and main.current_screen.name == "Level2", "Level Select routes to Level 2")
        main.show_level_select()
        await process_frame
        _check(main.current_screen != null and main.current_screen.name == "LevelSelect", "Back route returns to Level Select")
        main.queue_free()
        await process_frame

    if failures.is_empty():
        print("S96_SMOKE_OK=1")
        quit(0)
    else:
        for failure in failures:
            push_error("S96_SMOKE_FAIL: " + String(failure))
        quit(1)

func _check_level(path: String, label: String) -> void:
    var packed: PackedScene = load(path)
    _check(packed != null, label + " scene loads")
    if packed == null:
        return
    var level = packed.instantiate()
    root.add_child(level)
    await process_frame

    _check(level.route_verified == true, label + " has a guaranteed winning route")
    _check(not level.objective.is_empty(), label + " has one objective")
    _check(level.has_method("restart_level"), label + " shares restart")
    _check(level.has_method("undo_move"), label + " shares undo")

    var start: int = level.player_node
    var destination: int = 1
    _check(destination in level.adjacency[start], label + " test move is adjacent")

    var touch := InputEventScreenTouch.new()
    touch.pressed = true
    touch.position = level.nodes[destination]
    level._unhandled_input(touch)
    await process_frame
    _check(level.player_node == destination, label + " accepts touch movement")

    level.undo_move()
    _check(level.player_node == start, label + " undo restores player")
    level.restart_level()
    _check(level.player_node == start and level.turn == 0, label + " restart restores initial state")

    level.queue_free()
    await process_frame

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
