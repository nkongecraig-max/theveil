extends Node

## AudioManager - Procedural audio for The Veil.
## Generates all SFX from waveforms — no external audio files needed.
## Background ambient is a warm low-frequency drone.

var _sfx_players: Dictionary = {}  # name -> AudioStreamPlayer
var _ambient_player: AudioStreamPlayer = null
var sfx_volume: float = 0.8
var music_volume: float = 0.4
var _enabled: bool = true

const SAMPLE_RATE: int = 22050

func _ready() -> void:
	# Pre-generate all SFX
	_create_sfx("tap", _gen_tap())
	_create_sfx("coin", _gen_coin())
	_create_sfx("puzzle_complete", _gen_puzzle_complete())
	_create_sfx("customer_bell", _gen_bell())
	_create_sfx("restock", _gen_restock())
	_create_sfx("level_up", _gen_level_up())
	_create_sfx("patience_tick", _gen_tick())
	_create_sfx("fail", _gen_fail())
	_create_sfx("daily_reward", _gen_daily_reward())
	# Ambient
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Master"
	_ambient_player.volume_db = linear_to_db(music_volume * 0.3)
	_ambient_player.stream = _gen_ambient()
	add_child(_ambient_player)
	print("[AudioManager] Procedural audio ready. %d SFX loaded." % _sfx_players.size())

func play(sfx_name: String) -> void:
	if not _enabled:
		return
	if sfx_name in _sfx_players:
		var player = _sfx_players[sfx_name]
		player.volume_db = linear_to_db(sfx_volume)
		player.play()

func start_ambient() -> void:
	if _ambient_player and not _ambient_player.playing:
		_ambient_player.play()

func stop_ambient() -> void:
	if _ambient_player:
		_ambient_player.stop()

func set_sfx_volume(vol: float) -> void:
	sfx_volume = clampf(vol, 0.0, 1.0)

func set_music_volume(vol: float) -> void:
	music_volume = clampf(vol, 0.0, 1.0)
	if _ambient_player:
		_ambient_player.volume_db = linear_to_db(music_volume * 0.3)

func set_enabled(on: bool) -> void:
	_enabled = on
	if not on:
		stop_ambient()

func _create_sfx(sfx_name: String, stream: AudioStreamWAV) -> void:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = "Master"
	add_child(player)
	_sfx_players[sfx_name] = player

# ====== Waveform Generators ======

func _make_wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = data
	return wav

func _gen_tap() -> AudioStreamWAV:
	# Short crisp click
	var dur = 0.06
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur) * (1.0 - t / dur)
		var s = sin(t * 800.0 * TAU) * 0.4 * env
		s += sin(t * 1200.0 * TAU) * 0.2 * env * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_coin() -> AudioStreamWAV:
	# Rising two-tone chime
	var dur = 0.25
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur)
		var freq = 880.0 + t * 600.0  # Rising pitch
		var s = sin(t * freq * TAU) * 0.35 * env
		s += sin(t * freq * 1.5 * TAU) * 0.15 * env * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_puzzle_complete() -> AudioStreamWAV:
	# Happy ascending arpeggio: C-E-G-C
	var notes = [523.0, 659.0, 784.0, 1047.0]
	var note_dur = 0.12
	var dur = note_dur * notes.size() + 0.15
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var s = 0.0
		for n in notes.size():
			var nt = t - n * note_dur
			if nt >= 0.0 and nt < note_dur + 0.15:
				var nenv = maxf(0.0, 1.0 - nt / (note_dur + 0.15))
				s += sin(nt * notes[n] * TAU) * 0.25 * nenv
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_bell() -> AudioStreamWAV:
	# Door bell ding
	var dur = 0.4
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = exp(-t * 6.0)
		var s = sin(t * 1200.0 * TAU) * 0.3 * env
		s += sin(t * 2400.0 * TAU) * 0.1 * env * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_restock() -> AudioStreamWAV:
	# Satisfying pop
	var dur = 0.15
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur)
		var freq = 400.0 + (1.0 - t / dur) * 300.0
		var s = sin(t * freq * TAU) * 0.4 * env * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_level_up() -> AudioStreamWAV:
	# Celebratory ascending sweep
	var dur = 0.6
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur) * minf(t * 20.0, 1.0)
		var freq = 400.0 + t * 1200.0
		var s = sin(t * freq * TAU) * 0.3 * env
		s += sin(t * freq * 2.0 * TAU) * 0.1 * env
		s += sin(t * freq * 0.5 * TAU) * 0.15 * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_tick() -> AudioStreamWAV:
	# Subtle tick for patience warning
	var dur = 0.04
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur)
		var s = sin(t * 600.0 * TAU) * 0.2 * env * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_fail() -> AudioStreamWAV:
	# Descending sad tone
	var dur = 0.35
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur)
		var freq = 440.0 - t * 200.0
		var s = sin(t * freq * TAU) * 0.3 * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_daily_reward() -> AudioStreamWAV:
	# Coin shower: rapid ascending pings
	var dur = 0.8
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var env = (1.0 - t / dur) * minf(t * 10.0, 1.0)
		var freq = 600.0 + t * 800.0 + sin(t * 30.0) * 200.0
		var s = sin(t * freq * TAU) * 0.25 * env
		s += sin(t * freq * 1.5 * TAU) * 0.1 * env
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	return _make_wav(data)

func _gen_ambient() -> AudioStreamWAV:
	# Warm drone — loops. Low hum + gentle shimmer.
	var dur = 4.0  # 4-second loop
	var samples = int(SAMPLE_RATE * dur)
	var data = PackedByteArray()
	data.resize(samples)
	for i in samples:
		var t = float(i) / SAMPLE_RATE
		var s = sin(t * 80.0 * TAU) * 0.15  # Deep hum
		s += sin(t * 120.0 * TAU) * 0.08   # Warm fifth
		s += sin(t * 160.0 * TAU) * 0.05   # Octave shimmer
		s += sin(t * 3.0 * TAU) * sin(t * 240.0 * TAU) * 0.03  # Gentle modulation
		data[i] = int(clampf((s + 1.0) * 127.5, 0, 255))
	var wav = _make_wav(data)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = samples
	return wav

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		stop_ambient()
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if _enabled:
			start_ambient()
