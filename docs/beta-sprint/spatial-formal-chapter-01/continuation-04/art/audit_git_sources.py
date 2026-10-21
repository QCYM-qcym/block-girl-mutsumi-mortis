"""Read local reachable Git provenance beyond exact export filenames; JSON only."""
from pathlib import Path
import hashlib
import json
import re
import subprocess
import sys
from datetime import datetime, timezone

REPO = Path(__file__).resolve().parents[5]
DEST = Path(sys.argv[1]).resolve()
if DEST.exists() or DEST.parent != Path('E:/godot/beta-sprint-builds/spatial_formal_cont04_art_20261021_02'):
    raise ValueError('Expected a new evidence file in this round evidence directory')

def git(*args):
    p = subprocess.run(['git', '-C', str(REPO), *args], capture_output=True, check=True)
    return p.stdout

rows = git('rev-list', '--objects', '--all').decode().splitlines()
pattern = re.compile(r'build_boards|game_art_mechanics|design/greybox|face_lock|asset_manifest', re.I)
matched = [r.split(' ', 1) for r in rows if ' ' in r and pattern.search(r.split(' ', 1)[1])]
if len(rows) > 20000 or len(matched) > 400:
    raise RuntimeError('Git search budget exceeded')
images = []
for oid, path in matched:
    if Path(path).suffix.lower() in {'.png', '.svg'}:
        size = int(git('cat-file', '-s', oid))
        if size > 16 * 1024 * 1024:
            raise RuntimeError('Git candidate size budget exceeded')
        data = git('cat-file', 'blob', oid)
        images.append({'oid': oid, 'path': path, 'bytes': size, 'sha256': hashlib.sha256(data).hexdigest()})
history_paths = ['docs/beta-sprint/spatial-puzzle-batch-01/art/continuation_02/ORIGINAL_PACKAGE_SHA256.json',
                 'docs/beta-sprint/spatial-puzzle-batch-01/art/acceptance_01/SCOPE_DEVIATION.md']
manifest_commit = 'a851a9189825d2500f94aa275d079e7d63756879'
manifest_data = git('show', manifest_commit + ':' + history_paths[0])
obj = {'checked_utc': datetime.now(timezone.utc).isoformat(), 'repo': str(REPO),
       'budget': {'reachable_objects': 20000, 'qualified_objects': 400, 'candidate_bytes': 16777216},
       'reachable_object_count': len(rows), 'qualified_object_count': len(matched), 'qualified_objects': matched,
       'image_candidates': images,
       'related_commit_search': git('log', '--all', '--format=%H %s', '--regexp-ignore-case',
                                     r'--grep=mechanics.*art\|art.*mechanics\|face.lock\|spatial.*art').decode(),
       'related_runtime_commit': {'sha': '697a31ed85e29b1d37ec882e712d323751bd90a1',
                                  'paths': git('diff-tree', '--no-commit-id', '--name-only', '-r', '697a31ed85e29b1d37ec882e712d323751bd90a1').decode().splitlines()},
       'manifest_history': git('log', '--all', '--format=%H %ad %s', '--date=iso-strict', '--', *history_paths).decode(),
       'committed_manifest': {'commit': manifest_commit, 'path': history_paths[0], 'sha256': hashlib.sha256(manifest_data).hexdigest(),
                              'entry_count': len(json.loads(manifest_data)), 'trust_limit': 'Post-incident audit commit; not an independent pre-incident immutable anchor'},
       'pinned_runtime_snapshot': {'sha': 'd9716389f58e8488aeaacd7d87b249882b10c988',
                                  'qualified_paths': [r for r in git('ls-tree', '-r', '--name-only', 'd9716389f58e8488aeaacd7d87b249882b10c988').decode().splitlines() if pattern.search(r)]},
       'limits': ['Local reachable history only', 'No unreachable blob scan or remote ref fetch', 'Related image candidate names only; not arbitrary-name Git blob hash search']}
DEST.write_text(json.dumps(obj, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps({'reachable': len(rows), 'qualified': len(matched), 'image_candidates': len(images), 'committed_manifest': obj['committed_manifest']}, indent=2))
