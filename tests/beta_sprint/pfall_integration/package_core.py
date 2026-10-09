"""00 standalone laboratory package, exact committed files, unique output only."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,re,subprocess,sys,zipfile

root=Path(__file__).resolve().parents[3]
target=Path(sys.argv[1]).resolve()
if target.exists(): raise SystemExit('Refusing to overwrite an existing QA package')
head=subprocess.check_output(['git','-C',str(root),'rev-parse','HEAD'],text=True).strip()
if subprocess.check_output(['git','-C',str(root),'status','--porcelain'],text=True).strip():
    raise SystemExit('Package requires a clean committed source identity')
if not (root/'foundation/game_feel/runtime_facade.gd').is_file():
    raise SystemExit('01 formal Runtime dependency not integrated')
target.mkdir(parents=True,exist_ok=False)
project=target/'project'
paths=subprocess.check_output(['git','-C',str(root),'ls-tree','-r','--name-only',head],encoding='utf-8').splitlines()
selected=[p for p in paths if p in ['project.godot','icon.svg','default_bus_layout.tres','tests/foundation/level/baker_fixture.gd'] or p.startswith(('foundation/','game/feel/animation/fall_landing/','experiments/game_feel_01/maps/','experiments/game_feel_01/host/','tests/beta_sprint/pfall_integration/')) or p=='game/feel/cube_presenter.gd']
files=[]
for relative in selected:
    data=subprocess.check_output(['git','-C',str(root),'show',head+':'+relative])
    path=project/relative
    path.parent.mkdir(parents=True,exist_ok=True)
    path.write_bytes(data)
    files.append({'path':'project/'+relative,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':subprocess.check_output(['git','-C',str(root),'rev-parse',head+':'+relative],text=True).strip()})
play='''param([string]$Godot="D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe")
$ErrorActionPreference="Stop"
$labProject=Join-Path $PSScriptRoot "project"
$labProfile=Join-Path $PSScriptRoot "qa-profile"
$env:APPDATA=Join-Path $labProfile "Roaming"
$env:LOCALAPPDATA=Join-Path $labProfile "Local"
$env:TEMP=Join-Path $labProfile "Temp"
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
& $Godot --path $labProject "res://experiments/game_feel_01/host/core_lab.tscn"
exit $LASTEXITCODE
'''
(target/'play.ps1').write_bytes(play.encode('utf-8'))
identity={'task':'PFALL_FIRST_VERTICAL_SLICE_INTEGRATION_01','build_kind':'CORE_LAB_CANDIDATE','integration_commit':head,'created_utc':datetime.now(timezone.utc).isoformat(),'engine':'Godot 4.7.2','scene':'res://experiments/game_feel_01/host/core_lab.tscn','profile':str(target/'qa-profile'),'assets':'isolated temporary BoxMesh, formal Art/Audio/UI NOT_INCLUDED','old_five_level_baseline':'UNCHANGED separate accepted QA package','human_qa':'NOT_RUN','files':files}
(target/'BUILD_IDENTITY.json').write_bytes((json.dumps(identity,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(target/'README.md').write_bytes(('CORE lab candidate; QA status is defined by the integration receipt, not package creation.\nIntegration: '+head+'\nRun PowerShell: ./play.ps1\nA/B buttons select maps. F: authored Fall. WASD/arrows: formal move. Q/E: authoritative Camera. R: Reset. Esc: Pause. Gold platform is Exit Goal. Space: unsupported in isolated Core.\nTemporary centered cube and face marker; Art, Audio, UI second-build integration pending. No L01-L05 puzzle/Save changes. user:// is isolated inside qa-profile. Human QA NOT_RUN.\n').encode('utf-8'))
archive=target.with_suffix('.zip')
if archive.exists(): raise SystemExit('Refusing to overwrite existing QA archive')
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(target.rglob('*')):
        if path.is_file(): output.write(path,path.relative_to(target))
with archive.open('rb') as stream: archive_hash=hashlib.file_digest(stream,'sha256').hexdigest()
print(json.dumps({'path':str(target),'integration_commit':head,'source_files':len(files),'archive':str(archive),'archive_sha256':archive_hash,'human_qa':'NOT_RUN'},ensure_ascii=False))
