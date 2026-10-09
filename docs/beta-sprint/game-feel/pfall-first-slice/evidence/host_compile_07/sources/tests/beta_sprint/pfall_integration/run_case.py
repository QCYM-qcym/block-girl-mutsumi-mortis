"""00 focused process runner; append-only evidence and isolated Windows user data."""
from pathlib import Path
import os, sys, json, hashlib, subprocess
from datetime import datetime, timezone

ROOT=Path(__file__).resolve().parents[3]
ENGINE=Path('D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
case=sys.argv[1]
script=sys.argv[2]
if not case.replace('_','').isalnum() or len(case)>32 or not script.startswith('res://'):
    raise SystemExit('Use a unique short case and an explicit res:// script')
OUT=ROOT/'docs/beta-sprint/game-feel/pfall-first-slice/evidence'/case
OUT.mkdir(parents=True,exist_ok=False)
PROFILE=OUT/'profile'
env=os.environ.copy()
for key,leaf in [('APPDATA','Roaming'),('LOCALAPPDATA','Local'),('TEMP','Temp'),('TMP','Temp')]:
    path=PROFILE/leaf; path.mkdir(parents=True,exist_ok=True); env[key]=str(path)
def digest(path):
    with Path(path).open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
paths=subprocess.check_output(['git','-C',str(ROOT),'ls-files','--cached','--others','--exclude-standard','-z','--','foundation','game/feel','experiments/game_feel_01','tests/beta_sprint/pfall_integration','tests/beta_sprint/game_feel','tests/beta_sprint/game_feel_owner_09','tests/beta_sprint/game_feel_owner_10a','tests/foundation/level/baker_fixture.gd'],encoding='utf-8').split('\0')
sources={p:digest(ROOT/p) for p in sorted(set(paths)) if p and (ROOT/p).is_file()}
head=subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],encoding='utf-8').strip()
dirty=subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain','-z'],encoding='utf-8').split('\0')
args=[str(ENGINE),'--headless','--path',str(ROOT),'--script',script,'--','--evidence='+OUT.as_posix(),'--evidence-dir='+OUT.as_posix(),'--profile='+PROFILE.as_posix()]
record={'case':case,'head':head,'dirty':[p for p in dirty if p],'script':script,'arguments':args,'engine_sha256':digest(ENGINE),'source_sha256':sources,'profile_environment':{k:env[k] for k in ['APPDATA','LOCALAPPDATA','TEMP','TMP']},'input':'direct formal API or explicitly labelled contract Unit; report defines authority','started_utc':datetime.now(timezone.utc).isoformat()}
for p in sources:
    if p.startswith(('game/feel/','experiments/game_feel_01/','tests/beta_sprint/pfall_integration/')):
        dest=OUT/'sources'/p; dest.parent.mkdir(parents=True,exist_ok=True); dest.write_bytes((ROOT/p).read_bytes())
with (OUT/'stdout.log').open('wb') as out, (OUT/'stderr.log').open('wb') as err:
    proc=subprocess.Popen(args,cwd=ROOT,env=env,stdout=out,stderr=err,creationflags=subprocess.CREATE_NO_WINDOW)
    record['pid']=proc.pid
    try: record['exit_code']=proc.wait(timeout=90)
    except subprocess.TimeoutExpired:
        proc.kill();proc.wait();record['exit_code']='TIMEOUT'
report_path=OUT/'report.json'
report=json.loads(report_path.read_text(encoding='utf-8-sig')) if report_path.exists() else {}
record.update({'finished_utc':datetime.now(timezone.utc).isoformat(),'checks':report.get('checks',0),'failures':report.get('failures',['missing report, parser or dependency failure']),'doubles':report.get('doubles',None),'source_drift':[p for p,s in sources.items() if not (ROOT/p).is_file() or digest(ROOT/p)!=s],'stderr_bytes':(OUT/'stderr.log').stat().st_size})
record['status']='PASS' if record['exit_code']==0 and record['checks']>0 and not record['failures'] and not record['source_drift'] and record['stderr_bytes']==0 else 'FAILED'
record['authority']=report.get('authority','UNDECLARED')
(OUT/'process.json').write_bytes((json.dumps(record,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:record[k] for k in ['case','pid','exit_code','checks','failures','doubles','source_drift','stderr_bytes','status','authority']},ensure_ascii=False))
if record['stderr_bytes']: print((OUT/'stderr.log').read_text(encoding='utf-8',errors='replace'))
raise SystemExit(0 if record['status']=='PASS' else 1)
