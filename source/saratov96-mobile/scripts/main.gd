extends Node

var current_screen = null

func _ready() -> void:
    show_level_select()

func show_level_select() -> void:
    _clear_current()
    var packed: PackedScene = load("res://scenes/level_select.tscn")
    current_screen = packed.instantiate()
    add_child(current_screen)
    current_screen.level_requested.connect(open_level)

func open_level(level_id: int) -> void:
    _clear_current()
    var path: String = "res://scenes/level1.tscn" if level_id == 1 else "res://scenes/level2.tscn"
    var packed: PackedScene = load(path)
    current_screen = packed.instantiate()
    add_child(current_screen)
    current_screen.back_requested.connect(show_level_select)

func _clear_current() -> void:
    if current_screen != null and is_instance_valid(current_screen):
        remove_child(current_screen)
        current_screen.queue_free()
    current_screen = null
