param([string]$EvidenceName,[string]$Script='res://tests/beta_sprint/game_feel_owner_01/test_contracts.gd',[switch]$Graphical,[string[]]$ScriptArguments,[switch]$Import,[switch]$LegacyEvidence,[switch]$SourceMaps)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath("$PSScriptRoot/../../..")
$ev=Join-Path $taskRoot ".godot/game-feel-owner-01/$EvidenceName"
if(Test-Path -LiteralPath $ev){throw 'Evidence already exists'}
New-Item -ItemType Directory -Path $ev | Out-Null
if($SourceMaps){
@'
import sys, subprocess, pathlib, hashlib, json
root, ev = sys.argv[1:]
commit = "82a8a7dc85205e9391551f24267f35f5abe53393"
records = []
for letter in ("a", "b"):
    source = f"experiments/game_feel_01/maps/map_{letter}.json"
    raw = subprocess.check_output(["git", "-C", root, "show", f"{commit}:{source}"])
    pathlib.Path(ev, f"map_{letter}.json").write_bytes(raw)
    records.append({"commit":commit,"path":source,"sha256":hashlib.sha256(raw).hexdigest(),"blob":subprocess.check_output(["git","-C",root,"rev-parse",f"{commit}:{source}"]).decode().strip()})
pathlib.Path(ev,"map_source.json").write_text(json.dumps(records,indent=2),encoding="utf-8")
'@ | python - $taskRoot $ev
if($LASTEXITCODE -ne 0){throw 'Map input acquisition failed'}
}
if($Import){$Script='EDITOR_IMPORT'}
$source=@(& git -C $taskRoot status --short --untracked-files=all)
$shaFiles=@(Get-ChildItem -LiteralPath "$taskRoot/foundation","$taskRoot/tests/beta_sprint/game_feel_owner_01" -Recurse -File | Where-Object Extension -EQ '.gd' | ForEach-Object {@{path=$_.FullName.Replace($taskRoot,'');sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()}})
$exe='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
@{head=(& git -C $taskRoot rev-parse HEAD);dirty=$source;script=$Script;input= $(if($Script.StartsWith('res://tests/beta_sprint/game_feel_owner_01/')){'semantic actions'}else{'LEGACY_SCRIPT_DECLARED_INPUT'});source_sha=$shaFiles;engine=$exe;engine_sha=(Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant()} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$ev/source.json"
$info=[Diagnostics.ProcessStartInfo]::new($exe)
$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true;$info.WorkingDirectory=$taskRoot
$args=if($Import){@('--headless','--editor','--path',$taskRoot,'--import')}elseif($Graphical){@('--path',$taskRoot,'--max-fps','60','--script',$Script)}else{@('--headless','--path',$taskRoot,'--script',$Script)}
if($LegacyEvidence){$ScriptArguments=@("--evidence-dir=$ev")}
if($ScriptArguments){$args+='--';$args+=$ScriptArguments}
foreach($arg in $args){$info.ArgumentList.Add($arg)}
foreach($key in @('TEMP','TMP','APPDATA','LOCALAPPDATA')){$info.Environment[$key]=$ev}
$info.Environment['FOUNDATION_TEST_EVIDENCE']=$ev
$proc=[Diagnostics.Process]::Start($info)
@{pid=$proc.Id;status='RUNNING';arguments=@($info.ArgumentList)} | ConvertTo-Json | Set-Content -LiteralPath "$ev/process.json"
$out=[IO.FileStream]::new("$ev/stdout.log",[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::Read);$err=[IO.FileStream]::new("$ev/stderr.log",[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::Read)
$ot=$proc.StandardOutput.BaseStream.CopyToAsync($out);$et=$proc.StandardError.BaseStream.CopyToAsync($err)
$proc.WaitForExit();$null=$ot.GetAwaiter().GetResult();$null=$et.GetAwaiter().GetResult();$out.Dispose();$err.Dispose()
$ec=$proc.ExitCode
@{exit_code=$ec;pid=$proc.Id;arguments=@($info.ArgumentList)} | ConvertTo-Json | Set-Content -LiteralPath "$ev/process.json"
$proc.Dispose()
Get-Content -LiteralPath "$ev/stderr.log"
Get-Content -LiteralPath "$ev/stdout.log" -Tail 5
if([IO.File]::ReadAllText("$ev/stderr.log") -match 'SCRIPT ERROR:|ERROR:'){exit 1}
exit $ec
