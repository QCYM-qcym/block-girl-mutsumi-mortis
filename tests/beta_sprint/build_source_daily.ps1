param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$BuildName = ('source_daily_' + (Get-Date -Format 'yyyyMMdd_HHmmss')),
    [string]$SmokeEvidenceName = ''
)
$ErrorActionPreference = 'Stop'
if ($BuildName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a fresh simple build name.' }
if ($SmokeEvidenceName -and $SmokeEvidenceName -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Use a simple smoke evidence name.' }
$dailySource = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../..')).Path
$dailyOutputRoot = [IO.Path]::GetFullPath('E:/godot/beta-sprint-builds')
$dailyBuild = [IO.Path]::GetFullPath((Join-Path $dailyOutputRoot $BuildName))
if (-not $dailyBuild.StartsWith($dailyOutputRoot + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Build path escaped approved output root.' }
if (Test-Path -LiteralPath $dailyBuild) { throw 'Preserve prior build; choose a fresh BuildName.' }
$dailyProject = Join-Path $dailyBuild 'project'
$dailyEvidence = Join-Path $dailySource ".godot/beta-sprint/$BuildName"
if (Test-Path -LiteralPath $dailyEvidence) { throw 'Preserve prior build evidence; choose a fresh BuildName.' }
New-Item -ItemType Directory -Path $dailyProject,$dailyEvidence -Force | Out-Null
$dailyFiles = @(& git -C $dailySource -c core.quotepath=false ls-files --cached --others --exclude-standard) | Sort-Object -Unique
if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate project source.' }
$dailyManifest = [Collections.Generic.List[object]]::new()
foreach ($dailyRelative in $dailyFiles) {
    if ($dailyRelative -match '(?i)(^|/)\.git(/|$)|(^|/)\.godot(/|$)|(^|/)[^/]*evidence[^/]*/|(^|/)receipts?/' -or $dailyRelative -match '(?i)\.(log|zip|exe|pck|tmp)$') { continue }
    $dailyFrom = Join-Path $dailySource $dailyRelative
    if (-not (Test-Path -LiteralPath $dailyFrom -PathType Leaf)) { continue }
    $dailyTo = Join-Path $dailyProject $dailyRelative
    New-Item -ItemType Directory -Path (Split-Path -Parent $dailyTo) -Force | Out-Null
    Copy-Item -LiteralPath $dailyFrom -Destination $dailyTo
    $dailyHash = (Get-FileHash -LiteralPath $dailyFrom -Algorithm SHA256).Hash
    if ($dailyHash -ne (Get-FileHash -LiteralPath $dailyTo -Algorithm SHA256).Hash) { throw "Source changed during snapshot: $dailyRelative. Preserve this failed build and rerun with a fresh name." }
    $dailyManifest.Add([pscustomobject]@{ path=$dailyRelative; sha256=$dailyHash.ToLowerInvariant(); bytes=(Get-Item -LiteralPath $dailyTo).Length })
}
$dailyVersion = if (Test-Path -LiteralPath $Godot) { (& $Godot --version | Out-String).Trim() } else { 'UNAVAILABLE' }
$dailyTemplates = Join-Path $env:APPDATA 'Godot/export_templates'
$dailyInfo = [ordered]@{ package_kind='SOURCE_PLAYABLE_NOT_EXE'; created_at=(Get-Date -Format o); head=(& git -C $dailySource rev-parse HEAD); source_branch=(& git -C $dailySource branch --show-current); source_status=@(& git -C $dailySource status --porcelain); godot=$Godot; godot_version=$dailyVersion; engine_sha256=$(if(Test-Path -LiteralPath $Godot){(Get-FileHash -LiteralPath $Godot -Algorithm SHA256).Hash.ToLowerInvariant()}else{$null}); export_preset_present=(Test-Path -LiteralPath (Join-Path $dailySource 'export_presets.cfg')); export_template_root=$dailyTemplates; export_template_root_present=(Test-Path -LiteralPath $dailyTemplates); smoke_evidence_name=$SmokeEvidenceName; excludes='.git, .godot, evidence directories, receipt directories, logs and prior archives/executables'; files=@($dailyManifest.ToArray()); verification=@() }
$dailyPlay = @'
param([string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe', [switch]$Foundation)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $Godot)) { throw 'Install Godot 4.7.2 or pass -Godot with its executable path.' }
$dailyPlayProject = Join-Path $PSScriptRoot 'project'
& $Godot --headless --editor --import --path $dailyPlayProject
if ($LASTEXITCODE -ne 0) { throw 'Godot asset import failed.' }
if ($Foundation) { & $Godot --path $dailyPlayProject res://prototype/foundation/runtime/foundation_runtime.tscn }
else { & $Godot --path $dailyPlayProject }
exit $LASTEXITCODE
'@
$dailyPlay | Set-Content -LiteralPath (Join-Path $dailyBuild 'play.ps1') -Encoding utf8
@"
# Daily source playable package (NOT an exported executable)

Snapshot: $($dailyInfo.head), $($dailyInfo.created_at).
Engine used: $dailyVersion. Godot is required separately.

Run in PowerShell: ./play.ps1
Custom engine: ./play.ps1 -Godot 'C:/path/to/godot.exe'
Real Foundation owner-chain fixture: ./play.ps1 -Foundation
Alternatively import project/project.godot into Godot and press F5 (P01).

P01 controls: W/A/S/D move; Q/E or left mouse drag changes perspective;
Space switches Surface/Inner; R resets; F3 toggles debug.
Foundation fixture controls: D move, Q world rotation, Space shift, R reset.
Foundation is a technical integration fixture; P01 is the default playable scene.

This package includes source and assets, with no bundled engine or export templates.
No project export settings were added. First launch imports assets and creates a local .godot cache.
Daily smoke evidence is separate at $SmokeEvidenceName; see the repository .godot/beta-sprint/ directory.
Independent process restart is checked by the daily smoke; Shell Restart-menu UI is not claimed.
Do not run graphical smoke and build checks concurrently: focus changes can interrupt gameplay input.
build-manifest.json records snapshot hashes and independent copied-project import/boot verification.
"@ | Set-Content -LiteralPath (Join-Path $dailyBuild 'README.md') -Encoding utf8
foreach ($dailyCheck in @(
    @{name='import';args=@('--headless','--editor','--import')},
    @{name='p01_boot';args=@('--max-fps','60','--quit-after','120')},
    @{name='foundation_boot';args=@('--max-fps','60','--quit-after','120','res://prototype/foundation/runtime/foundation_runtime.tscn')}
)) {
    $dailyOut = Join-Path $dailyEvidence "$($dailyCheck.name).stdout.log"
    $dailyErr = Join-Path $dailyEvidence "$($dailyCheck.name).stderr.log"
    $dailyResult = [ordered]@{stage=$dailyCheck.name;status='PENDING';exit_code=$null;timed_out=$false;stdout=$dailyOut;stderr=$dailyErr}
    $dailyChild = $null
    try {
        if (Test-Path -LiteralPath $Godot) {
            $dailyChild = Start-Process -FilePath $Godot -ArgumentList (@('--path',('"'+$dailyProject+'"')) + $dailyCheck.args) -WindowStyle Hidden -PassThru -RedirectStandardOutput $dailyOut -RedirectStandardError $dailyErr
            if (-not $dailyChild.WaitForExit(120000)) { $dailyResult.timed_out=$true; $dailyChild.Kill(); $dailyChild.WaitForExit() }
            $dailyChild.WaitForExit()
            $dailyResult.exit_code=$dailyChild.ExitCode
            $dailyLog = (Get-Content -LiteralPath $dailyOut -Raw) + (Get-Content -LiteralPath $dailyErr -Raw)
            $dailyResult.status=if (-not $dailyResult.timed_out -and $dailyChild.ExitCode -eq 0 -and $dailyLog -notmatch 'SCRIPT ERROR:|ERROR:|FAIL:') { 'PASS' } else { 'FAIL' }
        }
    } catch { $dailyResult.status='FAIL'; $dailyResult.error=$_.Exception.Message }
    finally { if ($null -ne $dailyChild -and -not $dailyChild.HasExited) { $dailyChild.Kill(); $dailyChild.WaitForExit() } }
    $dailyInfo.verification += [pscustomobject]$dailyResult
    Write-Output "$($dailyCheck.name): $($dailyResult.status)"
}
# Remove only the generated cache in the freshly created approved build snapshot.
$dailyCache = [IO.Path]::GetFullPath((Join-Path $dailyProject '.godot'))
if (-not $dailyCache.StartsWith($dailyBuild + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Cache cleanup escaped this build.' }
if (Test-Path -LiteralPath $dailyCache) { Remove-Item -LiteralPath $dailyCache -Recurse -Force }
$dailyInfo | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $dailyBuild 'build-manifest.json') -Encoding utf8
$dailyInfo | ConvertTo-Json -Depth 7 | Set-Content -LiteralPath (Join-Path $dailyEvidence 'build-manifest.json') -Encoding utf8
Add-Type -AssemblyName System.IO.Compression.FileSystem
$dailyZip = $dailyBuild + '.zip'
if (Test-Path -LiteralPath $dailyZip) { throw 'Preserve prior zip; choose a fresh build name.' }
[IO.Compression.ZipFile]::CreateFromDirectory($dailyBuild,$dailyZip,[IO.Compression.CompressionLevel]::Optimal,$true)
[pscustomobject]@{zip=$dailyZip;sha256=(Get-FileHash -LiteralPath $dailyZip -Algorithm SHA256).Hash.ToLowerInvariant();bytes=(Get-Item -LiteralPath $dailyZip).Length;package_kind='SOURCE_PLAYABLE_NOT_EXE'} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $dailyEvidence 'archive.json') -Encoding utf8
Write-Output "SOURCE_PLAYABLE_NOT_EXE: $dailyBuild; archive=$dailyZip; evidence=$dailyEvidence"
if (@($dailyInfo.verification | Where-Object status -EQ 'FAIL').Count) { exit 1 }
if (@($dailyInfo.verification | Where-Object status -EQ 'PENDING').Count) { exit 2 }
exit 0
