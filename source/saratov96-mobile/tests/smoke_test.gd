extends Node

var failures: Array = []

func _ready() -> void:
    call_deferred("_run")

func _run() -> void:
    await get_tree().process_frame

    var audio := get_node_or_null("/root/AudioManager")
    _check(audio != null, "AudioManager autoload exists")
    if audio != null:
        _check(bool(audio.get("enabled")) == false, "audio must start OFF")
        _check(audio.has_method("resources_ready") and bool(audio.resources_ready()), "imported MP3 audio resources load")
        audio.set_enabled(true)
        await get_tree().process_frame
        _check(bool(audio.get("enabled")) == true, "audio toggles ON")
        _check(audio.music_player != null and audio.music_player.stream is AudioStreamMP3, "music uses imported MP3, not procedural WAV")
        audio.set_enabled(false)
        _check(bool(audio.get("enabled")) == false, "audio toggles OFF")

    _check(ResourceLoader.exists("res://assets/legacy/courtyard_clean.webp"), "Level 1 courtyard art exists")
    _check(ResourceLoader.exists("res://assets/legacy/characters.webp"), "character atlas exists")
    _check(ResourceLoader.exists("res://assets/audio/music_30s.mp3"), "music file exists")

    var select_scene: PackedScene = load("res://scenes/level_select.tscn")
    _check(select_scene != null, "level select scene loads")
    if select_scene != null:
        var select = select_scene.instantiate()
        get_tree().root.add_child(select)
        await get_tree().process_frame
        _check(select.find_child("Level1Button", true, false) != null, "Level 1 button exists")
        _check(select.find_child("Level2Button", true, false) != null, "Level 2 button exists")
        select.queue_free()
        await get_tree().process_frame

    await _check_level("res://scenes/level1.tscn", "Level 1")
    await _check_level("res://scenes/level2.tscn", "Level 2")

    var main_scene: PackedScene = load("res://scenes/main.tscn")
    _check(main_scene != null, "Main scene loads")
    if main_scene != null:
        var main = main_scene.instantiate()
        get_tree().root.add_child(main)
        await get_tree().process_frame
        _check(main.current_screen != null, "Main opens Level Select")
        main.open_level(1)
        await get_tree().process_frame
        _check(main.current_screen != null and main.current_screen.name == "Level1", "Level Select routes to Level 1")
        main.open_level(2)
        await get_tree().process_frame
        _check(main.current_screen != null and main.current_screen.name == "Level2", "Level Select routes to Level 2")
        main.show_level_select()
        await get_tree().process_frame
        _check(main.current_screen != null and main.current_screen.name == "LevelSelect", "Back route returns to Level Select")
        main.queue_free()
        await get_tree().process_frame

    if failures.is_empty():
        print("S96_SMOKE_OK=1")
        get_tree().quit(0)
    else:
        for failure in failures:
            push_error("S96_SMOKE_FAIL: " + String(failure))
        get_tree().quit(1)

func _check_level(path: String, label: String) -> void:
    var packed: PackedScene = load(path)
    _check(packed != null, label + " scene loads")
    if packed == null:
        return
    var level = packed.instantiate()
    get_tree().root.add_child(level)
    await get_tree().process_frame

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
    await get_tree().process_frame
    _check(level.player_node == destination, label + " accepts touch movement")

    level.undo_move()
    _check(level.player_node == start, label + " undo restores player")
    level.restart_level()
    _check(level.player_node == start and level.turn == 0, label + " restart restores initial state")

    level.queue_free()
    await get_tree().process_frame

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
