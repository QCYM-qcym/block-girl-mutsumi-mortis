"""Deterministic original score/sound design. No samples, recordings or network.

Only Python stdlib + NumPy. Render source PCM24 WAV and game PCM16 WAV.
Music tails are wrapped through the loop boundary; no silence splice is used.
"""
import hashlib
import json
from pathlib import Path
import wave
import numpy as np

HERE = Path(__file__).resolve().parent
ASSETS = HERE.parent
SCORE = json.loads((HERE / 'score.json').read_text(encoding='utf-8'))
RATE = SCORE['sample_rate']
BEAT = 60.0 / SCORE['bpm']
TAU = 2 * np.pi


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def envelope(t, attack, decay):
    return (1 - np.exp(-t / attack)) * np.exp(-t / decay)


def pluck(midi, duration, inner=False):
    t = np.arange(round(duration * RATE)) / RATE
    frequency = hz(midi)
    if inner:
        tone = np.sin(TAU * frequency * t) + 0.18 * np.sin(TAU * frequency * 2.002 * t) * np.exp(-t * 2)
        tone += 0.085 * np.sin(TAU * frequency * 1.002 * t)
        amp = envelope(t, 0.018, 1.6)
    else:
        tone = np.sin(TAU * frequency * t) + 0.20 * np.sin(TAU * frequency * 2 * t) * np.exp(-t * 2.8)
        tone += 0.045 * np.sin(TAU * frequency * 3 * t) * np.exp(-t * 4.5)
        amp = envelope(t, 0.008, 0.88)
    amp *= np.minimum(1, np.maximum(0, (duration - t) / 0.18))
    return tone * amp


def add_at(output, sound, seconds, gain, pan=0, loop=True):
    offset = round(seconds * RATE)
    gains = np.array([np.sqrt((1 - pan) / 2), np.sqrt((1 + pan) / 2)]) * gain
    for delay, level, flipped in ((0, 1.0, False), (0.19, 0.12, True), (0.43, 0.06, False)):
        indices = np.arange(len(sound)) + offset + round(delay * RATE)
        stereo = sound[:, None] * (gains[::-1] if flipped else gains)[None, :] * level
        if loop:
            np.add.at(output, indices % len(output), stereo)
        else:
            valid = (indices >= 0) & (indices < len(output))
            output[indices[valid]] += stereo[valid]


def pad(chord, duration, inner):
    t = np.arange(round(duration * RATE)) / RATE
    attack = np.minimum(t / 0.6, 1)
    release = np.clip((duration - t) / 1.4, 0, 1)
    amp = np.sin(attack * np.pi / 2) ** 2 * np.sin(release * np.pi / 2) ** 2
    voice = np.zeros(len(t))
    for index, midi in enumerate(chord):
        frequency = hz(midi + (12 if inner else 0))
        voice += np.sin(TAU * frequency * t + index * 0.7) / len(chord)
        if inner:
            voice += 0.055 * np.sin(TAU * frequency * 1.0018 * t + index) / len(chord)
        else:
            voice += 0.10 * np.sin(TAU * frequency * 2 * t) / len(chord)
    if inner:
        # One very quiet minor second above the upper chord tone: soft tension, no sharp transient.
        voice += 0.018 * np.sin(TAU * hz(chord[-1] + 13) * t)
    return voice * amp


def music(kind):
    bars = 8 if kind == 'menu' else SCORE['exploration_bars']
    inner = kind == 'inner'
    out = np.zeros((round(bars * 4 * BEAT * RATE), 2))
    for bar, chord in enumerate(SCORE['chords_midi'][:bars]):
        add_at(out, pad(chord, 4 * BEAT + 1.6, inner), bar * 4 * BEAT, 0.055 if inner else 0.062, (-1) ** bar * 0.12)
        # Slowly articulated harmony: room for frequent gameplay actions.
        if kind != 'menu':
            for beat_offset, midi in ((0.5, chord[1] + 12), (2.5, chord[2] + 12)):
                add_at(out, pluck(midi, 3.6, inner), (bar * 4 + beat_offset) * BEAT, 0.037, (-1) ** bar * 0.30)
    for index, (beat, midi, _gate) in enumerate(SCORE['melody']):
        if beat >= bars * 4:
            continue
        add_at(out, pluck(midi, 5.0 if inner else 3.8, inner), beat * BEAT, 0.095 if inner else 0.12, np.sin(index * 1.8) * 0.18)
    return out


