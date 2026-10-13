"""00 append-only real process runner, usable against source or immutable package."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib,json,os,re,subprocess,sys

ROOT=Path(__file__).resolve().parents[3]
ENGINE=Path('D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
case,script=sys.argv[1:3]
mode=sys.argv[3] if len(sys.argv)>3 else 'headless'
PROJECT=Path(sys.argv[4]).resolve() if len(sys.argv)>4 else ROOT
if not re.fullmatch(r'[a-zA-Z0-9_]{1,32}',case) or not script.startswith('res://') or mode not in ['headless','graphical']:
    raise SystemExit('Explicit script, unique short case, and headless/graphical mode required')
out=ROOT/'docs/beta-sprint/spatial-puzzle-batch-01/evidence'/case
out.mkdir(parents=True,exist_ok=False)
profile=out/'profile'
env=os.environ.copy()
for key,leaf in [('APPDATA','Roaming'),('LOCALAPPDATA','Local'),('TEMP','Temp'),('TMP','Temp')]:
    dest=profile/leaf;dest.mkdir(parents=True,exist_ok=True);env[key]=str(dest)
env['FOUNDATION_TEST_EVIDENCE']=str(out)
def digest(path):
    with path.open('rb') as stream:return hashlib.file_digest(stream,'sha256').hexdigest()
source_dirs=['experiments/spatial_puzzle_batch_01','tests/beta_sprint/spatial_integration','foundation','game/feel','experiments/game_feel_01','tests/beta_sprint/pfall_integration','tests/beta_sprint/pfall_v2_integration','tests/beta_sprint/game_feel_full_slice','tests/beta_sprint/graphical_bridge_02','tests/beta_sprint/yellow_target_01','tests/beta_sprint/forward_drop_01','tests/beta_sprint/game_feel_owner_10a','tests/beta_sprint/game_feel_owner_01','tests/beta_sprint/game_feel_owner_03','game/shell','tests/foundation/level']
def source_files():
    paths={p.relative_to(PROJECT).as_posix():p for directory in source_dirs for p in (PROJECT/directory).rglob('*') if p.is_file() and '__pycache__' not in p.parts}
    entry=script.removeprefix('res://')
    if (PROJECT/entry).is_file(): paths[entry]=PROJECT/entry
    for name in ['project.godot','default_bus_layout.tres','icon.svg']:
        if (PROJECT/name).is_file(): paths[name]=PROJECT/name
    return paths
sources={name:digest(path) for name,path in source_files().items()}
for name in ['project.godot','default_bus_layout.tres','icon.svg']:
    if (PROJECT/name).is_file(): sources[name]=digest(PROJECT/name)
args=[str(ENGINE)]+(['--headless'] if mode=='headless' else [])+['--max-fps','60','--path',str(PROJECT),'--script',script,'--','--evidence='+out.as_posix(),'--evidence-dir='+out.as_posix(),'--profile='+profile.as_posix()]+sys.argv[5:]
record={'case':case,'project':str(PROJECT),'integration_head':subprocess.check_output(['git','-C',str(ROOT),'rev-parse','HEAD'],text=True).strip(),'script':script,'mode':mode,'arguments':args,'source_sha256':sources,'engine_sha256':digest(ENGINE),'profile_environment':{k:env[k] for k in ['APPDATA','LOCALAPPDATA','TEMP','TMP']},'started_utc':datetime.now(timezone.utc).isoformat()}
record['dirty']=[p for p in subprocess.check_output(['git','-C',str(ROOT),'status','--porcelain','-z'],encoding='utf-8').split('\0') if p]
identity=PROJECT.parent/'BUILD_IDENTITY.json'
if PROJECT!=ROOT and identity.is_file(): record['build_identity']=json.loads(identity.read_text(encoding='utf-8-sig'))['integration_commit']
with (out/'stdout.log').open('wb') as stdout,(out/'stderr.log').open('wb') as stderr:
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    process=subprocess.Popen(args,cwd=PROJECT,env=env,stdout=stdout,stderr=stderr,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
    record['pid']=process.pid
    try:record['exit_code']=process.wait(timeout=240)
    except subprocess.TimeoutExpired:process.kill();process.wait();record['exit_code']='TIMEOUT'
path=out/'report.json'
if not path.exists(): path=out/'unit.json'
if not path.exists(): path=out/'results.json'
report=json.loads(path.read_text(encoding='utf-8-sig')) if path.exists() else {}
after=source_files()
drift=sorted(set(after).symmetric_difference(sources))+[p for p,sha in sources.items() if p in after and digest(after[p])!=sha]
record.update({'checks':report.get('checks',0),'failures':report.get('failures',['missing report']),'doubles':report.get('doubles'),'stderr_bytes':(out/'stderr.log').stat().st_size,'source_drift':drift,'finished_utc':datetime.now(timezone.utc).isoformat()})
observations = report.get('observations', {})
if not isinstance(observations, dict): observations = {}
record.update({'display':report.get('display'),'renderer':report.get('renderer',observations.get('renderer')),'user_data_dir':report.get('user_data_dir'),'input':report.get('input','Declared in script authority and per-route rows'),'authority':report.get('authority'),'engine_version':next((line for line in (out/'stdout.log').read_text(encoding='utf-8',errors='replace').splitlines() if line.startswith('Godot Engine')),'UNAVAILABLE')})
record['status']='PASS' if record['exit_code']==0 and record['checks']>0 and record['failures']==[] and record['doubles']==[] and record['stderr_bytes']==0 and not record['source_drift'] else 'FAIL'
(out/'process.json').write_text(json.dumps(record,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:record[k] for k in ['case','pid','exit_code','checks','failures','doubles','stderr_bytes','source_drift','status']},ensure_ascii=False))
if record['stderr_bytes']:print((out/'stderr.log').read_text(encoding='utf-8',errors='replace'))
raise SystemExit(0 if record['status']=='PASS' else 1)
