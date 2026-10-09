"""Two unchanged focused real regression cases; neither grants Fall acceptance."""
from pathlib import Path
import hashlib,json,os,re,subprocess,sys
from datetime import datetime,timezone
root=Path(__file__).resolve().parents[3]
suffix=sys.argv[1] if len(sys.argv)>1 else '01'
if not re.fullmatch(r'[a-zA-Z0-9_]{1,16}',suffix):raise SystemExit('Unique short suffix required')
cases=[('legacy_pconn_'+suffix,'res://tests/gameplay/test_perspective_logic.gd','PERSPECTIVE_LOGIC: ',r'(\d+) checks'),('legacy_safety_'+suffix,'res://tests/foundation/kernel_safety/test_kernel_safety.gd','KERNEL_SAFETY_INTEGRATION ',r'checks=(\d+)')]
engine=Path('D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe')
failed=False
for name,script,marker,pattern in cases:
    out=root/'docs/beta-sprint/game-feel/pfall-v2-01/evidence'/name
    out.mkdir(parents=True,exist_ok=False)
    env=os.environ.copy()
    for key,leaf in [('APPDATA','Roaming'),('LOCALAPPDATA','Local'),('TEMP','Temp'),('TMP','Temp')]:
        path=out/'profile'/leaf;path.mkdir(parents=True,exist_ok=True);env[key]=str(path)
    args=[str(engine),'--headless','--path',str(root),'--script',script]
    sources={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for directory in ['foundation','prototype/perspective','tests/gameplay','tests/foundation/kernel_safety','tests/foundation/rules','tests/foundation/validation'] for p in (root/directory).rglob('*') if p.is_file()}
    for path in ['project.godot','default_bus_layout.tres','icon.svg']:sources[path]=hashlib.sha256((root/path).read_bytes()).hexdigest()
    started=datetime.now(timezone.utc).isoformat()
    execution_head=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
    dirty=[p for p in subprocess.check_output(['git','-C',str(root),'status','--porcelain','-z'],encoding='utf-8').split('\0') if p]
    startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
    with (out/'stdout.log').open('wb') as stdout,(out/'stderr.log').open('wb') as stderr:
        p=subprocess.Popen(args,cwd=root,env=env,stdout=stdout,stderr=stderr,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
        try:code=p.wait(timeout=60)
        except subprocess.TimeoutExpired:p.kill();p.wait();code='TIMEOUT'
    text=(out/'stdout.log').read_text(encoding='utf-8',errors='replace')
    rows=[line for line in text.splitlines() if line.startswith(marker)]
    match=re.search(pattern,rows[0]) if len(rows)==1 else None
    checks=int(match[1]) if match else 0
    errors=[]
    if code!=0 or checks<=0 or len(rows)!=1 or 'failures=[]' not in rows[0] or (out/'stderr.log').stat().st_size or any(line.startswith('FAIL:') for line in text.splitlines()):errors.append('Legacy process/marker/assertion/stderr gate failed')
    drift=[path for path,sha in sources.items() if not (root/path).is_file() or hashlib.sha256((root/path).read_bytes()).hexdigest()!=sha]
    if drift:errors.append('source drift')
    report={'case':name,'script':script,'source_sha256':sources,'source_drift':drift,'integration_head':execution_head,'dirty':dirty,'engine_sha256':hashlib.sha256(engine.read_bytes()).hexdigest(),'engine_version':next((line for line in text.splitlines() if line.startswith('Godot Engine')),'UNAVAILABLE'),'display':'headless (explicit --headless process)','renderer':'NOT_RENDERED (headless legacy cases)','input':'direct unchanged test APIs; OS/human input NOT_RUN','profile_environment':{k:env[k] for k in ['APPDATA','LOCALAPPDATA','TEMP','TMP']},'started_utc':started,'finished_utc':datetime.now(timezone.utc).isoformat(),'arguments':args,'pid':p.pid,'exit_code':code,'checks':checks,'failures':errors,'stderr_bytes':(out/'stderr.log').stat().st_size,'doubles':[],'authority':'unchanged real legacy regression; not new Fall authority','status':'FAIL' if errors else 'PASS'}
    (out/'process.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({k:report[k] for k in ['case','pid','exit_code','checks','failures','stderr_bytes','source_drift','status']},ensure_ascii=False));failed=failed or bool(errors)
raise SystemExit(1 if failed else 0)