def cue(kind):
    spec = SCORE[kind]
    out = np.zeros((round(spec['duration_seconds'] * RATE), 2))
    for index, midi in enumerate(spec['notes_midi']):
        add_at(out, pluck(midi, 3.2), 0.08 + index * (0.34 if kind == 'discovery' else 0.42), 0.14, (index - 2) * 0.08, False)
    add_at(out, pad([50, 57, 62, 64] if kind == 'complete' else [50, 60, 64, 69], spec['duration_seconds'], False), 0, 0.075, 0, False)
    return end_fade(out)


def soft_noise(count, seed, cutoff=1700):
    rng = np.random.default_rng(seed)
    noise = rng.normal(0, 1, count)
    spectrum = np.fft.rfft(noise)
    frequencies = np.fft.rfftfreq(count, 1 / RATE)
    spectrum *= np.exp(-(frequencies / cutoff) ** 4)
    result = np.fft.irfft(spectrum, n=count)
    return result / max(1e-9, np.max(np.abs(result)))


def end_fade(samples):
    output = samples.copy()
    count = min(round(0.035 * RATE), len(output) // 4)
    fade = np.sin(np.linspace(0, np.pi / 2, count)) ** 2
    if output.ndim == 2:
        fade = fade[:, None]
    output[:count] *= fade
    output[-count:] *= fade[::-1]
    return output


def sfx(kind, index):
    durations = dict(cube_roll=.36, cube_contact=.16, edge_lean=.32, edge_recoil=.45,
        fall_start=.38, fall_whoosh=1.5, landing_impact=.55, perspective_connect=.55,
        perspective_disconnect=.50, world_shift=1.1, goal=2.2, ui_select=.12, ui_back=.17)
    duration = durations[kind]
    t = np.arange(round(duration * RATE)) / RATE
    noise = soft_noise(len(t), SCORE['seed'] + index, 1250)
    if kind in ('cube_roll', 'cube_contact', 'landing_impact'):
        frequency = {'cube_roll': 180, 'cube_contact': 310, 'landing_impact': 115}[kind]
        decay = {'cube_roll': .095, 'cube_contact': .04, 'landing_impact': .16}[kind]
        shape = envelope(t, .008, decay)
        tone = np.sin(TAU * frequency * t * (1 - .10 * t)) + .28 * np.sin(TAU * frequency * 2.31 * t)
        output = (tone * .13 + noise * .07) * shape
        if kind == 'cube_roll':
            late = np.maximum(t - .18, 0)
            output += .04 * np.sin(TAU * 245 * late) * envelope(late, .01, .05)
    elif kind in ('edge_lean', 'edge_recoil'):
        phase = TAU * (220 * t - 75 * t * t)
        output = (.12 * np.sin(phase) + .028 * noise) * envelope(t, .045, .16)
        if kind == 'edge_recoil':
            output += .035 * np.sin(TAU * 430 * t) * envelope(t, .01, .065)
    elif kind == 'fall_whoosh':
        # FFT noise is periodic; envelope is periodic too. No edge fades break the loop.
        output = noise * (.04 + .01 * np.cos(TAU * t / duration))
    elif kind == 'fall_start':
        output = (.05 * noise + .10 * np.sin(TAU * (330 * t - 190 * t * t))) * envelope(t, .018, .13)
    elif kind in ('perspective_connect', 'perspective_disconnect', 'world_shift'):
        direction = 1 if kind != 'perspective_disconnect' else -1
        phase = TAU * (440 * t + direction * 95 * t * t)
        output = (.10 * np.sin(phase) + .05 * np.sin(phase * 1.5) + .016 * noise) * np.sin(np.pi * t / duration) ** 2
    elif kind == 'goal':
        output = np.zeros(len(t))
        for note_index, midi in enumerate((74, 77, 81, 86)):
            note = pluck(midi, duration - note_index * .18)
            offset = round(note_index * .18 * RATE)
            output[offset:offset + len(note)] += note[:len(output) - offset] * .10
    else:
        frequency = 660 if kind == 'ui_select' else 440
        output = (.11 * np.sin(TAU * frequency * t) + .03 * np.sin(TAU * frequency * 1.5 * t)) * envelope(t, .003, .025)
    if kind != 'fall_whoosh':
        output = end_fade(output)
    return output[:, None]


def write_wav(path, samples, width):
    path.parent.mkdir(parents=True, exist_ok=True)
    # Remove negligible numerical DC before fixed point; never normalize each file into loudness.
    samples = samples - samples.mean(axis=0)
    if not path.stem.endswith('fall_whoosh') and path.stem not in ('bgm_menu', 'bgm_surface', 'bgm_inner'):
        samples = end_fade(samples)
    if width == 2:
        pcm = np.round(np.clip(samples, -.999, .999) * 32767).astype('<i2').tobytes()
    else:
        numbers = np.round(np.clip(samples, -.999, .999) * 8388607).astype(np.int32).ravel()
        packed = np.empty((len(numbers), 3), dtype=np.uint8)
        for byte in range(3):
            packed[:, byte] = (numbers >> (8 * byte)) & 255
        pcm = packed.tobytes()
    with wave.open(str(path), 'wb') as stream:
        stream.setnchannels(samples.shape[1])
        stream.setsampwidth(width)
        stream.setframerate(RATE)
        stream.writeframes(pcm)


def main():
    manifest = dict(schema_version=1, sample_rate=RATE, source_recipe='source/synthesize.py',
        score='source/score.json', license='LICENSE_PROVENANCE.md', encoding='PCM16_WAV',
        ogg_status='NOT_PRODUCED_NO_ENCODER_AVAILABLE', music={}, sfx={})
    sfx_keys = ['cube_roll', 'cube_contact', 'edge_lean', 'edge_recoil', 'fall_start', 'fall_whoosh',
        'landing_impact', 'perspective_connect', 'perspective_disconnect', 'world_shift', 'goal', 'ui_select', 'ui_back']
    rendered = {}
    for group, keys in (('music', ['menu', 'surface', 'inner', 'discovery', 'complete']), ('sfx', sfx_keys)):
        for index, key in enumerate(keys):
            samples = music(key) if key in ('menu', 'surface', 'inner') else cue(key) if group == 'music' else sfx(key, index)
            rendered[key] = samples
            stem = f'bgm_{key}' if group == 'music' else f'sfx_{key}'
            filename = stem + '.wav'
            export = ASSETS / 'exports' / filename
            source = ASSETS / 'source' / 'pcm24' / filename
            write_wav(export, samples, 2)
            write_wav(source, samples, 3)
            loop = key in ('menu', 'surface', 'inner', 'fall_whoosh')
            entry = dict(path='res://production/experimental/game_feel_01/audio/exports/' + filename,
                source_path='res://production/experimental/game_feel_01/audio/source/pcm24/' + filename,
                length_seconds=len(samples) / RATE, frame_count=len(samples), channels=samples.shape[1],
                loop=loop, loop_start_frame=0, loop_end_frame=len(samples) if loop else 0,
                gain_db=-3.0 if group == 'music' else -2.0,
                sha256=hashlib.sha256(export.read_bytes()).hexdigest(),
                source_sha256=hashlib.sha256(source.read_bytes()).hexdigest(),
                provenance='original deterministic synthesis; no sampled material')
            if group == 'music' and loop:
                entry.update(bpm=SCORE['bpm'], bars=8 if key == 'menu' else 12,
                    sync_group='exploration_pair_v1' if key != 'menu' else 'menu_v1')
            manifest[group][key] = entry
    (ASSETS / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    # Offline listening aid only: world blend preserves phrase position, then labeled cue order in README.
    count = round(24 * RATE)
    progress = np.clip((np.arange(count) / RATE - 10) / 2, 0, 1)
    preview = rendered['surface'][:count] * np.cos(progress[:, None] * np.pi / 2)
    preview += rendered['inner'][:count] * np.sin(progress[:, None] * np.pi / 2)
    preview = end_fade(preview)
    segments = [preview, np.zeros((RATE, 2))]
    for key in sfx_keys:
        segments.append(np.repeat(rendered[key], 2, axis=1))
        segments.append(np.zeros((round(.45 * RATE), 2)))
    write_wav(ASSETS / 'previews' / 'asset_audition.wav', np.concatenate(segments), 2)
    print('Produced 5 music files and 13 SFX; source PCM24 + export PCM16 WAV.')


if __name__ == '__main__':
    main()
