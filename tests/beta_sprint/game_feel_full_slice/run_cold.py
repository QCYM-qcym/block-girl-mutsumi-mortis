"""Append-only real engine runs; isolated user data, immutable source fingerprints."""
from pathlib import Path
import hashlib,json,os,subprocess,sys
ROOT=Path(__file__).resolve().parents[3]
name=sys.argv[1]
script=sys.argv[2]
project=Path(sys.argv[3]).resolve() if len(sys.argv)>3 and sys.argv[3]!='root' else ROOT
user_args=sys.argv[4:]
assert name.replace('_','').isalnum() and len(name)<=32 and script.startswith('res://')
out=ROOT/'docs/beta-sprint/game-feel/full-slice-01/evidence'/name
out.mkdir(parents=True,exist_ok=False)
env=os.environ.copy()
for key,leaf in [('APPDATA','Roaming'),('LOCALAPPDATA','Local'),('TEMP','Temp'),('TMP','Temp')]:
 p=out/'profile'/leaf;p.mkdir(parents=True,exist_ok=True);env[key]=str(p)
paths=subprocess.check_output(['git','ls-files','--cached','--others','--exclude-standard','-z','--','foundation','game','experiments/game_feel_01','project.godot','default_bus_layout.tres','tests/beta_sprint/ui_host_integration','tests/beta_sprint/game_feel_full_slice'],cwd=ROOT).decode('utf-8').split('\0')
sources={p:hashlib.sha256((project/p).read_bytes()).hexdigest() for p in sorted(set(paths)) if p and (project/p).is_file()}
record={'head':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'dirty':subprocess.check_output(['git','status','--porcelain'],cwd=ROOT,text=True).splitlines(),'project':str(project),'sources':sources,'runs':[]}
engine='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
phases=['seed','restore'] if '--cold' in user_args else ['matrix' if '--graphical' in user_args else 'unit']
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
for phase in phases:
 args=[engine]+([] if '--graphical' in user_args else ['--headless'])+['--path',str(project),'--script',script,'--max-fps','60','--','--evidence='+out.as_posix(),'--phase='+phase,'--shell-save=user://ui_host/progress.json']+[a for a in user_args if a not in ['--graphical','--cold']]
 with (out/(phase+'.stdout.log')).open('wb') as stdout,(out/(phase+'.stderr.log')).open('wb') as stderr:
  proc=subprocess.Popen(args,cwd=project,env=env,stdout=stdout,stderr=stderr,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW)
  try:code=proc.wait(timeout=120)
  except subprocess.TimeoutExpired:proc.kill();proc.wait();code='TIMEOUT'
 report_path=out/(phase+'.json')
 report=json.loads(report_path.read_text(encoding='utf-8-sig')) if report_path.exists() else {}
 row={'phase':phase,'pid':proc.pid,'arguments':args,'exit_code':code,'stderr_bytes':(out/(phase+'.stderr.log')).stat().st_size,'checks':report.get('checks',0),'failures':report.get('failures',['missing report']),'doubles':report.get('doubles'),'report_sha256':hashlib.sha256(report_path.read_bytes()).hexdigest() if report_path.exists() else None}
 record['runs'].append(row)
 print(json.dumps(row,ensure_ascii=False))
record['source_drift']=[p for p,s in sources.items() if hashlib.sha256((project/p).read_bytes()).hexdigest()!=s]
record['passed']=not record['source_drift'] and all(r['exit_code']==0 and r['checks']>0 and not r['failures'] and r['stderr_bytes']==0 and r['doubles']==[] for r in record['runs'])
(out/'process.json').write_bytes((json.dumps(record,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
raise SystemExit(0 if record['passed'] else 1)
