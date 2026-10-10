"""Read-only frozen-source/package audit; explicit Owner Replay exception only."""
from pathlib import Path
import hashlib,json,subprocess,sys
from datetime import datetime,timezone
ROOT=Path(__file__).resolve().parents[3]
name,owner=sys.argv[1:3]
out=ROOT/'docs/beta-sprint/game-feel/graphical-bridge-02'/name
if out.exists():raise SystemExit('Never overwrite evidence')
git=lambda *args:subprocess.check_output(['git','-C',str(ROOT),*args])
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base='fcee3299020caf99e396bbb5659d6f630b202f0f'
checks=0;failures=[]
def check(ok,label):
    global checks
    checks+=1
    if not ok:failures.append(label)
foundation=git('diff','--name-only',base,'HEAD','--','foundation').decode().splitlines()
check(foundation==['foundation/parity/trace_replayer.gd'],'sole authorized Foundation Replay port')
check(git('hash-object','--path=foundation/parity/trace_replayer.gd',str(ROOT/'foundation/parity/trace_replayer.gd')).strip()==git('rev-parse',owner+':foundation/parity/trace_replayer.gd').strip(),'exact delivered01 Replay implementation')
for prefix,sha in [('game/feel/animation/fall_landing','4781dfcf16757ccbde13e54ee449f1cf00174944'),('game/feel/animation/edge_recoil','285896e7193c53511ad8878d21b70825c983fb46')]:
    # The baseline already contains approved exact Owner bytes. Validate all
    # listed source against baseline without copying or altering Owner files.
    for relative in git('ls-tree','-r','--name-only',base,'--',prefix).decode().splitlines():
        check(git('hash-object','--path='+relative,str(ROOT/relative)).strip()==git('rev-parse',base+':'+relative).strip(),'frozen motion '+relative)
for prefix in ['assets','prototype','game/levels','game/content','game/shell/save_store.gd']:
    check(not git('diff','--name-only',base,'HEAD','--',prefix).strip(),'unchanged '+prefix)
check(digest(ROOT/'docs/beta-sprint/game-feel/GAME_FEEL_CONTRACT.md')=='6224f8cd364f98da41822eabe7ba2973fa2db01d030373e7b3e94d69f35f23de','frozen shared contract')
archives={'beta_pfall_core_20261010_01':'a5e9daf415c2c89a17c7cc56bab932b847b8fee6cef3f2532c9b61e980863024','beta_pfall_v2_20261010_01':'b25f77c48b8e52f7bccd867ca64af6a3373fcbd57975bd069061d97760a8dfa0','beta_game_feel_ui_host_20261010_04':'fa11b8aafaa88f8eef3fae6fad73e752a5a7fb40af974767d32da06651eeeb81','beta_five_level_3d_20261009_01':'409cb38c4b43a1847ed0857e019265fb7ed26eec90fea4691760e2905a1c27c1','beta_game_feel_full_slice_20261010_01':'a0ae72d45582d578753ff0e0722bd49bae3fbf85b9f87679050581c24ac2efcb'}
for folder,expected in archives.items():
    path=Path('E:/godot/beta-sprint-builds')/folder
    check(digest(path.with_suffix('.zip'))==expected,'old QA ZIP '+folder)
    identity=path/'BUILD_IDENTITY.json'
    if identity.is_file():
        rows=json.loads(identity.read_text(encoding='utf-8-sig')).get('files',[])
        for row in rows:check(digest(path/row['path'])==row['sha256'],'old QA manifest '+folder+'/'+row['path'])
baseline=json.loads((ROOT/'docs/beta-sprint/game-feel/BASELINE.json').read_text(encoding='utf-8-sig'))
for rows in baseline['groups'].values():
    for row in rows:
        p=Path(row['path'])
        if not str(p).replace('\\','/').startswith('E:/godot/beta-sprint-builds/'):continue
        check(p.exists() and p.stat().st_size==row['bytes'] and digest(p)==row['sha256'],'frozen historical QA member '+str(p))
for group in baseline['full_member_roots']:
    check({p.as_posix() for p in Path(group['path']).rglob('*') if p.is_file()}==set(group['paths']),'frozen QA membership '+group['path'])
report={'checks':checks,'failures':failures,'owner_replay':owner,'source':git('rev-parse','HEAD').decode().strip(),'baseline':base,'old_archives':archives,'contract':'UNCHANGED','qa_source':'UNCHANGED','created_utc':datetime.now(timezone.utc).isoformat()}
out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':checks,'failures':failures},ensure_ascii=False))
raise SystemExit(1 if failures else 0)
