param([Parameter(Mandatory)][string]$EvidenceName,[string]$Script='res://tests/beta_sprint/spatial_owner_01/test_contracts.gd',[string[]]$ScriptArguments)
$ErrorActionPreference='Stop'
$taskRoot=[IO.Path]::GetFullPath("$PSScriptRoot/../../..")
$ev=Join-Path $taskRoot ".godot/spatial-01/$EvidenceName"
if(Test-Path -LiteralPath $ev){throw 'Evidence already exists'}
New-Item -ItemType Directory -Path $ev | Out-Null
$exe='D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
$shaFiles=@(Get-ChildItem -LiteralPath "$taskRoot/foundation","$taskRoot/tests/beta_sprint/spatial_owner_01" -Recurse -File | Where-Object Extension -EQ '.gd' | ForEach-Object {@{path=$_.FullName.Substring($taskRoot.Length);sha256=(Get-FileHash -LiteralPath $_.FullName).Hash.ToLowerInvariant()}})
@{head=(& git -C $taskRoot rev-parse HEAD);dirty=@(& git -C $taskRoot status --short --untracked-files=all);script=$Script;source_sha=$shaFiles;engine=$exe;engine_sha=(Get-FileHash -LiteralPath $exe).Hash.ToLowerInvariant()} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath "$ev/source.json"
$info=[Diagnostics.ProcessStartInfo]::new($exe)
$info.UseShellExecute=$false;$info.CreateNoWindow=$true
$info.RedirectStandardOutput=$true;$info.RedirectStandardError=$true;$info.WorkingDirectory=$taskRoot
foreach($arg in @('--headless','--path',$taskRoot,'--quit-after','5000','--script',$Script)){$info.ArgumentList.Add($arg)}
if($ScriptArguments){$info.ArgumentList.Add('--');foreach($arg in $ScriptArguments){$info.ArgumentList.Add($arg)}}
foreach($key in @('TEMP','TMP','APPDATA','LOCALAPPDATA')){$info.Environment[$key]=$ev}
$info.Environment['FOUNDATION_TEST_EVIDENCE']=$ev
$proc=[Diagnostics.Process]::Start($info)
@{pid=$proc.Id;status='RUNNING';arguments=@($info.ArgumentList)} | ConvertTo-Json | Set-Content -LiteralPath "$ev/process.json"
$out=[IO.FileStream]::new("$ev/stdout.log",[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::Read)
$err=[IO.FileStream]::new("$ev/stderr.log",[IO.FileMode]::Create,[IO.FileAccess]::Write,[IO.FileShare]::Read)
$ot=$proc.StandardOutput.BaseStream.CopyToAsync($out);$et=$proc.StandardError.BaseStream.CopyToAsync($err)
$proc.WaitForExit();$null=$ot.GetAwaiter().GetResult();$null=$et.GetAwaiter().GetResult();$out.Dispose();$err.Dispose()
$ec=$proc.ExitCode
@{exit_code=$ec;pid=$proc.Id;arguments=@($info.ArgumentList)} | ConvertTo-Json | Set-Content -LiteralPath "$ev/process.json"
$proc.Dispose()
Get-Content -LiteralPath "$ev/stderr.log"
Get-Content -LiteralPath "$ev/stdout.log" -Tail 4
if([IO.File]::ReadAllText("$ev/stderr.log") -match 'SCRIPT ERROR:|ERROR:'){exit 1}
$countMatch=[regex]::Match([IO.File]::ReadAllText("$ev/stdout.log"),'(?:checks=|"checks"\s*:\s*)(\d+)')
if(-not $countMatch.Success -or [int]$countMatch.Groups[1].Value -le 0){throw 'No behavior checks: normal quit-after guard is not PASS'}
exit $ec
