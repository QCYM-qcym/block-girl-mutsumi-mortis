"""Fresh append-only evidence for exact recipe reproduction and actual PCM checks."""
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import platform
import subprocess
import sys
import numpy as np
from validate_assets import ROOT, ASSETS, validate


def digest_files():
    files = list((ASSETS / 'exports').glob('*.wav'))
    files += list((ASSETS / 'source/pcm24').glob('*.wav'))
    files += [ASSETS / 'manifest.json', ASSETS / 'previews/asset_audition.wav']
    return {str(path.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(path.read_bytes()).hexdigest()
            for path in sorted(files)}


stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
evidence = Path(__file__).parent / ('evidence-' + stamp)
evidence.mkdir(exist_ok=False)
head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
dirty = subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT, text=True)
command = [sys.executable, str(ASSETS / 'source/synthesize.py')]
before = digest_files()
render = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
(evidence / 'render.stdout.txt').write_text(render.stdout, encoding='utf-8')
(evidence / 'render.stderr.txt').write_text(render.stderr, encoding='utf-8')
assert render.returncode == 0, render.stderr
after = digest_files()
assert before == after, 'Render SHA differs from previous render'
metrics = validate()
(evidence / 'pcm_metrics.json').write_text(json.dumps(metrics, indent=2) + '\n', encoding='utf-8')
source_paths = [ASSETS / 'source/synthesize.py', ASSETS / 'source/score.json',
                Path(__file__), Path(__file__).parent / 'validate_assets.py']
metadata = dict(status='PASS', test_kind='DETERMINISTIC_ORIGINAL_ASSET_RENDER',
    timestamp_utc=stamp, execution_head=head, execution_dirty_porcelain=dirty,
    command=command, returncode=render.returncode, python=sys.version, numpy=np.__version__,
    platform=platform.platform(), rendered_file_count=len(after),
    source_sha256={str(p.relative_to(ROOT)).replace('\\', '/'): hashlib.sha256(p.read_bytes()).hexdigest() for p in source_paths},
    reproduced_sha256=after, authority='ASSET_ANALYSIS_ONLY',
    runtime=False, godot_execution=False, subjective_listening='NOT_RUN',
    doubles=[], initial_contract_preflight='Missing manifest before generation; artifact absence only, not behavioral RED')
(evidence / 'reproduction.json').write_text(json.dumps(metadata, indent=2) + '\n', encoding='utf-8')
print(json.dumps(dict(status='PASS', evidence_directory=str(evidence), identical_files=len(after),
    pcm_assets=metrics['asset_count'], crossfade_peak=metrics['crossfade_peak'], subjective_listening='NOT_RUN'), indent=2))
