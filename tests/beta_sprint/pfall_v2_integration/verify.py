"""Read-only package manifest and previous frozen UI package preservation."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess,sys
root=Path(__file__).resolve().parents[3]
target=None if sys.argv[1]=='-' else Path(sys.argv[1]).resolve()
out=root/'docs/beta-sprint/game-feel/pfall-v2-01'/sys.argv[2]
if out.exists():raise SystemExit('Never overwrite verification evidence')
checks=0;errors=[];packages=[]
def digest(p):
    with p.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
def check(ok,label):
    global checks
    checks+=1
    if not ok:errors.append(label)
def verify_package(path,expected_zip=None,source_blobs=False):
    identity=json.loads((path/'BUILD_IDENTITY.json').read_text(encoding='utf-8-sig'))
    head=identity['integration_commit']
    for row in identity['files']+identity.get('generated_files',[]):
        file=path/row['path']
        check(file.is_file() and file.stat().st_size==row['bytes'] and digest(file)==row['sha256'],'immutable manifest '+str(file))
        if source_blobs and row.get('git_blob'):
            relative=row['path'].removeprefix('project/')
            blob=subprocess.check_output(['git','-C',str(root),'rev-parse',head+':'+relative],text=True).strip()
            check(blob==row['git_blob'],'source commit blob '+relative)
            actual_blob=subprocess.check_output(['git','-C',str(root),'hash-object','--no-filters',str(file)],text=True).strip()
            check(actual_blob==blob,'actual package bytes match source commit '+relative)
    sha=digest(path.with_suffix('.zip'))
    if expected_zip:check(sha==expected_zip,'frozen archive '+str(path))
    # Snapshot all prior package files, including launcher/identity and any profile files.
    snapshot={p.relative_to(path).as_posix():digest(p) for p in path.rglob('*') if p.is_file()}
    packages.append({'path':str(path),'integration_commit':head,'source_manifest_files':len(identity['files']),'physical_files':len(snapshot),'archive_sha256':sha,'snapshot':snapshot})
verify_package(Path('E:/godot/beta-sprint-builds/beta_game_feel_ui_host_20261010_04'),'fa11b8aafaa88f8eef3fae6fad73e752a5a7fb40af974767d32da06651eeeb81')
before=root/'docs/beta-sprint/game-feel/pfall-v2-01/PRESERVATION_UI_01.json'
if target:
    old=json.loads(before.read_text(encoding='utf-8-sig'))['packages'][0]
    check(packages[0]['snapshot']==old['snapshot'],'prior UI Build full membership and file hashes unchanged')
    verify_package(target,source_blobs=True)
    identity=json.loads((target/'BUILD_IDENTITY.json').read_text(encoding='utf-8'))
    check((target/'play.ps1').is_file() and (target/'project/experiments/game_feel_01/host/core_lab.tscn').is_file(),'real Build launcher and scene exist')
    check(subprocess.run(['git','-C',str(root),'merge-base','--is-ancestor',identity['integration_commit'],'HEAD']).returncode==0,'new Build source is an ancestor of current integration')
report={'checks':checks,'failures':errors,'packages':packages,'created_utc':datetime.now(timezone.utc).isoformat()}
out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':checks,'failures':errors,'packages':[{k:v for k,v in p.items() if k!='snapshot'} for p in packages]},ensure_ascii=False))
raise SystemExit(1 if errors else 0)
