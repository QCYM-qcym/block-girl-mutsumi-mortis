"""Exact committed-source Core lab package; explicit scene launcher, no old package writes."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess,sys,zipfile
root=Path(__file__).resolve().parents[3]
target=Path(sys.argv[1]).resolve()
archive=target.with_suffix('.zip')
if target.exists() or archive.exists():raise SystemExit('Refusing to overwrite QA package/archive')
git=lambda *a:subprocess.check_output(['git','-C',str(root),*a])
if git('status','--porcelain').strip():raise SystemExit('Requires clean committed source identity')
head=git('rev-parse','HEAD').decode().strip()
paths=git('ls-tree','-r','--name-only','-z',head).decode('utf-8').split('\0')
single={'project.godot','icon.svg','default_bus_layout.tres','tests/foundation/level/baker_fixture.gd','game/feel/cube_presenter.gd','experiments/game_feel_01/host/core_lab.gd','experiments/game_feel_01/host/core_lab.tscn','tests/beta_sprint/pfall_integration/test_core.gd'}
prefixes=('foundation/','game/feel/animation/fall_landing/','experiments/game_feel_01/maps/','tests/beta_sprint/pfall_v2_integration/')
selected=[p for p in paths if p and (p in single or p.startswith(prefixes)) and '__pycache__' not in p.split('/')]
files=[]
target.mkdir(parents=True,exist_ok=False)
for relative in selected:
    data=git('show',head+':'+relative)
    path=target/'project'/relative
    path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    files.append({'path':'project/'+relative,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':git('rev-parse',head+':'+relative).decode().strip()})
play='''param([string]$Godot="D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe",[int]$QuitAfter=0)
$ErrorActionPreference="Stop"
$labProject=Join-Path $PSScriptRoot "project"
$labProfile=Join-Path $PSScriptRoot "qa-profile"
$env:APPDATA=Join-Path $labProfile "Roaming"
$env:LOCALAPPDATA=Join-Path $labProfile "Local"
$env:TEMP=Join-Path $labProfile "Temp"
$env:TMP=$env:TEMP
New-Item -ItemType Directory -Force -Path $env:APPDATA,$env:LOCALAPPDATA,$env:TEMP | Out-Null
$labArgs=@("--path",$labProject,"res://experiments/game_feel_01/host/core_lab.tscn")
if($QuitAfter -gt 0){$labArgs+=@("--quit-after",[string]$QuitAfter)}
& $Godot @labArgs
exit $LASTEXITCODE
'''
(target/'play.ps1').write_text(play,encoding='utf-8')
(target/'README.md').write_text('PFALL v2 Core laboratory — automated acceptance is recorded by 00; Human QA NOT_RUN.\nIntegration source: '+head+'\nRun PowerShell: ./play.ps1 (Godot 4.7.2; optional -Godot executable path). The launcher explicitly selects core_lab.tscn; the preserved integration project.godot main menu entry is outside this minimal laboratory package. This is a source laboratory Build using installed Godot, not an exported standalone executable.\nMAP A/B: native A/B buttons. F: authored Fall; WASD/arrows: formal move; Q/E: camera; R: Reset; Esc: Pause. Valid starting view EAST. Full route: F → target/TOP → D (screen right at EAST maps U_POS) → exit/TOP Goal. Camera changes can alter mapped directional keys; U_POS remains the authoritative route.\nTemporary approved isolated BoxMesh and face marker. Dedicated qa-profile user data. Full Art/Audio/UI and Graphical TraceReplayer are outside Core acceptance. Old five-level and UI QA packages remain separate and unchanged.\n',encoding='utf-8')
generated=[{'path':name,'bytes':(target/name).stat().st_size,'sha256':hashlib.sha256((target/name).read_bytes()).hexdigest()} for name in ['play.ps1','README.md']]
identity={'task':'PFALL_V2_MAP_RUNTIME_INTEGRATION_01','kind':'COMMITTED_SOURCE_CORE_LAB','integration_commit':head,'engine':'Godot 4.7.2','scene':'res://experiments/game_feel_01/host/core_lab.tscn','map_delivery':'e4bcdfc6459f587cb26c25494dd5b57b76ccdca4','runtime_delivery':'26387d6c34a869ad7035ee13ee77d8d5c24d796a','animation_delivery':'4781dfcf16757ccbde13e54ee449f1cf00174944','profile':str(target/'qa-profile'),'human_qa':'NOT_RUN','files':files,'generated_files':generated,'created_utc':datetime.now(timezone.utc).isoformat()}
(target/'BUILD_IDENTITY.json').write_text(json.dumps(identity,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(archive,'x',compression=zipfile.ZIP_DEFLATED,compresslevel=6) as output:
    for path in sorted(target.rglob('*')):
        if path.is_file():output.write(path,path.relative_to(target))
with archive.open('rb') as stream:archive_hash=hashlib.file_digest(stream,'sha256').hexdigest()
print(json.dumps({'path':str(target),'integration_commit':head,'source_files':len(files),'archive':str(archive),'archive_sha256':archive_hash,'human_qa':'NOT_RUN'},ensure_ascii=False))
