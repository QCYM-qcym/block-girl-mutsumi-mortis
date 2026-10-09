"""Exact ancestry/source review; no production mutation or repeated integration."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess,sys
root=Path(__file__).resolve().parents[3]
out=root/'docs/beta-sprint/game-feel/pfall-v2-01'/sys.argv[1]
if out.exists():raise SystemExit('Never overwrite evidence')
git=lambda *args:subprocess.check_output(['git','-C',str(root),*args])
head=git('rev-parse','HEAD').decode().strip()
MAP='e4bcdfc6459f587cb26c25494dd5b57b76ccdca4'
PREVIOUS='82a8a7dc85205e9391551f24267f35f5abe53393'
RUNTIME='26387d6c34a869ad7035ee13ee77d8d5c24d796a'
ANIMATION='4781dfcf16757ccbde13e54ee449f1cf00174944'
CONTRACT='2938d6e534f5b596bb320ce79d72b69f5923f3cd'
errors=[];checks=0;rows=[]
def check(ok,label):
    global checks
    checks+=1
    if not ok:errors.append(label)
for ancestor,descendant in [(PREVIOUS,MAP),(MAP,head),(RUNTIME,head),(ANIMATION,head),(CONTRACT,head)]:
    check(subprocess.run(['git','-C',str(root),'merge-base','--is-ancestor',ancestor,descendant]).returncode==0,'ancestry '+ancestor+' -> '+descendant)
delta=[p for p in git('diff','--name-only','-z',PREVIOUS,MAP).decode('utf-8').split('\0') if p]
production=[p for p in delta if not p.startswith(('docs/','tests/'))]
check(set(production)=={'experiments/game_feel_01/maps/map_a.json','experiments/game_feel_01/maps/map_b.json','experiments/game_feel_01/maps/map_factory.gd'},'09 exact three production changes only')
factory='experiments/game_feel_01/maps/map_factory.gd'
check(git('show',MAP+':'+factory).startswith(git('show',PREVIOUS+':'+factory).rstrip()),'legacy authoring/bake/read_spec prefix unchanged')
for letter in ['a','b']:
    p='experiments/game_feel_01/maps/map_'+letter+'.json'
    old=json.loads(git('show',PREVIOUS+':'+p));new=json.loads(git('show',MAP+':'+p))
    new.pop('opt_in_candidate')
    check(new==old,'all pre-existing map '+letter+' fields unchanged')
for delivery,directory in [(MAP,'experiments/game_feel_01/maps'),(RUNTIME,'foundation'),(ANIMATION,'game/feel/animation/fall_landing')]:
    for p in git('ls-tree','-r','--name-only',delivery,'--',directory).decode().splitlines():
        current=git('hash-object','--path='+p,str(root/p)).decode().strip()
        expected=git('rev-parse',delivery+':'+p).decode().strip()
        check(current==expected,'physical exact Owner blob '+p)
        rows.append({'path':p,'delivery':delivery,'git_blob':current,'sha256':hashlib.sha256((root/p).read_bytes()).hexdigest()})
check(git('rev-parse',CONTRACT+':foundation/level/level_baker.gd')==git('rev-parse',head+':foundation/level/level_baker.gd'),'single legacy Baker implementation unchanged; DATA/Codec opt-in supplies v2')
manifest=json.loads((root/'docs/beta-sprint/game-feel-owner-09/CANDIDATE_FILES_SHA256.json').read_text(encoding='utf-8-sig'))
for row in manifest['files']:
    path=root/row['path']
    check(path.is_file() and hashlib.sha256(path.read_bytes()).hexdigest()==row['sha256'],'09 delivery manifest '+row['path'])
report={'task':'PFALL_V2_MAP_RUNTIME_INTEGRATION_01','head':head,'checks':checks,'failures':errors,'production_delta':production,'all_changed_files':delta,'map':MAP,'previous_map_delta':PREVIOUS,'runtime':RUNTIME,'animation':ANIMATION,'contract':CONTRACT,'sources':rows,'duplicate_application':'NONE; all delivery commits already ancestors','production_changes_this_task':'NONE','integration_window':'existing window deliveries reused; no third production merge window','created_utc':datetime.now(timezone.utc).isoformat()}
out.parent.mkdir(parents=True,exist_ok=True);out.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'checks':checks,'failures':errors,'production_delta':production},ensure_ascii=False))
raise SystemExit(1 if errors else 0)
