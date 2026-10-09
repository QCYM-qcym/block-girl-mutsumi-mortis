"""Exact 01 Git sources in an Owner-local disposable project; no merge/shared writes."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tarfile
import io
from run_validation import ROOT, GODOT

if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
DEPENDENCY = '26387d6c34a869ad7035ee13ee77d8d5c24d796a'
name = sys.argv[1]
if not name.replace('_', '').isalnum():
    raise SystemExit('simple fresh evidence name required')
evidence = ROOT / 'tests/beta_sprint/game_feel_owner_11/evidence' / name
evidence.mkdir(parents=True, exist_ok=False)
execution = evidence / 'execution_project'
execution.mkdir()
profile = evidence / 'profile'
profile.mkdir()
sources = {}
raw = subprocess.check_output(['git', 'archive', DEPENDENCY, 'foundation', 'tests/foundation', 'tests/beta_sprint/game_feel_owner_01/fixtures.gd'], cwd=ROOT)
with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
    for member in archive:
        if not member.isfile() or not member.name.endswith(('.gd', '.gd.uid')):
            continue
        target = execution / member.name
        assert target.resolve().is_relative_to(execution.resolve())
        target.parent.mkdir(parents=True, exist_ok=True)
        data = archive.extractfile(member).read()
        target.write_bytes(data)
        sources[member.name] = hashlib.sha256(data).hexdigest()
own = ['game/feel/audio/event_policy.gd', 'tests/beta_sprint/game_feel_owner_11/test_native_shapes.gd']
for rel in own:
    target = execution / rel
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes((ROOT / rel).read_bytes())
    sources[rel] = hashlib.sha256(target.read_bytes()).hexdigest()
(execution / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Owner11NativeAudioDTO"\nconfig/features=PackedStringArray("4.7")\n', encoding='utf-8', newline='\n')
sources['project.godot'] = hashlib.sha256((execution / 'project.godot').read_bytes()).hexdigest()
env = os.environ.copy()
env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile), XDG_DATA_HOME=str(profile))
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
dirty = subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines()
command = [str(GODOT), '--path', str(execution), '--headless', '--script', 'res://tests/beta_sprint/game_feel_owner_11/test_native_shapes.gd', '--', '--evidence-dir=' + str(evidence)]
with (evidence / 'stdout.log').open('wb') as stdout, (evidence / 'stderr.log').open('wb') as stderr:
    child = subprocess.Popen(command, cwd=execution, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0)
    try:
        exit_code = child.wait(timeout=60)
    except subprocess.TimeoutExpired:
        child.kill()
        exit_code = child.wait()
result = evidence / 'native_shapes.json'
report = json.loads(result.read_text(encoding='utf-8-sig')) if result.exists() else {}
drift = any(hashlib.sha256((execution / rel).read_bytes()).hexdigest() != value for rel, value in sources.items())
own_drift = any(hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() != sources[rel] for rel in own)
out = (evidence / 'stdout.log').read_text(encoding='utf-8', errors='replace')
err = (evidence / 'stderr.log').read_text(encoding='utf-8', errors='replace')
passed = exit_code == 0 and report.get('checks', 0) > 0 and not report.get('failures', []) and not drift and not own_drift and not any(s in out + err for s in ['SCRIPT ERROR', 'ERROR:', 'FAIL:'])
passed = passed and str(Path(report.get('user_data_dir', '')).resolve()).casefold().startswith(str(profile.resolve()).casefold() + os.sep)
metadata = {'status': 'PASS' if passed else 'FAIL', 'head': head, 'dirty': dirty, 'runtime_dependency_commit': DEPENDENCY, 'command': command, 'pid': child.pid, 'exit_code': exit_code, 'checks': report.get('checks'), 'failures': report.get('failures'), 'execution_source_sha256': sources, 'source_drift': drift or own_drift, 'engine_sha256': hashlib.sha256(GODOT.read_bytes()).hexdigest(), 'runner_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(), 'fixture_kind': 'NATIVE_RUNTIME_EVENT_API_COMPATIBILITY', 'doubles': [], 'motion_playback': 'NOT_RUN', 'graphical_gameplay': 'NOT_RUN', 'stderr_bytes': (evidence / 'stderr.log').stat().st_size, 'user_data_dir': report.get('user_data_dir')}
(evidence / 'process.json').write_text(json.dumps(metadata, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps({k: metadata[k] for k in ['status', 'checks', 'pid', 'exit_code', 'stderr_bytes', 'source_drift']}))
print(out[-2000:] + err[-2000:])
sys.exit(0 if passed else 1)
