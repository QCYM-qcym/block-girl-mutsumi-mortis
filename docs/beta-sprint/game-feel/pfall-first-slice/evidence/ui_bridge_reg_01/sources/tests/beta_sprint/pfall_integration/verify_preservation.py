"""Append-only check of bootstrap source, immutable packages and art inventories."""
from pathlib import Path
import json,hashlib,sys,subprocess
from datetime import datetime,timezone

root=Path(__file__).resolve().parents[3]
baseline=json.loads((root/'docs/beta-sprint/game-feel/BASELINE.json').read_text(encoding='utf-8-sig'))
output=root/'docs/beta-sprint/game-feel/pfall-first-slice'/sys.argv[1]
if output.exists(): raise SystemExit('Refusing to overwrite prior preservation evidence')
errors=[]
counts={}
runtime_delivery=sys.argv[2] if len(sys.argv)>2 else None
runtime_paths=set()
if runtime_delivery:
    runtime_paths=set(subprocess.check_output(['git','-C',str(root),'diff','--name-only','2938d6e534f5b596bb320ce79d72b69f5923f3cd',runtime_delivery,'--','foundation'],text=True).splitlines())
for group,entries in baseline['groups'].items():
    counts[group]=len(entries)
    for row in entries:
        path=Path(row['path'])
        if not path.is_file(): errors.append({'group':group,'path':str(path),'problem':'missing'});continue
        with path.open('rb') as stream: actual=hashlib.file_digest(stream,'sha256').hexdigest()
        relative=path.relative_to(root).as_posix() if path.is_relative_to(root) else None
        if group=='integration_production' and relative in runtime_paths:
            expected=subprocess.check_output(['git','-C',str(root),'rev-parse',runtime_delivery+':'+relative],text=True).strip()
            actual_blob=subprocess.check_output(['git','-C',str(root),'hash-object','--path='+relative,str(path)],text=True).strip()
            if actual_blob!=expected: errors.append({'group':group,'path':str(path),'problem':'authorized Runtime delivery differs','delivery':runtime_delivery})
        elif path.stat().st_size!=row['bytes'] or actual!=row['sha256']:
            errors.append({'group':group,'path':str(path),'problem':'bytes/hash changed','actual':actual})
for frozen in baseline['full_member_roots']:
    actual={p.as_posix() for p in Path(frozen['path']).rglob('*') if p.is_file()}
    expected=set(frozen['paths'])
    if actual!=expected:
        errors.append({'path':frozen['path'],'problem':'QA membership changed','added':sorted(actual-expected),'missing':sorted(expected-actual)})
report={'captured_utc':datetime.now(timezone.utc).isoformat(),'baseline':baseline['integration_baseline'],'checks':sum(counts.values()),'groups':counts,'failures':errors,'authorized_runtime_delivery':runtime_delivery,'runtime_paths':sorted(runtime_paths),'scope':'Existing inventory bytes; optional exact authorized Runtime Git blobs; additive lab files allowed; no gameplay PASS'}
output.parent.mkdir(parents=True,exist_ok=True)
output.write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps(report,ensure_ascii=False))
raise SystemExit(1 if errors else 0)
