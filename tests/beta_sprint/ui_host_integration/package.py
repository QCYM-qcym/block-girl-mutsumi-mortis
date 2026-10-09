"""Immutable, exact Git source package plus declared existing Godot import artifacts."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, io, json, re, subprocess, sys, tarfile, zipfile

root=Path(__file__).resolve().parents[3]
target=Path(sys.argv[1]).resolve()
archive=target.with_suffix('.zip')
if target.exists() or archive.exists(): raise SystemExit('Refusing to overwrite any QA package')
git=lambda *a: subprocess.check_output(['git','-C',str(root),*a])
if git('status','--porcelain').strip(): raise SystemExit('Build requires clean committed source')
head=git('rev-parse','HEAD').decode().strip()
roots=['foundation','game','production','prototype','experiments/game_feel_01','tests/foundation/level','tests/beta_sprint/ui_host_integration','tests/beta_sprint/pfall_integration','project.godot','default_bus_layout.tres','icon.svg','icon.svg.import']
selected=git('ls-tree','-r','--name-only',head,'--',*roots).decode('utf-8').splitlines()
selected=[p for p in selected if not any(s in p.split('/') for s in ['evidence','receipts','profile','__pycache__']) and not p.endswith(('.log','.zip','.tmp'))]
files=[]
target.mkdir(parents=True,exist_ok=False)
project=target/'project'
payload=git('archive','--format=tar',head,*roots) # Stay below Windows command-line length.
with tarfile.open(fileobj=io.BytesIO(payload)) as source:
    for member in source:
        if not member.isfile() or member.name not in selected: continue
        destination=project/member.name
        if not destination.resolve().is_relative_to(project.resolve()): raise SystemExit('Archive path escaped build')
        data=source.extractfile(member).read()
        destination.parent.mkdir(parents=True,exist_ok=True)
        destination.write_bytes(data)
        files.append({'path':'project/'+member.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'kind':'git_source'})

# Reuse existing compiled imports. No editor/import command rewrites frozen sources.
imports={}
for path in project.rglob('*.import'):
    metadata=path.read_text(encoding='utf-8-sig')
    source_match=re.search(r'source_file="res://([^"]+)"',metadata)
    for relative in re.findall(r'res://(\.godot/imported/[^"\s]+)',metadata): imports[relative]=source_match[1] if source_match else None
owners=json.loads((root/'docs/beta-sprint/game-feel/WORKTREES.json').read_text(encoding='utf-8-sig'))['owners']
cache_roots=[root,Path('E:/godot/beta-sprint-builds/beta_five_level_3d_20261009_01/project')]+[Path(x['worktree']) for x in owners]
for relative in sorted(imports):
    asset=imports[relative]
    candidates=[p/relative for p in cache_roots if asset and (p/asset).is_file() and (p/asset).read_bytes()==(project/asset).read_bytes()]
    source=next((p for p in candidates if p.is_file()),None)
    if source is None: raise SystemExit('Missing existing import artifact: '+relative)
    data=source.read_bytes();destination=project/relative
    destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(data)
    files.append({'path':'project/'+relative,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'kind':'existing_import','source':str(source)})
for relative in ['.godot/uid_cache.bin','.godot/global_script_class_cache.cfg']:
    source=root/relative
    if source.is_file():
        data=source.read_bytes();destination=project/relative
        destination.parent.mkdir(parents=True,exist_ok=True);destination.write_bytes(data)
        files.append({'path':'project/'+relative,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'kind':'existing_cache'})
play='''param([string]$Godot="D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
$ErrorActionPreference="Stop"
$uiProject=Join-Path $PSScriptRoot "project"
$uiProfile=Join-Path $PSScriptRoot "qa-profile"
$env:APPDATA=Join-Path $uiProfile "Roaming"
$env:LOCALAPPDATA=Join-Path $uiProfile "Local"
$env:TEMP=Join-Path $uiProfile "Temp"
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
& $Godot --path $uiProject
exit $LASTEXITCODE
'''
(target/'play.ps1').write_bytes(play.encode('utf-8'))
identity={'task':'GAME_FEEL_UI_HOST_INTEGRATION_01','kind':'SOURCE_PLAYABLE_REQUIRES_GODOT','integration_commit':head,'engine':'Godot 4.7.2','created_utc':datetime.now(timezone.utc).isoformat(),'main_scene':'res://game/shell/game_feel_shell.tscn','contract':'2938d6e534f5b596bb320ce79d72b69f5923f3cd','ui_original':'cccd9e2f23fbf3761e15dc44aa74a8496f78d268','ui_accepted':'6d3bf4b7f5120b44dad4790b657a4be953dd4954','audio_original':'4afbd068fae74a826dae4db04c2c612af23fa861','audio_accepted':'7363e9e7d7849018cc456ae866a60e23472591d6','profile':str(target/'qa-profile'),'runtime_readiness':'PENDING_RUNTIME_INTERFACE','edge_recoil_host':'PENDING','art':'Frozen existing approved five-level assets; isolated Core BoxMesh remains experimental','human_qa':'NOT_RUN','files':files}
(target/'BUILD_IDENTITY.json').write_bytes((json.dumps(identity,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(target/'README.md').write_bytes(('Game Feel UI Host QA candidate. Source playable package; install Godot 4.7.2 separately.\nSource: '+head+'\nPowerShell: ./play.ps1\nConfigured official menu keeps L01-L05. Settings uses the existing SaveStore. Bottom-right 错视实验 enters the real Core A/B lab. A/B selects map; F Fall, WASD move, Q/E Camera, R Reset, Esc official Pause. Temporary BoxMesh is not final Art. Connection preparedness and 10B host consumption remain PENDING;10A Reduced Motion selects the next Fall, without Gameplay changes. user:// is isolated under qa-profile. Human QA NOT_RUN. Never replace old QA packages/evidence/profiles.\n').encode('utf-8'))
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(target.rglob('*')):
        if path.is_file(): output.write(path,path.relative_to(target))
with archive.open('rb') as stream: digest=hashlib.file_digest(stream,'sha256').hexdigest()
print(json.dumps({'path':str(target),'integration_commit':head,'files':len(files),'source_files':sum(x['kind']=='git_source' for x in files),'import_files':len(imports),'archive':str(archive),'archive_sha256':digest},ensure_ascii=False))
