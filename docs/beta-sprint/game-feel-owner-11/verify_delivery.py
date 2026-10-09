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
    for name, checks in [('policy_final_02', 63), ('director_final_01', 48), ('settings_final_02', 10)]:
        folder = ROOT / 'tests/beta_sprint/game_feel_owner_11/evidence' / name
        report = json.loads((folder / 'process.json').read_text(encoding='utf-8-sig'))
        assert report['status'] == 'PASS' and report['checks'] == checks and not report['source_drift'], name
        assert all(sha(ROOT / rel) == value for rel, value in report['source_sha256'].items()), ('FINAL_SOURCE_BINDING_DRIFT', name)
        binding.append({'case': name, 'checks': checks, 'process_sha256': sha(folder / 'process.json')})
    metrics = json.loads((ROOT / 'tests/beta_sprint/game_feel_owner_11/assets/pcm_metrics_final.json').read_text())
    assert metrics['status'] == 'PASS' and metrics['asset_count'] == 18
    cleanup = json.loads((ROOT / 'docs/beta-sprint/game-feel-owner-11/GENERATED_SIDECAR_CLEANUP.json').read_text(encoding='utf-8-sig'))
    assert all(not (ROOT / row['path']).exists() for row in cleanup)
    return {'status': 'PASS', 'head': git('rev-parse', 'HEAD').decode().strip(), 'branch': git('branch', '--show-current').decode().strip(), 'dirty': git('status', '--porcelain').decode('utf-8').splitlines(), 'baseline': BASELINE, 'baseline_byte_identical_files': len(rows), 'outside_owner_changes': [], 'final_source_bindings': binding, 'checks': 121, 'actual_audio_assets': 18, 'generated_outside_sidecars_removed': len(cleanup), 'push': 'NOT_RUN', 'real_runtime_host_integration': 'PENDING_00', 'human_listening': 'NOT_RUN'}


if __name__ == '__main__':
    print(json.dumps(verify(), ensure_ascii=False, indent=2))
