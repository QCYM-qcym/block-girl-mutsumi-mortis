"""Read-only immutable QA/art verification; versioned Runtime changes audited separately."""
from pathlib import Path
import hashlib,json,subprocess,sys
from datetime import datetime,timezone

root=Path(__file__).resolve().parents[3]
output=root/'docs/beta-sprint/game-feel/forward-drop-01'/sys.argv[1]
if output.exists(): raise SystemExit('Evidence is append-only')
baseline=json.loads((root/'docs/beta-sprint/game-feel/BASELINE.json').read_text(encoding='utf-8-sig'))
old=json.loads((root/'docs/beta-sprint/game-feel/graphical-bridge-02/PRESERVATION_01.json').read_text(encoding='utf-8-sig'))
old['old_archives']['beta_pfall_yellow_target_20261010_01']='921b2c1bae7d9e8025ec47ca42a118530fe8dfee04969a2014121309141e961c'
checks=0;failures=[]
def check(ok,label):
    global checks
    checks+=1
    if not ok: failures.append(label)
def digest(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
groups={}
for name,rows in baseline['groups'].items():
    if name=='integration_production': continue
    groups[name]=len(rows)
    for row in rows:
        path=Path(row['path'])
        check(path.is_file() and digest(path)==row['sha256'],name+': '+str(path))
for spec in baseline['full_member_roots']:
    current={p.as_posix() for p in Path(spec['path']).rglob('*') if p.is_file()}
    check(current==set(spec['paths']),'immutable membership: '+spec['path'])
for name,sha in old['old_archives'].items():
    archive=Path('E:/godot/beta-sprint-builds')/(name+'.zip')
    check(archive.is_file() and digest(archive)==sha,'old QA archive: '+name)
    directory=archive.with_suffix('')
    identity=directory/('QA_BUILD_IDENTITY.json' if name=='beta_five_level_3d_20261009_01' else 'BUILD_IDENTITY.json')
    manifest=json.loads(identity.read_text(encoding='utf-8-sig'))
    for row in manifest.get('files',[]):
        relative=row.get('path')
        if not relative: continue
        path=directory/relative
        check(path.is_file() and digest(path)==row['sha256'],'old package file: '+str(path))
contract=root/'docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md'
check(digest(contract)=='6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de','frozen base contract')
report={'task':'PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01','checks':checks,'failures':failures,'groups':groups,'old_archives':old['old_archives'],'source':subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip(),'created_utc':datetime.now(timezone.utc).isoformat(),'scope':'Immutable old QA files/membership, approved art/source bindings and frozen contract. Authorized new Runtime/animation/map/host source changes are separately reviewed.'}
output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8',newline='\n')
print(json.dumps({'checks':checks,'failures':failures,'evidence':str(output)},ensure_ascii=False))
raise SystemExit(bool(failures))
