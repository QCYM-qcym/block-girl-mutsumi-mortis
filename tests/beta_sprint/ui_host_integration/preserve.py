"""Append-only preservation audit; exact authorized Runtime and single shared entry exception."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess,sys
root=Path(__file__).resolve().parents[3]
out=root/'docs/beta-sprint/game-feel/ui-host-01'/sys.argv[1]
if out.exists(): raise SystemExit('Never overwrite evidence')
git=lambda *a: subprocess.check_output(['git','-C',str(root),*a])
baseline=json.loads((root/'docs/beta-sprint/game-feel/BASELINE.json').read_text(encoding='utf-8-sig'))
runtime='26387d6c34a869ad7035ee13ee77d8d5c24d796a'
runtime_paths=set(git('diff','--name-only','2938d6e534f5b596bb320ce79d72b69f5923f3cd',runtime,'--','foundation').decode().splitlines())
errors=[];checks=0;groups={}
for group,rows in baseline['groups'].items():
    groups[group]=len(rows)
    for row in rows:
        checks+=1;p=Path(row['path'])
        if not p.is_file(): errors.append({'path':str(p),'problem':'missing'});continue
        relative=p.relative_to(root).as_posix() if p.is_relative_to(root) else None
        if group=='integration_production' and relative in runtime_paths:
            ok=git('hash-object','--path='+relative,str(p)).strip()==git('rev-parse',runtime+':'+relative).strip()
        elif group=='integration_production' and relative=='project.godot':
            previous=git('show','4b90a4bdb102550ad99cb3695fd49e394c1c447c:project.godot').decode('utf-8-sig')
            expected=previous.replace('res://game/shell/game_shell.tscn','res://game/shell/game_feel_shell.tscn')
            ok=p.read_text(encoding='utf-8-sig').replace('\r\n','\n')==expected.replace('\r\n','\n')
        else:
            with p.open('rb') as stream: digest=hashlib.file_digest(stream,'sha256').hexdigest()
            ok=p.stat().st_size==row['bytes'] and digest==row['sha256']
        if not ok: errors.append({'group':group,'path':str(p),'problem':'unauthorized source/hash change'})
for frozen in baseline['full_member_roots']:
    checks+=1
    actual={p.as_posix() for p in Path(frozen['path']).rglob('*') if p.is_file()}
    if actual!=set(frozen['paths']): errors.append({'path':frozen['path'],'problem':'old QA membership changed'})
for directory,delivery in [('game/feel/ui','6d3bf4b7f5120b44dad4790b657a4be953dd4954'),('game/feel/audio','7363e9e7d7849018cc456ae866a60e23472591d6')]:
    for relative in git('ls-tree','-r','--name-only',delivery,'--',directory).decode().splitlines():
        checks+=1
        if git('hash-object','--path='+relative,str(root/relative)).strip()!=git('rev-parse',delivery+':'+relative).strip(): errors.append({'path':relative,'problem':'Owner production drift'})
contract=root/'docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md'
checks+=1
if hashlib.sha256(contract.read_bytes()).hexdigest()!='6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de': errors.append({'problem':'contract drift'})
core=Path('E:/godot/beta-sprint-builds/beta_pfall_core_20261010_01')
identity=json.loads((core/'BUILD_IDENTITY.json').read_text(encoding='utf-8-sig'))
for row in identity['files']:
    checks+=1
    if hashlib.sha256((core/row['path']).read_bytes()).hexdigest()!=row['sha256']: errors.append({'path':row['path'],'problem':'frozen Core package drift'})
checks+=1
with core.with_suffix('.zip').open('rb') as stream: digest=hashlib.file_digest(stream,'sha256').hexdigest()
if digest!='a5e9daf415c2c89a17c7cc56bab932b847b8fee6cef3f2532c9b61e980863024': errors.append({'problem':'frozen Core ZIP drift'})
report={'checks':checks,'failures':errors,'groups':groups,'created_utc':datetime.now(timezone.utc).isoformat(),'authorized_prior_runtime':runtime,'authorized_current_change':'00 shared Main Scene entry only; additive00 Host and Presenter compatibility extension; no original five-level/SaveStore/Art edits','contract':'UNCHANGED','old_core_build':'UNCHANGED'}
out.write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps({'checks':checks,'failures':errors},ensure_ascii=False));raise SystemExit(1 if errors else 0)
