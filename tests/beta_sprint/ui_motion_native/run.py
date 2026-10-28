"""Owned-process native-menu checks. Never sends input to another process."""
import argparse, json, os, subprocess, time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('--case',choices=['backdrop','settings','integration','palette','view','graphical'],required=True);p.add_argument('--evidence',required=True);p.add_argument('--graphical',action='store_true');a=p.parse_args()
root=Path(__file__).resolve().parents[3];out=Path(a.evidence).resolve();out.mkdir(parents=True,exist_ok=True)
prefix=a.case+('_graphical' if a.graphical else '_headless'); receipt=out/(prefix+'_process.json')
if receipt.exists():raise SystemExit('Preserve previous evidence; choose a fresh output directory')
env=os.environ.copy()
for key in ['APPDATA','LOCALAPPDATA','TEMP','TMP']:
 folder=out/'profiles'/prefix/key;folder.mkdir(parents=True,exist_ok=True);env[key]=str(folder)
engine='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
cmd=[engine,'--path',str(root),'--audio-driver','Dummy']
if not a.graphical:cmd+=['--headless']
else:cmd+=['--position','30000,30000','--resolution','1280x720']
cmd+=['--script','res://tests/beta_sprint/ui_motion_native/test_'+a.case+'.gd','--','--evidence-dir='+str(out),'--shell-save=user://native_menu/'+prefix+'.json']
started=time.monotonic()
stdout_path=out/(prefix+'.stdout.txt');stderr_path=out/(prefix+'.stderr.txt')
startup=None
if os.name=='nt' and a.graphical:
 startup=subprocess.STARTUPINFO();startup.dwFlags=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
with stdout_path.open('wb') as stdout_file,stderr_path.open('wb') as stderr_file:
 process=subprocess.Popen(cmd,env=env,stdout=stdout_file,stderr=stderr_file,startupinfo=startup,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' and not a.graphical else 0)
 (out/(prefix+'_running.json')).write_text(json.dumps({'pid':process.pid,'command':cmd}),encoding='utf-8')
 try:code=process.wait(timeout=180)
 except subprocess.TimeoutExpired:process.kill();process.wait();code=-1
stdout=stdout_path.read_text(encoding='utf-8',errors='replace');stderr=stderr_path.read_text(encoding='utf-8',errors='replace')
data={'case':a.case,'exit_code':code,'seconds':round(time.monotonic()-started,3),'stderr_empty':not stderr.strip(),'command':cmd,'scope':'REAL_RENDERING' if a.graphical else 'HEADLESS_NOT_GRAPHICAL','human_qa':'NOT_RUN'}
receipt.write_text(json.dumps(data,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(data));print(stdout[-9000:]);print(stderr[-3000:]);raise SystemExit(code if code else (1 if stderr.strip() else 0))
