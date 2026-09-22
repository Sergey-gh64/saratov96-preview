extends Node

signal state_changed(enabled: bool)

const AUDIO_PATHS := {
    "music": "res://assets/audio/music_30s.mp3",
    "step": "res://assets/audio/step.mp3",
    "coin": "res://assets/audio/coin.mp3",
    "cassette": "res://assets/audio/cassette.mp3",
    "firecracker": "res://assets/audio/firecracker.mp3",
    "buy": "res://assets/audio/buy.mp3",
    "catch": "res://assets/audio/catch.mp3",
    "near_1": "res://assets/audio/near_1.mp3",
    "near_2": "res://assets/audio/near_2.mp3",
    "near_3": "res://assets/audio/near_3.mp3",
    "near_4": "res://assets/audio/near_4.mp3",
    "catch_1": "res://assets/audio/catch_1.mp3",
    "catch_2": "res://assets/audio/catch_2.mp3",
    "catch_3": "res://assets/audio/catch_3.mp3",
}

var enabled: bool = false
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var streams: Dictionary = {}

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "Music"
    music_player.volume_db = -11.0
    add_child(music_player)

    sfx_player = AudioStreamPlayer.new()
    sfx_player.name = "Sfx"
    sfx_player.volume_db = -6.0
    sfx_player.max_polyphony = 4
    add_child(sfx_player)

    voice_player = AudioStreamPlayer.new()
    voice_player.name = "Voice"
    voice_player.volume_db = -2.0
    add_child(voice_player)

    for key in AUDIO_PATHS:
        var stream: AudioStream = ResourceLoader.load(String(AUDIO_PATHS[key]))
        if stream == null:
            push_error("S96_AUDIO_MISSING: " + String(AUDIO_PATHS[key]))
        streams[key] = stream

    var music: AudioStream = streams.get("music")
    if music is AudioStreamMP3:
        music.loop = true
    music_player.stream = music

func toggle() -> void:
    set_enabled(not enabled)

func set_enabled(value: bool) -> void:
    enabled = value
    if enabled:
        if music_player.stream != null and not music_player.playing:
            music_player.play()
        play_sfx("ui")
    else:
        music_player.stop()
        sfx_player.stop()
        voice_player.stop()
    state_changed.emit(enabled)

func play_sfx(kind: String) -> void:
    if not enabled:
        return
    var key := "coin"
    match kind:
        "move":
            key = "step"
        "undo":
            key = "coin"
        "win":
            key = "buy"
        "caught":
            key = "catch"
        "ui":
            key = "coin"
        _:
            key = kind
    _play_on(sfx_player, key)

func play_voice(key: String) -> void:
    if not enabled:
        return
    _play_on(voice_player, key)

func _play_on(player: AudioStreamPlayer, key: String) -> void:
    var stream: AudioStream = streams.get(key)
    if stream == null:
        push_warning("S96_AUDIO_STREAM_NULL: " + key)
        return
    player.stream = stream
    player.play()

func resources_ready() -> bool:
    if streams.size() != AUDIO_PATHS.size():
        return false
    for key in AUDIO_PATHS:
        if streams.get(key) == null:
            return false
    return music_player != null and music_player.stream != null
