#requires -Version 7.4
<# Focused local validation only. The shared I2 Graphical gate remains binding.
The separate Real run is DIRECT_LOCAL_PREFLIGHT, outside a D4 controlled job;
its checks cannot establish D_JOBS delivery, graphical replay or I2 core PASS. #>
[CmdletBinding()]
param(
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe',
    [string]$EvidenceName = ('p1_' + [DateTime]::Now.ToString('yyyyMMdd_HHmmss') + '_' + [guid]::NewGuid().ToString('N').Substring(0,8))
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath("$PSScriptRoot/../..").Replace('\','/')
$directory = $null
$summary = [ordered]@{scope='DIRECT_LOCAL_PREFLIGHT';formal_harness_pass=$false;i2_core_pass=$false;i2_status='NOT_RUN';preflight_status='NOT_RUN';started_at=[DateTimeOffset]::Now.ToString('o')}

function Write-Json([string]$Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 60), [Text.UTF8Encoding]::new($false))
}
function Get-Sha([string]$Path) { (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Git-Text([string[]]$GitArgs) {
    $value = & git -C $root @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "Git failed: $($GitArgs -join ' ')" }
    return (@($value) -join "`n")
}
function Invoke-Recorded([string]$Executable, [string[]]$ProcessArgs, [string]$Destination, [string]$Scope) {
    New-Item -ItemType Directory -Path $Destination | Out-Null
    $info = [Diagnostics.ProcessStartInfo]::new($Executable)
    $info.UseShellExecute=$false; $info.CreateNoWindow=$true
    $info.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput=$true; $info.RedirectStandardError=$true
    $info.WorkingDirectory=$root
    foreach ($argument in $ProcessArgs) { $info.ArgumentList.Add($argument) }
    foreach ($key in @('TEMP','TMP','APPDATA','LOCALAPPDATA')) { $info.Environment[$key]=$Destination }
    $info.Environment['FOUNDATION_TEST_EVIDENCE']=$Destination
    $info.Environment['FOUNDATION_TEST_MODE']='Real'
    $outFile=[IO.File]::Create("$Destination/stdout.log")
    $errFile=[IO.File]::Create("$Destination/stderr.log")
    $process=[Diagnostics.Process]::new(); $process.StartInfo=$info
    $ownedStarted=$false
    $timeoutSeconds=if ($Scope -ceq 'SHARED_I2_GRAPHICAL_GATE_ONLY') {300} else {120}
    $record=[ordered]@{executable=$Executable;arguments=$ProcessArgs;scope=$Scope;timeout_seconds=$timeoutSeconds;timed_out=$false;status='NOT_STARTED';exit_code=$null;started_at=[DateTimeOffset]::Now.ToString('o')}
    try {
        [void]$process.Start()
        $ownedStarted=$true
        $record.status='RUNNING'; $record.pid=$process.Id
        Write-Json "$Destination/process.json" $record
        $outTask=$process.StandardOutput.BaseStream.CopyToAsync($outFile)
        $errTask=$process.StandardError.BaseStream.CopyToAsync($errFile)
        if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
            $record.timed_out=$true
            $record.status='TIMED_OUT'
            $process.Kill($true) # Only this invocation's owned process tree.
            if (-not $process.WaitForExit(10000)) { throw 'Owned process did not exit after timeout cleanup' }
        }
        $null=$outTask.GetAwaiter().GetResult(); $null=$errTask.GetAwaiter().GetResult()
        $record.exit_code=$process.ExitCode
        if (-not $record.timed_out) { $record.status='EXITED' }
        $record.finished_at=[DateTimeOffset]::Now.ToString('o')
        Write-Json "$Destination/process.json" $record
        if ($record.timed_out) { throw "Owned $Scope invocation exceeded ${timeoutSeconds}s; raw logs retained" }
        return $process.ExitCode
    } finally {
        try {
            if ($ownedStarted -and -not $process.HasExited) {
                $process.Kill($true)
                $record.status='ABORTED_OWNED_PROCESS_CLEANUP'
                $record.cleanup_exit_confirmed=$process.WaitForExit(10000)
                $record.finished_at=[DateTimeOffset]::Now.ToString('o')
                Write-Json "$Destination/process.json" $record
            }
        } finally { $process.Dispose(); $outFile.Dispose(); $errFile.Dispose() }
    }
}
function Assert-CleanLogs([string]$Destination) {
    if ((Get-Item -LiteralPath "$Destination/stderr.log").Length -ne 0) { throw "Nonempty stderr: $Destination" }
    if ([IO.File]::ReadAllText("$Destination/stdout.log") -match '(?m)(SCRIPT ERROR:|Parse Error:|^ERROR:|^WARNING:.*ObjectDB)') { throw "Engine error in stdout: $Destination" }
}
try {
    if ($root -notmatch '^E:/' -or $EvidenceName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,35}$' -or $EvidenceName -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$') { throw 'Unsafe evidence location/name' }
    $candidateDirectory="$root/.godot/beta-sprint/foundation-preflight/$EvidenceName"
    New-Item -ItemType Directory -Path $candidateDirectory -ErrorAction Stop | Out-Null
    $directory=$candidateDirectory
    $summary.evidence=$directory
    if (-not [IO.Path]::IsPathFullyQualified($Godot) -or -not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Godot must be an existing absolute executable' }
    $Godot=[IO.Path]::GetFullPath($Godot)
    $receipts=Get-Content -LiteralPath "$root/tests/foundation/authoring_integration/dependency_receipts.json" -Raw | ConvertFrom-Json
    $engineHash=Get-Sha $Godot
    if ($engineHash -cne $receipts.engine.sha256) { throw 'Engine hash differs from the existing receipt' }
    $productionRoots=@('foundation','tools/foundation','prototype/foundation','addons/block_girl_level_tools','project.godot')
    $dirty=Git-Text (@('diff','--name-only','HEAD','--') + $productionRoots)
    $untracked=Git-Text (@('ls-files','--others','--exclude-standard','--') + $productionRoots)
    if ($dirty -or $untracked) { throw "Selected checkout has uncommitted Owner production bytes: $dirty $untracked" }
    $tracked=@(& git -C $root -c core.quotepath=false ls-files)
    if ($LASTEXITCODE -ne 0) { throw 'Source inventory failed' }
    $sourceFiles=@()
    foreach ($path in $tracked) {
        if ($path -match '(?i)\.(gd|uid|tscn|tres|godot|cfg|json)$' -or $path -match '^docs/.+\.md$') {
            $sourceFiles += @{path=$path;sha256=(Get-Sha "$root/$path")}
        }
    }
    $identity=[ordered]@{scope='DIRECT_LOCAL_PREFLIGHT';head=(Git-Text @('rev-parse','HEAD'));branch=(Git-Text @('branch','--show-current'));status=(Git-Text @('status','--porcelain'));owner_source_dirty=@();script=@{path='tests/beta_sprint/run_foundation_preflight.ps1';sha256=(Get-Sha $PSCommandPath)};engine=@{path=$Godot;sha256=$engineHash;expected_version=$receipts.engine.version};tracked_sources=$sourceFiles;receipts=$receipts;started_at=$summary.started_at}
    Write-Json "$directory/identity.json" $identity
    $versionExit=Invoke-Recorded $Godot @('--version') "$directory/engine" 'ENGINE_IDENTITY'
    Assert-CleanLogs "$directory/engine"
    $version=[IO.File]::ReadAllText("$directory/engine/stdout.log").Trim()
    if ($versionExit -ne 0 -or $version -cne $receipts.engine.version) { throw 'Engine version differs from the existing receipt' }

    # The unchanged shared wrapper owns its native immutable evidence directory.
    # Preserve it and copy its raw gate result here; exit 2 is pending, never FAIL.
    $gateName='bpf_' + $EvidenceName
    $gateRoot="$root/.godot/foundation-authoring-tests/$gateName"
    if (Test-Path -LiteralPath $gateRoot) { throw 'Shared gate evidence already exists' }
    $gateExit=Invoke-Recorded (Join-Path $PSHOME 'pwsh.exe') @('-NoProfile','-File',"$root/tests/foundation/authoring_integration/run_module.ps1",'-Module','Integration','-Case','I2','-Mode','Graphical','-EvidenceName',$gateName,'-Godot',$Godot) "$directory/shared-gate-process" 'SHARED_I2_GRAPHICAL_GATE_ONLY'
    $summary.shared_gate_evidence=$gateRoot
    Copy-Item -LiteralPath $gateRoot -Destination "$directory/shared-gate-evidence" -Recurse
    $gate=Get-Content -LiteralPath "$gateRoot/summary.json" -Raw | ConvertFrom-Json
    $summary.i2_gate=$gate
    $summary.i2_status=$gate.status
    $missing=@($gate.cases[0].missing)
    if ($gateExit -ne 2 -or $gate.status -cne 'DEPENDENCY_PENDING' -or $gate.cases.Count -ne 1 -or $missing.Count -ne 1 -or $missing[0] -cne 'slot:D_JOBS') { throw 'I2 gate did not report the expected exact D_JOBS pending dependency' }

    # Copy exact tracked source bytes; capture_saved creates its run packages in
    # this disposable project, so all local capture/cache outputs stay in evidence.
    $project="$directory/project"
    New-Item -ItemType Directory -Path $project | Out-Null
    $copied=@()
    foreach ($item in $sourceFiles) {
        if ($item.path -notmatch '^(foundation/|tools/foundation/|prototype/foundation/|tests/foundation/|addons/block_girl_level_tools/|project\.godot$)') { continue }
        $target="$project/$($item.path)"
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
        Copy-Item -LiteralPath "$root/$($item.path)" -Destination $target
        if ((Get-Sha $target) -cne $item.sha256) { throw "Source changed during copy: $($item.path)" }
        $copied += $item
    }
    $config=[IO.File]::ReadAllText("$project/project.godot")
    $config=[regex]::Replace($config,'(?m)^(run/main_scene|config/icon)=.*\r?\n','')
    $config=[regex]::Replace($config,'(?ms)^\[editor_plugins\].*?(?=^\[|\z)','')
    [IO.File]::WriteAllText("$project/project.godot",$config,[Text.UTF8Encoding]::new($false))
    Write-Json "$directory/source-copy.json" @{scope='DIRECT_LOCAL_PREFLIGHT';files=$copied;effective_project_sha256=(Get-Sha "$project/project.godot");config_projection='Remove unrelated main_scene, icon and editor_plugins for disposable test project'}
    $importExit=Invoke-Recorded $Godot @('--headless','--path',$project,'--editor','--import') "$directory/import" 'DIRECT_LOCAL_PREFLIGHT_IMPORT'
    Assert-CleanLogs "$directory/import"
    if ($importExit -ne 0) { throw 'Disposable project import failed' }
    $summary.preflight_status='RUNNING'
    # The original test localizes this directory into res:// source URIs.
    # It must remain inside the disposable project, below its ignored cache.
    $local="$project/.godot/local-preflight"
    $summary.local_evidence=$local
    Write-Json "$directory/summary.json" $summary
    $localExit=Invoke-Recorded $Godot @('--headless','--verbose','--path',$project,'--script','res://tests/foundation/authoring_integration/test_quality_replay.gd') $local 'DIRECT_LOCAL_PREFLIGHT'
    Assert-CleanLogs $local
    $result=Get-Content -LiteralPath "$local/results.json" -Raw | ConvertFrom-Json
    $summary.preflight_exit_code=$localExit
    $summary.preflight_result=$result
    if ($localExit -ne 0 -or $result.checks -le 0 -or $result.failures.Count -ne 0 -or $result.mode -cne 'Real' -or $result.display -cne 'headless' -or $result.doubles.Count -ne 0) { throw 'Local headless preflight failed' }
    if ([IO.File]::ReadAllText("$local/stdout.log") -match '(?im)^Loading resource: res://\S*(?:_double\.gd|/doubles/|/owned_worker_fixture\.gd)') { throw 'Algorithm/port double was loaded during local preflight' }
    foreach ($item in $sourceFiles) { if ((Get-Sha "$root/$($item.path)") -cne $item.sha256) { throw "Tracked source changed during run: $($item.path)" } }
    $summary.preflight_status='LOCAL_PREFLIGHT_PASS'
    $summary.finished_at=[DateTimeOffset]::Now.ToString('o')
    Write-Json "$directory/summary.json" $summary
    $summary | ConvertTo-Json -Depth 20
    exit 0
} catch {
    $summary.preflight_status='LOCAL_PREFLIGHT_FAIL'
    $summary.failure=$_.Exception.Message
    $summary.finished_at=[DateTimeOffset]::Now.ToString('o')
    if ($directory -and (Test-Path -LiteralPath $directory)) { Write-Json "$directory/summary.json" $summary }
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
