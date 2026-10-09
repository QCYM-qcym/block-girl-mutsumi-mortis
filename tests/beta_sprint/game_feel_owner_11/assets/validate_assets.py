"""Actual PCM contract/quality checks; this does not claim auditory listening."""
import hashlib
import json
from pathlib import Path
import sys
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[4]
ASSETS = ROOT / 'production/experimental/game_feel_01/audio'
EXPECTED_MUSIC = {'menu', 'surface', 'inner', 'discovery', 'complete'}
EXPECTED_SFX = {'cube_roll', 'cube_contact', 'edge_lean', 'edge_recoil', 'fall_start',
                'fall_whoosh', 'landing_impact', 'perspective_connect',
                'perspective_disconnect', 'world_shift', 'goal', 'ui_select', 'ui_back'}


def validate():
    manifest = json.loads((ASSETS / 'manifest.json').read_text(encoding='utf-8'))
    assert set(manifest['music']) == EXPECTED_MUSIC
    assert set(manifest['sfx']) == EXPECTED_SFX
    metrics = {}
    for group in ('music', 'sfx'):
        for key, entry in manifest[group].items():
            path = ROOT / entry['path'].removeprefix('res://')
            assert hashlib.sha256(path.read_bytes()).hexdigest() == entry['sha256'], key
            source_path = ROOT / entry['source_path'].removeprefix('res://')
            assert hashlib.sha256(source_path.read_bytes()).hexdigest() == entry['source_sha256'], key
            with wave.open(str(source_path), 'rb') as source:
                assert source.getsampwidth() == 3 and source.getframerate() == 44100
                assert source.getnchannels() == entry['channels'] and source.getnframes() == entry['frame_count']
            with wave.open(str(path), 'rb') as stream:
                assert stream.getframerate() == 44100 and stream.getsampwidth() == 2
                channels, count = stream.getnchannels(), stream.getnframes()
                samples = np.frombuffer(stream.readframes(count), dtype='<i2').reshape(-1, channels) / 32768.0
            peak = float(np.max(np.abs(samples)))
            rms = float(np.sqrt(np.mean(samples ** 2)))
            dc = float(np.max(np.abs(np.mean(samples, axis=0))))
            seam = float(np.max(np.abs(samples[0] - samples[-1])))
            derivative = float(np.max(np.abs(np.diff(samples, axis=0))))
            assert count == entry['frame_count']
            assert abs(count / 44100 - entry['length_seconds']) < 1e-9
            assert 0.005 < peak < 0.71, (key, peak)
            assert rms > 0.0004 and dc < 0.002, (key, rms, dc)
            assert derivative < 0.1, (key, derivative)
            if entry['loop']:
                assert entry['loop_start_frame'] == 0 and entry['loop_end_frame'] == count
                assert seam < 0.012, (key, seam)
            else:
                assert np.max(np.abs(samples[0])) < 0.0001
                assert np.max(np.abs(samples[-1])) < 0.0001
            metrics[f'{group}/{key}'] = dict(frame_count=count, channels=channels,
                peak=peak, peak_dbfs=20 * np.log10(peak), rms=rms, dc=dc,
                seam_jump=seam, max_sample_step=derivative,
                sha256=entry['sha256'])
    for field in ('frame_count', 'length_seconds', 'bpm', 'bars', 'loop'):
        assert manifest['music']['surface'][field] == manifest['music']['inner'][field], field
    assert manifest['music']['surface']['sha256'] != manifest['music']['inner']['sha256']
    # Test the actual PCM crossfade on the synchronized pair; keep equal-power sum headroom.
    pair = []
    for key in ('surface', 'inner'):
        with wave.open(str(ROOT / manifest['music'][key]['path'].removeprefix('res://')), 'rb') as stream:
            pair.append(np.frombuffer(stream.readframes(stream.getnframes()), dtype='<i2') / 32768.0)
    blend_peak = max(float(np.max(np.abs(pair[0] * np.cos(t * np.pi / 2) + pair[1] * np.sin(t * np.pi / 2)))) for t in np.linspace(0, 1, 21))
    assert blend_peak < 0.71, blend_peak
    return dict(status='PASS', asset_count=18, crossfade_peak=blend_peak, metrics=metrics,
                subjective_listening='NOT_RUN', authority='PCM_ASSET_ANALYSIS_ONLY',
                encoding='PCM16_WAV', fixture_kind='ORIGINAL_AUDIO_ASSET_VALIDATION')


if __name__ == '__main__':
    result = validate()
    payload = json.dumps(result, indent=2)
    if len(sys.argv) > 1:
        Path(sys.argv[1]).write_text(payload + '\n', encoding='utf-8')
    print(payload)
