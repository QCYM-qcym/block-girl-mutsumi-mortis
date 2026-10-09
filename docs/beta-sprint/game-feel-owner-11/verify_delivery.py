"""Read-only source/evidence/scope gate; stdout records actual HEAD and dirty state."""
from pathlib import Path
import hashlib
import json
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASELINE = '2938d6e534f5b596bb320ce79d72b69f5923f3cd'
PREFIXES = ['game/feel/audio/', 'production/experimental/game_feel_01/audio/', 'tests/beta_sprint/game_feel_owner_11/', 'docs/beta-sprint/game-feel-owner-11/']


def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def verify():
    files = git('-c', 'core.quotepath=false', 'diff', '--name-only', BASELINE, 'HEAD').decode('utf-8').splitlines()
    staged = git('-c', 'core.quotepath=false', 'diff', '--cached', '--name-only').decode('utf-8').splitlines()
    untracked = git('ls-files', '--others', '--exclude-standard', '-z').decode('utf-8').split('\0')
    for rel in files + staged + [r for r in untracked if r]:
        assert any(rel.startswith(prefix) for prefix in PREFIXES), ('OUTSIDE_OWNER_SCOPE', rel)
    rows = []
    for entry in git('ls-tree', '-r', '-z', '--full-tree', BASELINE).split(b'\0'):
        if not entry:
            continue
        meta, path = entry.split(b'\t', 1)
        mode, kind, oid = meta.split()
        if kind != b'blob':
            continue
        rows.append((oid, path.decode('utf-8')))
    raw = git('cat-file', '--batch') if not rows else subprocess.check_output(['git', 'cat-file', '--batch'], cwd=ROOT, input=b'\n'.join(oid for oid, _ in rows) + b'\n')
    offset = 0
    mismatches = []
    for _, rel in rows:
        end = raw.index(b'\n', offset)
        size = int(raw[offset:end].split()[-1])
        data = raw[end + 1:end + 1 + size]
        offset = end + 1 + size + 1
        if not (ROOT / rel).exists() or sha(ROOT / rel) != hashlib.sha256(data).hexdigest():
            mismatches.append(rel)
    assert not mismatches, ('BASELINE_BYTE_DRIFT', mismatches)
    binding = []
    for name, checks in [('runtime_shapes_green_01', 79), ('runtime_shapes_director_green_01', 48), ('runtime_shapes_settings_green_01', 10)]:
        folder = ROOT / 'tests/beta_sprint/game_feel_owner_11/evidence' / name
        report = json.loads((folder / 'process.json').read_text(encoding='utf-8-sig'))
        assert report['status'] == 'PASS' and report['checks'] == checks and not report['source_drift'], name
        assert all(sha(ROOT / rel) == value for rel, value in report['source_sha256'].items()), ('FINAL_SOURCE_BINDING_DRIFT', name)
        binding.append({'case': name, 'checks': checks, 'process_sha256': sha(folder / 'process.json')})
    native = ROOT / 'tests/beta_sprint/game_feel_owner_11/evidence/native_shapes_green_02'
    native_report = json.loads((native / 'process.json').read_text(encoding='utf-8-sig'))
    assert native_report['status'] == 'PASS' and native_report['checks'] == 16 and not native_report['source_drift']
    assert native_report['runtime_dependency_commit'] == '26387d6c34a869ad7035ee13ee77d8d5c24d796a'
    for rel, value in native_report['execution_source_sha256'].items():
        assert sha(native / 'execution_project' / rel) == value, ('NATIVE_SOURCE_DRIFT', rel)
    for rel in ['game/feel/audio/event_policy.gd', 'tests/beta_sprint/game_feel_owner_11/test_native_shapes.gd']:
        assert sha(ROOT / rel) == native_report['execution_source_sha256'][rel]
    binding.append({'case': 'native_shapes_green_02', 'checks': 16, 'process_sha256': sha(native / 'process.json')})
    previous_audio = '4afbd068fae74a826dae4db04c2c612af23fa861'
    asset_entries = git('ls-tree', '-r', '-z', '--full-tree', previous_audio, '--', 'production/experimental/game_feel_01/audio').split(b'\0')
    for entry in asset_entries:
        if not entry: continue
        meta, path = entry.split(b'\t', 1)
        assert sha(ROOT / path.decode('utf-8')) == hashlib.sha256(git('show', previous_audio + ':' + path.decode('utf-8'))).hexdigest(), ('ORIGINAL_ASSET_DRIFT', path)
    metrics = json.loads((ROOT / 'tests/beta_sprint/game_feel_owner_11/assets/pcm_metrics_final.json').read_text())
    assert metrics['status'] == 'PASS' and metrics['asset_count'] == 18
    cleanup = json.loads((ROOT / 'docs/beta-sprint/game-feel-owner-11/GENERATED_SIDECAR_CLEANUP.json').read_text(encoding='utf-8-sig'))
    assert all(not (ROOT / row['path']).exists() for row in cleanup)
    return {'status': 'PASS', 'head': git('rev-parse', 'HEAD').decode().strip(), 'branch': git('branch', '--show-current').decode().strip(), 'dirty': git('status', '--porcelain').decode('utf-8').splitlines(), 'baseline': BASELINE, 'baseline_byte_identical_files': len(rows), 'outside_owner_changes': [], 'final_source_bindings': binding, 'checks': 153, 'actual_audio_assets': 18, 'original_audio_asset_files_unchanged': len([e for e in asset_entries if e]), 'generated_outside_sidecars_removed': len(cleanup), 'push': 'NOT_RUN', 'real_runtime_host_integration': 'PENDING_00', 'human_listening': 'NOT_RUN'}


if __name__ == '__main__':
    print(json.dumps(verify(), ensure_ascii=False, indent=2))
