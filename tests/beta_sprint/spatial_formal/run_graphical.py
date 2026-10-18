"""Run one isolated real-rendering process without reusing any QA save directory."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time

root = Path(__file__).resolve().parents[3]
out = Path(sys.argv[1]).resolve()
out.mkdir(parents=True, exist_ok=False)
engine = Path('D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
env = os.environ.copy()
for key in ['APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP']:
    path = out / 'profile' / key
    path.mkdir(parents=True)
    env[key] = str(path)
paths = [p for folder in ['game', 'foundation', 'experiments', 'tests/beta_sprint/spatial_formal']
         for p in (root / folder).rglob('*') if p.is_file() and p.suffix in ['.gd', '.tscn', '.tres', '.json']]
hashes = {p.relative_to(root).as_posix(): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}
(out / 'SOURCE_SHA256.json').write_text(json.dumps(hashes, indent=2), encoding='utf-8')
script = sys.argv[2] if len(sys.argv) > 2 else 'graphical.gd'
args = [str(engine), '--path', str(root), '--position', '30000,30000',
        '--script', 'res://tests/beta_sprint/spatial_formal/' + script, '--',
        '--phase=fresh', '--shell-save=user://beta_sprint/spatial_formal/graphical.json',
        '--evidence-dir=' + out.as_posix()]
args += sys.argv[3:]
startup = subprocess.STARTUPINFO()
startup.dwFlags = subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
record = {'args': args, 'engine_sha256': hashlib.sha256(engine.read_bytes()).hexdigest(),
          'source_head': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD']).decode().strip(),
          'human_qa': 'NOT_RUN', 'started': time.time()}
with (out / 'stdout.log').open('wb') as stdout, (out / 'stderr.log').open('wb') as stderr:
    process = subprocess.Popen(args, env=env, stdout=stdout, stderr=stderr, startupinfo=startup)
    record['pid'] = process.pid
    (out / 'RUNNING.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
    try:
        record['exit_code'] = process.wait(timeout=240)
    except subprocess.TimeoutExpired:
        process.kill()
        process.wait()
        record['exit_code'] = 'TIMEOUT_OWNED_PROCESS_ONLY'
record['elapsed_seconds'] = time.time() - record['started']
record['stderr_bytes'] = (out / 'stderr.log').stat().st_size
record['source_drift'] = [p for p, digest in hashes.items() if hashlib.sha256((root / p).read_bytes()).hexdigest() != digest]
(out / 'PROCESS.json').write_text(json.dumps(record, indent=2), encoding='utf-8')
print(json.dumps(record, ensure_ascii=False))
sys.exit(0 if record['exit_code'] == 0 and not record['source_drift'] else 1)
