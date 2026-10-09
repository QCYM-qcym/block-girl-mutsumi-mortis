param(
    [string]$RunId = 'native_01',
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
$ErrorActionPreference = 'Stop'
if ($RunId -notmatch '^[A-Za-z0-9_-]+$') { throw 'RunId must be a simple unique name' }
$l06Project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$l06Evidence = Join-Path $PSScriptRoot "evidence/$RunId"
if (Test-Path -LiteralPath $l06Evidence) { throw 'Preserve old evidence; choose another RunId' }
New-Item -ItemType Directory -Path $l06Evidence | Out-Null
$l06Head = git -C $l06Project rev-parse HEAD
$l06Protected = @(git -C $l06Project -c core.quotepath=false ls-files | Where-Object {
    $_ -notmatch '^(docs/beta-sprint/l06-preproduction/|tests/beta_sprint/l06_preproduction/)'
})
function Get-L06Snapshot {
    @($l06Protected | ForEach-Object {
        $l06File = Join-Path $l06Project $_
        [ordered]@{path=$_; bytes=(Get-Item -LiteralPath $l06File).Length; sha256=(Get-FileHash -LiteralPath $l06File -Algorithm SHA256).Hash.ToLowerInvariant()}
    })
}
$l06Before = Get-L06Snapshot
$l06Sources = @('docs/beta-sprint/l06-preproduction/CANDIDATE.json','tests/beta_sprint/l06_preproduction/validate_design.gd','tests/beta_sprint/l06_preproduction/run.ps1')
$l06SourceIdentity = @($l06Sources | ForEach-Object {
    [ordered]@{path=$_; sha256=(Get-FileHash -LiteralPath (Join-Path $l06Project $_) -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$l06Args = @('--headless','--path',('"'+$l06Project+'"'),'--script','res://tests/beta_sprint/l06_preproduction/validate_design.gd','--',('--evidence-dir="'+$l06Evidence+'"'))
$l06Out = Join-Path $l06Evidence 'stdout.log'
$l06Err = Join-Path $l06Evidence 'stderr.log'
$l06Start = [DateTime]::UtcNow
$l06Process = Start-Process -FilePath $Godot -ArgumentList $l06Args -WindowStyle Hidden -PassThru -RedirectStandardOutput $l06Out -RedirectStandardError $l06Err
Write-Output "START PID=$($l06Process.Id)"
$l06Timeout = -not $l06Process.WaitForExit(60000)
if ($l06Timeout) { $l06Process.Kill() }
$l06Process.WaitForExit()
$l06After = Get-L06Snapshot
$l06Changed = @()
for ($l06Index=0; $l06Index -lt $l06Before.Count; $l06Index++) {
    if ($l06Before[$l06Index].sha256 -ne $l06After[$l06Index].sha256 -or $l06Before[$l06Index].bytes -ne $l06After[$l06Index].bytes) {
        $l06Changed += $l06Before[$l06Index].path
    }
}
[ordered]@{kind='all tracked outside authorized roots'; count=$l06Before.Count; changed=$l06Changed; before=$l06Before; after=$l06After} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $l06Evidence 'protection.json') -Encoding utf8NoBOM
[ordered]@{
    pid=$l06Process.Id; exit_code=$l06Process.ExitCode; timed_out=$l06Timeout; start_utc=$l06Start.ToString('o'); end_utc=[DateTime]::UtcNow.ToString('o');
    project=$l06Project; head=$l06Head; args=$l06Args; sources=$l06SourceIdentity;
    stdout_sha256=(Get-FileHash -LiteralPath $l06Out -Algorithm SHA256).Hash.ToLowerInvariant();
    stderr_sha256=(Get-FileHash -LiteralPath $l06Err -Algorithm SHA256).Hash.ToLowerInvariant(); protected_changes=$l06Changed
} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $l06Evidence 'process.json') -Encoding utf8NoBOM
Get-Content -LiteralPath $l06Out
$l06Errors = Get-Content -LiteralPath $l06Err -Raw
if ($l06Errors) { Write-Output $l06Errors }
if ($l06Timeout -or $l06Process.ExitCode -ne 0 -or $l06Errors -match 'SCRIPT ERROR:|ERROR:|FAIL:' -or $l06Changed.Count -ne 0) { throw 'Design validation failed; actual evidence retained' }
$l06Report = Get-Content -LiteralPath (Join-Path $l06Evidence 'report.json') -Raw | ConvertFrom-Json
if ($l06Report.failures.Count -ne 0) { throw 'Report contains failures' }
Write-Output "L06_DESIGN_NATIVE_PASS checks=$($l06Report.checks) protected=$($l06Before.Count) PID=$($l06Process.Id) exit=$($l06Process.ExitCode)"
