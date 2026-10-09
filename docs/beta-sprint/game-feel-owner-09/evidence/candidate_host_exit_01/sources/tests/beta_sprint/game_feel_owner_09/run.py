"""Append-only Owner09 evidence runner; one isolated Windows profile per process."""
from pathlib import Path
import os, sys, json, hashlib, subprocess, datetime

root = Path(__file__).resolve().parents[3]
case = sys.argv[1]
if not case.replace('_', '').isalnum():
    raise SystemExit('Use a new alphanumeric case name')
out = root / 'docs/beta-sprint/game-feel-owner-09/evidence' / case
out.mkdir(parents=True, exist_ok=False)
profile = out / 'profile'
profile.mkdir()
engine = Path('D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
env = os.environ.copy()
env['APPDATA'] = str(profile / 'Roaming')
env['LOCALAPPDATA'] = str(profile / 'Local')
Path(env['APPDATA']).mkdir()
Path(env['LOCALAPPDATA']).mkdir()
def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()
paths = subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', 'foundation', 'experiments/game_feel_01/maps', 'tests/beta_sprint/game_feel_owner_09', 'tests/foundation/level/baker_fixture.gd'], cwd=root).decode().splitlines()
sources = {p: digest(root / p) for p in sorted(set(paths))}
# Retain exact WIP Owner sources, including the RED input, not just a final hash.
for name in paths:
    if name.startswith(('experiments/game_feel_01/maps/', 'tests/beta_sprint/game_feel_owner_09/')):
        dest = out / 'sources' / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes((root / name).read_bytes())
script = sys.argv[2] if len(sys.argv)>2 else 'validate_maps.gd'
if script not in ['validate_maps.gd','validate_exit.gd']:
    raise SystemExit('Unknown Owner09 test script')
args = [str(engine), '--headless', '--path', str(root), '--script', 'res://tests/beta_sprint/game_feel_owner_09/'+script, '--', '--evidence='+out.as_posix(), '--profile='+profile.as_posix()]
record = {'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip(), 'dirty': subprocess.check_output(['git', 'status', '--porcelain'], cwd=root).decode(), 'sources_sha256': sources, 'engine_sha256': digest(engine), 'arguments': args, 'profile_environment': {k: env[k] for k in ['APPDATA','LOCALAPPDATA']}, 'started_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'doubles': []}
with (out/'stdout.log').open('wb') as stdout, (out/'stderr.log').open('wb') as stderr:
    process = subprocess.Popen(args, cwd=root, env=env, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW)
    record['pid'] = process.pid
    try:
        record['exit_code'] = process.wait(timeout=60)
    except subprocess.TimeoutExpired:
        process.kill(); process.wait(); record['exit_code'] = 'TIMEOUT'
record['finished_utc'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
record['source_drift'] = [p for p, sha in sources.items() if digest(root/p) != sha]
report_file = out/'report.json'
report = json.loads(report_file.read_text(encoding='utf-8')) if report_file.exists() else {}
record['checks'] = report.get('checks', 0)
record['failures'] = report.get('failures', ['missing report / parser or dependency failure'])
record['status'] = 'PASS' if record['exit_code'] == 0 and record['checks'] > 0 and not record['failures'] and not record['source_drift'] and not (out/'stderr.log').read_bytes() else 'FAILED'
(out/'process.json').write_bytes((json.dumps(record, indent=2, ensure_ascii=False)+'\n').encode())
print(case, record['status'], record['checks'], record['failures'], 'PID', process.pid)
print((out/'stderr.log').read_text(encoding='utf-8'))
sys.exit(0 if record['status']=='PASS' else 1)
