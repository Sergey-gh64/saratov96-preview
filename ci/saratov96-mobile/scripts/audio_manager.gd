extends Node

signal state_changed(enabled: bool)

var enabled: bool = false
var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

func _ready() -> void:
    music_player = AudioStreamPlayer.new()
    music_player.name = "Music"
    music_player.stream = _make_music_loop()
    music_player.volume_db = -11.0
    add_child(music_player)

    sfx_player = AudioStreamPlayer.new()
    sfx_player.name = "Sfx"
    sfx_player.volume_db = -8.0
    add_child(sfx_player)

func toggle() -> void:
    set_enabled(not enabled)

func set_enabled(value: bool) -> void:
    enabled = value
    if enabled:
        if music_player.stream != null and not music_player.playing:
            music_player.play()
        play_sfx("ui")
    else:
        if music_player.playing:
            music_player.stop()
        if sfx_player.playing:
            sfx_player.stop()
    state_changed.emit(enabled)

func play_sfx(kind: String) -> void:
    if not enabled:
        return
    var freq: float = 520.0
    var duration: float = 0.065
    match kind:
        "move":
            freq = 430.0
        "undo":
            freq = 310.0
        "win":
            freq = 880.0
            duration = 0.14
        "caught":
            freq = 145.0
            duration = 0.18
        _:
            freq = 620.0
    sfx_player.stream = _make_tone(freq, duration, 0.22)
    sfx_player.play()

func _make_music_loop() -> AudioStreamWAV:
    var rate: int = 22050
    var seconds: float = 4.0
    var frames: int = int(rate * seconds)
    var data := PackedByteArray()
    data.resize(frames * 2)
    var notes: Array = [110.0, 146.83, 164.81, 130.81, 110.0, 130.81, 98.0, 110.0]
    var beat_frames: int = int(rate * 0.5)
    for i in range(frames):
        var note_index: int = mini(notes.size() - 1, int(i / beat_frames))
        var freq: float = float(notes[note_index])
        var t: float = float(i) / float(rate)
        var pulse: float = sin(TAU * freq * t) * 0.075
        pulse += sin(TAU * freq * 2.0 * t) * 0.018
        var sample: int = int(clampf(pulse, -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
    wav.loop_begin = 0
    wav.loop_end = frames
    wav.data = data
    return wav

func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
    var rate: int = 22050
    var frames: int = max(1, int(rate * duration))
    var data := PackedByteArray()
    data.resize(frames * 2)
    for i in range(frames):
        var t: float = float(i) / float(rate)
        var fade: float = 1.0 - (float(i) / float(frames))
        var value: float = sin(TAU * freq * t) * volume * fade
        data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767.0))
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = rate
    wav.stereo = false
    wav.data = data
    return wav
