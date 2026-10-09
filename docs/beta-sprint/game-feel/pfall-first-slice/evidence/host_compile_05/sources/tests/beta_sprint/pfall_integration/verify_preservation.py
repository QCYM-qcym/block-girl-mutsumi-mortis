"""Append-only check of bootstrap source, immutable packages and art inventories."""
from pathlib import Path
import json,hashlib,sys
from datetime import datetime,timezone

root=Path(__file__).resolve().parents[3]
baseline=json.loads((root/'docs/beta-sprint/game-feel/BASELINE.json').read_text(encoding='utf-8-sig'))
output=root/'docs/beta-sprint/game-feel/pfall-first-slice'/sys.argv[1]
if output.exists(): raise SystemExit('Refusing to overwrite prior preservation evidence')
errors=[]
counts={}
for group,entries in baseline['groups'].items():
    counts[group]=len(entries)
    for row in entries:
        path=Path(row['path'])
        if not path.is_file(): errors.append({'group':group,'path':str(path),'problem':'missing'});continue
        with path.open('rb') as stream: actual=hashlib.file_digest(stream,'sha256').hexdigest()
        if path.stat().st_size!=row['bytes'] or actual!=row['sha256']:
            errors.append({'group':group,'path':str(path),'problem':'bytes/hash changed','actual':actual})
for frozen in baseline['full_member_roots']:
    actual={p.as_posix() for p in Path(frozen['path']).rglob('*') if p.is_file()}
    expected=set(frozen['paths'])
    if actual!=expected:
        errors.append({'path':frozen['path'],'problem':'QA membership changed','added':sorted(actual-expected),'missing':sorted(expected-actual)})
report={'captured_utc':datetime.now(timezone.utc).isoformat(),'baseline':baseline['integration_baseline'],'checks':sum(counts.values()),'groups':counts,'failures':errors,'scope':'Existing inventory bytes only; additive lab files allowed; no gameplay PASS'}
output.parent.mkdir(parents=True,exist_ok=True)
output.write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(report,ensure_ascii=False))
raise SystemExit(1 if errors else 0)
