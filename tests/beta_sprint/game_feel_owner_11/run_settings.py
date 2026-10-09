"""Existing SaveStore writer/reader with distinct PIDs and a single isolated profile."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
from run_validation import ROOT, GODOT, inventory

name = sys.argv[1]
if not name.replace('_', '').isalnum():
    raise SystemExit('simple fresh evidence name required')
evidence = ROOT / 'tests/beta_sprint/game_feel_owner_11/evidence' / name
evidence.mkdir(parents=True, exist_ok=False)
profile = evidence / 'profile'
profile.mkdir()
env = os.environ.copy()
env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile), XDG_DATA_HOME=str(profile))
sources = inventory('director')
for rel in ['game/shell/save_store.gd', 'game/shell/settings.gd', 'tests/beta_sprint/game_feel_owner_11/test_settings_persistence.gd', 'tests/beta_sprint/game_feel_owner_11/run_settings.py']:
    sources[rel] = hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
rows = []
for mode in ['write', 'read']:
    command = [str(GODOT), '--path', str(ROOT), '--headless', '--script', 'res://tests/beta_sprint/game_feel_owner_11/test_settings_persistence.gd', '--', '--mode=' + mode, '--evidence-dir=' + str(evidence)]
    with (evidence / (mode + '.stdout.log')).open('wb') as stdout, (evidence / (mode + '.stderr.log')).open('wb') as stderr:
        child = subprocess.Popen(command, env=env, cwd=ROOT, stdout=stdout, stderr=stderr, creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0)
        try:
            code = child.wait(30)
        except subprocess.TimeoutExpired:
            child.kill()
            code = child.wait()
    result = evidence / ('settings_' + mode + '.json')
    row = {'mode': mode, 'pid': child.pid, 'exit_code': code, 'command': command, 'report': json.loads(result.read_text(encoding='utf-8-sig')) if result.exists() else None}
    rows.append(row)
    print((evidence / (mode + '.stdout.log')).read_text(errors='replace')[-1000:])
    print((evidence / (mode + '.stderr.log')).read_text(errors='replace')[-1000:])
    if code:
        break
fresh = inventory('director')
fresh.update({rel: hashlib.sha256((ROOT / rel).read_bytes()).hexdigest() for rel in sources if rel not in fresh})
passed = len(rows) == 2 and all(r['exit_code'] == 0 and r['report'] and not r['report']['failures'] and r['report']['checks'] > 0 and str(Path(r['report']['user_data_dir']).resolve()).casefold().startswith(str(profile.resolve()).casefold() + os.sep) for r in rows)
passed = passed and rows[0]['pid'] != rows[1]['pid'] and rows[0]['report']['save_sha256'] == rows[1]['report']['save_sha256'] and sources == fresh
payload = {'status': 'PASS' if passed else 'FAIL', 'head': head, 'dirty': subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True).splitlines(), 'source_sha256': sources, 'source_drift': sources != fresh, 'engine_sha256': hashlib.sha256(GODOT.read_bytes()).hexdigest(), 'fixture_kind': 'EXISTING_SAVE_API_AUDIO_CONTRACT', 'shell_ui_integration': 'PENDING_00', 'checks': sum(r['report']['checks'] for r in rows if r['report']), 'rows': rows}
(evidence / 'process.json').write_text(json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'status': payload['status'], 'checks': payload['checks'], 'pids': [r['pid'] for r in rows]}))
sys.exit(0 if passed else 1)
