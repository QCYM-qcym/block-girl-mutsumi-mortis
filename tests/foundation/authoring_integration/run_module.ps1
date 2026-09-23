#requires -Version 7.4
<# I0 test infrastructure, not the product wire/task service.
Cases write results.json under FOUNDATION_TEST_EVIDENCE. The real 4B QA driver
also receives --case, --mode, --evidence-dir after --. No watchdog/forced kill.
The receipt commit R refers to the earlier implementation H, never itself. #>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Module,
    [Parameter(Mandatory)][string]$Case,
    [Parameter(Mandatory)][string]$Mode,
    [Parameter(Mandatory)][string]$EvidenceName,
    [string]$Godot = 'D:/APP/steam/steamapps/common/Godot Engine/godot.windows.opt.tools.64.exe'
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath("$PSScriptRoot/../../..").Replace('\','/')
$baseCommit = 'bd393303d3a21ae3ddebc6643a94a114437365a3'
$slots = @('BASE','I_HARNESS','A_SCHEMA','A_BAKE','A_EDIT','D_PROTOCOL','D_SAVED','D_HOST','D_JOBS','D_FULL','C_QUALITY','B_EDITOR')
$evidence = $null
$sourceFiles = @()
$receipts = $null

function Write-Json($Path, $Value) {
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 50), [Text.UTF8Encoding]::new($false))
}
function Read-Json($Path) {
    # ConvertFrom-Json alone accepts duplicate fields.
    $doc = [Text.Json.JsonDocument]::Parse([IO.File]::ReadAllText($Path))
    function Check-Keys($Node) {
        if ($Node.ValueKind -eq [Text.Json.JsonValueKind]::Object) {
            $keys = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
            foreach ($p in $Node.EnumerateObject()) {
                if (-not $keys.Add($p.Name)) { throw "Duplicate JSON field: $($p.Name)" }
                Check-Keys $p.Value
            }
        } elseif ($Node.ValueKind -eq [Text.Json.JsonValueKind]::Array) {
            foreach ($item in $Node.EnumerateArray()) { Check-Keys $item }
        }
    }
    try { Check-Keys $doc.RootElement } finally { $doc.Dispose() }
    return ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($Path)) -AsHashtable
}
function Assert-Fields($Value, [string[]]$Names) {
    if ($Value -isnot [Collections.IDictionary] -or $Value.Count -ne $Names.Count) { throw 'Closed schema field count/type mismatch' }
    foreach ($key in $Value.Keys) { if ($Names -cnotcontains $key) { throw "Unknown field: $key" } }
}
function Assert-Strings($Value) {
    if ($Value -isnot [array]) { throw 'Expected an array of strings' }
    foreach ($item in $Value) { if ($item -isnot [string]) { throw 'Expected string element' } }
}
function Assert-Path([string]$Path) {
    if ($Path -notmatch '^[A-Za-z0-9_./-]+$' -or $Path -match '(^/|//|(^|/)\.\.?(/|$))') { throw "Unsafe repository path: $Path" }
}
function Assert-NoLink([string]$Path) {
    $cursor = [IO.Path]::GetFullPath($Path)
    while ($cursor) {
        if ((Test-Path -LiteralPath $cursor) -and ((Get-Item -Force -LiteralPath $cursor).Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Linked path is not allowed: $cursor" }
        $cursor = [IO.Path]::GetDirectoryName($cursor)
    }
}
function Get-Sha([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Git-Text([string[]]$GitArgs) {
    $value = & git -C $root @GitArgs 2>&1
    if ($LASTEXITCODE -ne 0) { throw "git $GitArgs failed: $value" }
    return ($value -join "`n").Trim()
}
function Is-Ancestor([string]$Commit) {
    & git -C $root merge-base --is-ancestor $Commit HEAD 2>$null
    if ($LASTEXITCODE -gt 1) { throw "Invalid/unavailable commit: $Commit" }
    return $LASTEXITCODE -eq 0
}
function Blob-Sha([string]$Commit, [string]$Path) {
    $info = [Diagnostics.ProcessStartInfo]::new('git')
    $info.UseShellExecute = $false; $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    foreach ($a in @('-C',$root,'show',"${Commit}:$Path")) { $info.ArgumentList.Add($a) }
    $p = [Diagnostics.Process]::Start($info)
    $err = $p.StandardError.ReadToEndAsync()
    $hash = [Security.Cryptography.SHA256]::HashData($p.StandardOutput.BaseStream)
    $p.WaitForExit()
    try {
        if ($p.ExitCode -ne 0) { throw "Missing receipt blob ${Commit}:$Path $($err.Result)" }
        return [Convert]::ToHexString($hash).ToLowerInvariant()
    } finally { $p.Dispose() }
}
function Invoke-Engine([string[]]$EngineArgs, [string]$Directory, [string]$TestMode) {
    $Directory = [IO.Path]::GetFullPath($Directory).Replace('\','/')
    New-Item -ItemType Directory -Path $Directory -Force | Out-Null
    New-Item -ItemType Directory -Path "$Directory/foundation-test-user" -Force | Out-Null
    $info = [Diagnostics.ProcessStartInfo]::new($Godot)
    $info.UseShellExecute = $false; $info.CreateNoWindow = $true
    $info.WindowStyle = [Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput = $true; $info.RedirectStandardError = $true
    $info.WorkingDirectory = $root
    foreach ($a in $EngineArgs) { $info.ArgumentList.Add($a) }
    foreach ($key in @('TEMP','TMP','APPDATA','LOCALAPPDATA')) { $info.Environment[$key] = $Directory }
    $info.Environment['FOUNDATION_TEST_EVIDENCE'] = $Directory
    $info.Environment['FOUNDATION_TEST_MODE'] = $TestMode
    $outFile = [IO.File]::Create("$Directory/stdout.log")
    $errFile = [IO.File]::Create("$Directory/stderr.log")
    $p = [Diagnostics.Process]::new(); $p.StartInfo = $info
    $record = @{arguments=$EngineArgs; mode=$TestMode; status='NOT_STARTED'; exit_code=$null; started_at=[DateTimeOffset]::Now.ToString('o')}
    try {
        [void]$p.Start()
        $record.status = 'RUNNING_PENDING_RELEASE'; $record.pid = $p.Id
        Write-Json "$Directory/process.json" $record
        $outTask = $p.StandardOutput.BaseStream.CopyToAsync($outFile)
        $errTask = $p.StandardError.BaseStream.CopyToAsync($errFile)
        $p.WaitForExit()
        $null = $outTask.GetAwaiter().GetResult(); $null = $errTask.GetAwaiter().GetResult()
        $record.exit_code = $p.ExitCode; $record.status = 'EXITED'
        $record.finished_at = [DateTimeOffset]::Now.ToString('o')
        Write-Json "$Directory/process.json" $record
        return $record.exit_code
    } finally { $outFile.Dispose(); $errFile.Dispose(); $p.Dispose() }
}
function Assert-CleanLogs([string]$Directory) {
    if ((Get-Item -LiteralPath "$Directory/stderr.log").Length -ne 0) { throw "Nonempty stderr: $Directory/stderr.log" }
    if ([IO.File]::ReadAllText("$Directory/stdout.log") -match '(?m)(SCRIPT ERROR:|Parse Error:|^ERROR:|^WARNING:.*ObjectDB)') { throw "Engine error in stdout: $Directory" }
}
function Assert-Manifest($Manifest) {
    Assert-Fields $Manifest @('manifest_version','cases')
    if ($Manifest.manifest_version -isnot [string] -or $Manifest.manifest_version -cne '1' -or $Manifest.cases -isnot [array]) { throw 'Unsupported manifest version/type' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $tasks = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    $planText = (Get-Content "$root/docs/superpowers/plans/2026-09-23-foundation*plan.md" -Raw) -join "`n"
    foreach ($c in $Manifest.cases) {
        Assert-Fields $c @('module','case_id','mode','script','entry','required_slots','allows_double')
        foreach ($key in @('module','case_id','mode','script','entry')) { if ($c[$key] -isnot [string]) { throw "Case $key must be string" } }
        if (@('4A','4B','4C','4D','Integration') -cnotcontains $c.module -or @('Unit','Real','Graphical','Editor') -cnotcontains $c.mode -or @('SELF_CHECK','SCENE_TREE','EDITOR') -cnotcontains $c.entry -or $c.allows_double -isnot [bool]) { throw 'Invalid case enum/type' }
        $idPattern = switch ($c.module) { '4A' {'^4A-[1-4]$'} '4B' {'^4B-[1-4]$'} '4C' {'^4C-[1-3]$'} '4D' {'^4D-[1-7]$'} 'Integration' {'^I[0-4]$'} }
        if ($c.case_id -cnotmatch $idPattern -or -not $seen.Add("$($c.module)/$($c.case_id)/$($c.mode)")) { throw 'Unknown/duplicate case ID or combination' }
        [void]$tasks.Add($c.case_id)
        if (-not $c.script.StartsWith('res://tests/foundation/', [StringComparison]::Ordinal)) { throw 'Case must be a registered test resource' }
        $path = $c.script.Substring(6); Assert-Path $path
        if (-not $planText.Contains('`' + $path + '`')) { throw "Case path not owned by approved plans: $path" }
        if (($c.mode -ceq 'Editor' -or $c.module -ceq '4B' -or $c.case_id -ceq '4D-5') -and $c.entry -cne 'EDITOR') { throw 'Editor case must use actual QA entry' }
        if (($c.entry -ceq 'SELF_CHECK') -ne ($c.case_id -ceq 'I0')) { throw 'SELF_CHECK belongs only to I0' }
        if ($c.allows_double -and $c.mode -cne 'Unit') { throw 'Only Unit permits doubles' }
        Assert-Strings $c.required_slots
        if ($c.required_slots.Count -ne @($c.required_slots | Select-Object -Unique).Count) { throw 'Duplicate slot' }
        foreach ($slot in $c.required_slots) { if ($slots -cnotcontains $slot) { throw "Unknown slot $slot" } }
        if ($c.required_slots -cnotcontains 'BASE' -or ($c.case_id -cne 'I0' -and $c.required_slots -cnotcontains 'I_HARNESS')) { throw 'Missing foundational slot' }
        if ($c.case_id -ceq 'I0' -and ($c.mode -cne 'Unit' -or $c.required_slots.Count -ne 1)) { throw 'I0 requires only BASE in Unit' }
    }
    $expected = @('4A-1','4A-2','4A-3','4A-4','4B-1','4B-2','4B-3','4B-4','4C-1','4C-2','4C-3','4D-1','4D-2','4D-3','4D-4','4D-5','4D-6','4D-7','I0','I1','I2','I3','I4')
    if ($tasks.Count -ne $expected.Count) { throw 'Incomplete task registry' }
    foreach ($id in $expected) { if (-not $tasks.Contains($id)) { throw "Missing task $id" } }
    foreach ($match in [regex]::Matches($planText, '-Module (4[A-D]|Integration) -Case ([A-Z0-9-]+) -Mode (Unit|Real|Graphical|Editor)')) {
        if (-not $seen.Contains("$($match.Groups[1].Value)/$($match.Groups[2].Value)/$($match.Groups[3].Value)")) { throw "Missing approved case/mode: $($match.Value)" }
    }
    if (-not $seen.Contains('4B/4B-1/Editor')) { throw 'B1 requires follow-up real Editor mode' }
}
function Assert-Receipts($Value) {
    Assert-Fields $Value @('schema_version','base_commit','engine','deliveries')
    if ($Value.schema_version -isnot [string] -or $Value.schema_version -cne '1' -or $Value.base_commit -cne $baseCommit -or $Value.deliveries -isnot [array]) { throw 'Invalid receipt version/BASE/deliveries' }
    Assert-Fields $Value.engine @('path','sha256','version')
    foreach ($key in @('path','sha256','version')) { if ($Value.engine[$key] -isnot [string]) { throw 'Invalid engine identity' } }
    if ($Value.engine.sha256 -cnotmatch '^[a-f0-9]{64}$' -or -not [IO.Path]::IsPathFullyQualified($Value.engine.path)) { throw 'Invalid engine path/hash' }
    $seen = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach ($d in $Value.deliveries) {
        Assert-Fields $d @('slot','commit','paths')
        if ($d.slot -isnot [string] -or $slots -cnotcontains $d.slot -or $d.slot -ceq 'BASE' -or -not $seen.Add($d.slot)) { throw 'Unknown/duplicate delivery slot' }
        if ($d.commit -isnot [string] -or $d.commit -cnotmatch '^[a-f0-9]{40}$' -or $d.paths -isnot [array] -or $d.paths.Count -eq 0) { throw 'Invalid delivery commit/paths' }
        $paths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        foreach ($item in $d.paths) {
            Assert-Fields $item @('path','sha256')
            if ($item.path -isnot [string] -or $item.sha256 -isnot [string] -or $item.sha256 -cnotmatch '^[a-f0-9]{64}$') { throw 'Invalid delivery path/hash' }
            Assert-Path $item.path
            if (-not $paths.Add($item.path) -or $item.path.EndsWith('/dependency_receipts.json')) { throw 'Duplicate/self-referential receipt path' }
        }
    }
}
function Get-Missing($Registration) {
    $missing = [Collections.Generic.List[string]]::new()
    foreach ($slot in $Registration.required_slots) {
        if ($slot -ceq 'BASE') { continue }
        $delivery = @($receipts.deliveries | Where-Object { $_.slot -ceq $slot })
        if ($delivery.Count -eq 0) { $missing.Add("slot:$slot"); continue }
        $d = $delivery[0]
        & git -C $root cat-file -e "$($d.commit)^{commit}" 2>$null
        if ($LASTEXITCODE -ne 0) { $missing.Add("commit:$slot/$($d.commit)"); continue }
        if (-not (Is-Ancestor $d.commit)) { $missing.Add("not_integrated:$slot/$($d.commit)"); continue }
        foreach ($item in $d.paths) {
            if ((Blob-Sha $d.commit $item.path) -cne $item.sha256) { throw "CONTRACT_MISMATCH: $slot committed blob $($item.path)" }
            $file = "$root/$($item.path)"; Assert-NoLink $file
            if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { $missing.Add("file:$($item.path)"); continue }
            if ((Get-Sha $file) -cne $item.sha256) { throw "CONTRACT_MISMATCH: $slot checkout differs: $($item.path)" }
        }
    }
    if (-not (Test-Path -LiteralPath "$root/$($Registration.script.Substring(6))" -PathType Leaf)) { $missing.Add("script:$($Registration.script)") }
    if ($Registration.entry -ceq 'EDITOR') {
        foreach ($path in @('tests/foundation/editor/plugin.cfg','tests/foundation/editor/editor_test_driver.gd','addons/block_girl_level_tools/plugin.cfg','addons/block_girl_level_tools/plugin.gd')) {
            if (-not (Test-Path -LiteralPath "$root/$path" -PathType Leaf)) { $missing.Add("editor:$path") }
        }
    }
    return $missing.ToArray()
}
function New-Project([string]$Project, [string]$TestMode, [bool]$SelfCheck) {
    New-Item -ItemType Directory -Path $Project | Out-Null
    $copied = @(); $excluded = @()
    foreach ($item in $sourceFiles) {
        if ($SelfCheck -and $item.path -notmatch '/test_suite\.gd(\.uid)?$') { continue }
        if ($TestMode -cne 'Unit' -and $item.path -match '(?i)(_double\.gd(\.uid)?$|/doubles/|/owned_worker_fixture\.gd(\.uid)?$)') { $excluded += $item.path; continue }
        $target = "$Project/$($item.path)"
        New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($target)) -Force | Out-Null
        Copy-Item -LiteralPath "$root/$($item.path)" -Destination $target
        if ((Get-Sha $target) -cne $item.sha256) { throw "Source changed during copy: $($item.path)" }
        $copied += $item
    }
    $config = [IO.File]::ReadAllText("$root/project.godot")
    $config = [regex]::Replace($config, '(?m)^(run/main_scene|config/icon)=.*\r?\n', '')
    $config = [regex]::Replace($config, '(?ms)^\[editor_plugins\].*?(?=^\[|\z)', '')
    $config = [regex]::Replace($config, '(?m)^config/(use_custom_user_dir|custom_user_dir_name)=.*\r?\n', '')
    $config = $config.Replace('[application]', "[application]`nconfig/use_custom_user_dir=true`nconfig/custom_user_dir_name=`"foundation-test-user`"")
    [IO.File]::WriteAllText("$Project/project.godot", $config)
    Write-Json "$Project/../source-copy.json" @{files=$copied; excluded_doubles=$excluded; project_sha256=(Get-Sha "$Project/project.godot")}
}
function Test-Result([int]$ExitCode, [string]$Directory, [string]$TestMode, [bool]$AllowsDouble) {
    Assert-CleanLogs $Directory
    $r = Read-Json "$Directory/results.json"
    Assert-Fields $r @('checks','failures','mode','display','doubles')
    if (($r.checks -isnot [long] -and $r.checks -isnot [int]) -or $r.checks -le 0) { throw 'NOT_RUN: checks must be a positive integer' }
    Assert-Strings $r.failures; Assert-Strings $r.doubles
    if ($r.mode -isnot [string] -or $r.mode -cne $TestMode -or $r.display -isnot [string] -or [string]::IsNullOrWhiteSpace($r.display)) { throw 'Result mode/display mismatch' }
    if ($TestMode -cin @('Graphical','Editor') -and $r.display -ceq 'headless') { throw 'Real graphical display required' }
    $loadedDoubles = @([regex]::Matches([IO.File]::ReadAllText("$Directory/stdout.log"), '(?im)^Loading resource: (res://\S+?)(?: remapped:|\r?$)') | ForEach-Object { $_.Groups[1].Value } | Where-Object { $_ -match '(?i)(_double\.gd$|/doubles/|/owned_worker_fixture\.gd$)' } | Select-Object -Unique)
    if (($TestMode -cne 'Unit' -or -not $AllowsDouble) -and ($r.doubles.Count -gt 0 -or $loadedDoubles.Count -gt 0)) { throw 'Double forbidden in this case/mode' }
    foreach ($path in $loadedDoubles) { if ($r.doubles -cnotcontains $path) { throw "Unreported loaded double: $path" } }
    if ($ExitCode -ne 0 -or $r.failures.Count -ne 0) { throw "Case failed: exit=$ExitCode failures=$($r.failures -join '; ')" }
    return $r
}
function Invoke-SelfCheck([string]$Directory) {
    $project = "$Directory/project"; New-Project $project 'Unit' $true
    $suite = 'res://tests/foundation/authoring_integration/test_suite.gd'
    [IO.File]::WriteAllText("$project/probe_double.gd", "extends RefCounted`n")
    # Literal expectations; every negative child retains its own raw logs/result.
    $probes = @(
        @{name='assertion_failure'; body='check(false, "harness must reject a real failing assertion")'; expected=1; raw=1; checks=1; failure='harness must reject a real failing assertion'},
        @{name='success'; body="await process_frame`n`tcheck(true, `"actual asynchronous check`")`n`tcheck(OS.get_user_data_dir().replace(char(92), char(47)).begins_with(evidence_dir() + char(47)), `"user data is isolated under evidence`")"; expected=0; raw=0},
        @{name='zero_checks'; body='pass'; expected=1; raw=1; checks=0; failure='NOT_RUN: no checks executed'},
        @{name='stderr_error'; body="check(true, `"ran`")`n`tpush_error(`"injected script error`")"; expected=1; raw=0},
        @{name='declared_double'; body="check(true, `"ran`")`n`tdoubles.append(`"tests-only injected port`")"; expected=1; raw=0; mode='Real'},
        @{name='unreported_port'; body='check(load("res://probe_double.gd") != null, "real resource load")'; expected=1; raw=0},
        @{name='forbidden_port'; body='check(load("res://probe_double.gd") != null, "real resource load")'; expected=1; raw=0; mode='Real'},
        @{name='reported_port'; body="check(load(`"res://probe_double.gd`") != null, `"real resource load`")`n`tdoubles.append(`"res://probe_double.gd`")"; expected=0; raw=0},
        @{name='exit_zero_failure'; raw=0; expected=1; json='{"checks":1,"failures":["intentional failure"],"mode":"Unit","display":"headless","doubles":[]}'},
        @{name='unknown_field'; raw=0; expected=1; json='{"checks":1,"failures":[],"mode":"Unit","display":"headless","doubles":[],"pass":true}'},
        @{name='wrong_mode'; raw=0; expected=1; json='{"checks":1,"failures":[],"mode":"Real","display":"headless","doubles":[]}'},
        @{name='fractional_checks'; raw=0; expected=1; json='{"checks":1.5,"failures":[],"mode":"Unit","display":"headless","doubles":[]}'},
        @{name='duplicate_field'; raw=0; expected=1; json='{"checks":1,"checks":2,"failures":[],"mode":"Unit","display":"headless","doubles":[]}'},
        @{name='pass_text_only'; raw=0; expected=1; no_result=$true}
    )
    foreach ($probe in $probes) {
        $body = if ($probe.ContainsKey('json')) {
            "var f = FileAccess.open(evidence_dir().path_join(`"results.json`"), FileAccess.WRITE)`n`tf.store_string('" + $probe.json + "')`n`tf.close()`n`tquit(0)"
        } elseif ($probe.ContainsKey('no_result')) { "print(`"PASS`")`n`tquit(0)" } else { $probe.body + "`n`tfinish()" }
        [IO.File]::WriteAllText("$project/$($probe.name).gd", "extends `"$suite`"`nfunc run() -> void:`n`t$body`n")
    }
    $importExit = Invoke-Engine @('--headless','--path',$project,'--editor','--import') "$Directory/import" 'Unit'
    Assert-CleanLogs "$Directory/import"
    if ($importExit -ne 0) { throw 'Self-check resource import failed' }
    $observations = @(); $failures = @()
    foreach ($probe in $probes) {
        $dir = "$Directory/$($probe.name)"
        $testMode = if ($probe.ContainsKey('mode')) { $probe.mode } else { 'Unit' }
        $raw = Invoke-Engine @('--headless','--verbose','--path',$project,'--script',"res://$($probe.name).gd") $dir $testMode
        $classification = 0; $reason = ''
        try { $null = Test-Result $raw $dir $testMode ($testMode -ceq 'Unit') } catch { $classification = 1; $reason = $_.Exception.Message }
        $ok = $raw -eq $probe.raw -and $classification -eq $probe.expected
        if ($probe.ContainsKey('failure')) {
            # A parse error is not proof that check()/finish() handled a failure.
            try {
                Assert-CleanLogs $dir
                $proof = Read-Json "$dir/results.json"
                Assert-Fields $proof @('checks','failures','mode','display','doubles')
                Assert-Strings $proof.failures; Assert-Strings $proof.doubles
                if (($proof.checks -isnot [long] -and $proof.checks -isnot [int]) -or
                    $proof.checks -ne $probe.checks -or $proof.failures.Count -ne 1 -or
                    $proof.failures[0] -cne $probe.failure -or $proof.mode -cne 'Unit' -or
                    $proof.display -cne 'headless' -or $proof.doubles.Count -ne 0) {
                    throw 'Intended failure was not actually executed and reported'
                }
            } catch { $ok = $false; $reason = "Missing intended failure proof: $($_.Exception.Message)" }
        }
        if (-not $ok) { $failures += "$($probe.name): expected raw=$($probe.raw)/class=$($probe.expected), observed $raw/$classification : $reason" }
        $observation = @{name=$probe.name; raw_exit=$raw; classified_exit=$classification; expected_exit=$probe.expected; matched=$ok; reason=$reason; injection='isolated child result/exit boundary'}
        Write-Json "$dir/classification.json" $observation; $observations += $observation
    }
    # Run the actual missing-dependency and aggregation functions in a separate
    # PowerShell child. Private SELF_CHECK registration never enters the manifest.
    $pendingDir = "$Directory/missing_dependency"
    New-Item -ItemType Directory -Path $pendingDir | Out-Null
    $child = "Set-StrictMode -Version Latest`n`$ErrorActionPreference='Stop'`n`$root='" + $project.Replace("'","''") + "'`n"
    foreach ($fn in @('Write-Json','Get-Missing','Invoke-Case','Complete-Run')) { $child += "function $fn {`n" + (Get-Item "Function:$fn").Definition + "`n}`n" }
    $child += "`$registration=@{case_id='missing';required_slots=@('BASE');script='res://not_created.gd';entry='SCENE_TREE'}`n"
    $child += "`$r=Invoke-Case `$registration '" + "$pendingDir/case".Replace("'","''") + "'`n"
    $child += "exit (Complete-Run @(`$r) '" + $pendingDir.Replace("'","''") + "')`n"
    [IO.File]::WriteAllText("$pendingDir/probe.ps1", $child)
    $pendingText = & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -File "$pendingDir/probe.ps1" 2>"$pendingDir/stderr.log"
    $pendingExit = $LASTEXITCODE
    [IO.File]::WriteAllText("$pendingDir/stdout.log", ($pendingText -join "`n"))
    $pendingOK = $pendingExit -eq 2 -and $pendingText -ceq 'DEPENDENCY_PENDING' -and (Get-Item "$pendingDir/stderr.log").Length -eq 0
    if (-not $pendingOK) { $failures += 'Missing dependency was not classified as pending / exit 2' }
    $observations += @{name='missing_dependency';raw_exit=$pendingExit;classified_exit=$pendingExit;expected_exit=2;matched=$pendingOK}
    Write-Json "$Directory/observations.json" $observations
    $r = @{checks=$observations.Count;failures=@($failures);mode='Unit';display='headless';doubles=@('isolated result/exit fault injection children')}
    Write-Json "$Directory/results.json" $r
    return $r
}
function Invoke-Case($Registration, [string]$Directory) {
    New-Item -ItemType Directory -Path $Directory | Out-Null
    try {
        $missing = @(Get-Missing $Registration)
        if ($missing.Count -gt 0) {
            $r = @{case_id=$Registration.case_id;status='DEPENDENCY_PENDING';exit_code=2;missing=$missing;checks=0;failures=@();doubles=@();display='NOT_RUN'}
            Write-Json "$Directory/case.json" $r
            return $r
        }
        if ($Registration.entry -ceq 'SELF_CHECK') { $result = Invoke-SelfCheck $Directory }
        else {
            $project = "$Directory/project"; New-Project $project $Registration.mode $false
            if ($Registration.entry -ceq 'EDITOR') {
                # Editor filesystem scans must not execute unrelated test scripts.
                # The real QA driver loads its registered case explicitly by res://.
                [IO.File]::WriteAllText("$project/tests/.gdignore", '')
            }
            $importExit = Invoke-Engine @('--headless','--path',$project,'--editor','--import') "$Directory/import" $Registration.mode
            Assert-CleanLogs "$Directory/import"
            if ($importExit -ne 0) { throw 'Resource import failed' }
            $engineArgs = @('--verbose','--path',$project)
            if ($Registration.entry -ceq 'EDITOR') {
                $qa = "$project/addons/foundation_authoring_qa"; New-Item -ItemType Directory -Path $qa | Out-Null
                $cfg = [IO.File]::ReadAllText("$project/tests/foundation/editor/plugin.cfg")
                if ($cfg -notmatch '(?m)^script=') { throw 'Invalid 4B QA plugin configuration' }
                $cfg = [regex]::Replace($cfg, '(?m)^script=.*$', 'script="../../tests/foundation/editor/editor_test_driver.gd"')
                [IO.File]::WriteAllText("$qa/plugin.cfg", $cfg)
                [IO.File]::AppendAllText("$project/project.godot", "`n[editor_plugins]`nenabled=PackedStringArray(`"res://addons/block_girl_level_tools/plugin.cfg`", `"res://addons/foundation_authoring_qa/plugin.cfg`")`n")
                $engineArgs += '--editor'
            } else {
                if ($Registration.mode -cin @('Unit','Real')) { $engineArgs += '--headless' }
                $engineArgs += @('--script',$Registration.script)
            }
            $engineArgs += @('--','--case',$Registration.case_id,'--mode',$Registration.mode,'--evidence-dir',"$Directory/run")
            Write-Json "$Directory/launch-project.json" @{sha256=(Get-Sha "$project/project.godot");entry=$Registration.entry;script=$Registration.script}
            $raw = Invoke-Engine $engineArgs "$Directory/run" $Registration.mode
            $result = Test-Result $raw "$Directory/run" $Registration.mode $Registration.allows_double
            if ($Registration.entry -ceq 'EDITOR' -and $result.display -ceq 'headless') { throw 'QA requires a graphical Editor, including Unit' }
        }
        $exit = if ($result.checks -gt 0 -and $result.failures.Count -eq 0) {0} else {1}
        $r = @{case_id=$Registration.case_id;status=$(if ($exit -eq 0) {'PASS'} else {'FAIL'});exit_code=$exit;checks=$result.checks;failures=$result.failures;doubles=$result.doubles;display=$result.display}
    } catch { $r = @{case_id=$Registration.case_id;status='FAIL';exit_code=1;checks=0;failures=@($_.Exception.Message);doubles=@();display='UNKNOWN'} }
    Write-Json "$Directory/case.json" $r
    return $r
}
function Complete-Run($Results, [string]$Directory) {
    $exitCode = if (@($Results | Where-Object exit_code -EQ 1).Count) {1} elseif (@($Results | Where-Object exit_code -EQ 2).Count) {2} else {0}
    $status = @('PASS','FAIL','DEPENDENCY_PENDING')[$exitCode]
    Write-Json "$Directory/summary.json" @{status=$status;exit_code=$exitCode;cases=@($Results);finished_at=[DateTimeOffset]::Now.ToString('o')}
    [Console]::WriteLine($status)
    return $exitCode
}
try {
    if (@('4A','4B','4C','4D','Integration') -cnotcontains $Module -or @('Unit','Real','Graphical','Editor') -cnotcontains $Mode) { throw 'Unknown module/mode' }
    if ($EvidenceName -cnotmatch '^[A-Za-z0-9][A-Za-z0-9_-]{0,99}$' -or $EvidenceName -match '^(CON|PRN|AUX|NUL|COM[0-9]|LPT[0-9])$') { throw 'Unsafe EvidenceName' }
    if ($root -notmatch '^E:/') { throw 'Evidence/source must be on the authorized E drive' }
    $targetEvidence = "$root/.godot/foundation-authoring-tests/$EvidenceName"; Assert-NoLink $targetEvidence
    # Exclusive reservation: existing evidence is never modified.
    New-Item -ItemType Directory -Path $targetEvidence -ErrorAction Stop | Out-Null
    $evidence = $targetEvidence
    $manifest = Read-Json "$PSScriptRoot/case_manifest.json"; Assert-Manifest $manifest
    $receipts = Read-Json "$PSScriptRoot/dependency_receipts.json"; Assert-Receipts $receipts
    $selected = @($manifest.cases | Where-Object { $_.module -ceq $Module -and $_.mode -ceq $Mode -and ($Case -ceq 'All' -or $_.case_id -ceq $Case) })
    if ($selected.Count -eq 0) { throw 'Unknown module/case/mode combination' }
    if (-not (Is-Ancestor $baseCommit)) { throw 'Checkout does not contain authorized BASE' }
    if (-not [IO.Path]::IsPathFullyQualified($Godot) -or -not (Test-Path -LiteralPath $Godot -PathType Leaf)) { throw 'Godot must be an existing absolute executable' }
    $Godot = [IO.Path]::GetFullPath($Godot); $engineHash = Get-Sha $Godot
    if ($engineHash -cne $receipts.engine.sha256) { throw 'Engine hash differs from bound receipt' }
    $versionExit = Invoke-Engine @('--version') "$evidence/engine" $Mode
    Assert-CleanLogs "$evidence/engine"
    $version = [IO.File]::ReadAllText("$evidence/engine/stdout.log").Trim()
    if ($versionExit -ne 0 -or $version -cne $receipts.engine.version) { throw 'Engine version differs from bound receipt' }
    $files = & git -C $root -c core.quotepath=false ls-files --cached --others --exclude-standard -- foundation tools/foundation prototype/foundation tests/foundation addons/block_girl_level_tools project.godot
    if ($LASTEXITCODE -ne 0) { throw 'Source inventory failed' }
    foreach ($file in @($files | Sort-Object -Unique)) {
        Assert-NoLink "$root/$file"
        if (Test-Path -LiteralPath "$root/$file" -PathType Leaf) { $sourceFiles += @{path=$file;sha256=(Get-Sha "$root/$file")} }
    }
    $identity = @{base_commit=$baseCommit;head=(Git-Text @('rev-parse','HEAD'));branch=(Git-Text @('branch','--show-current'));status=(Git-Text @('status','--porcelain'));engine=@{path=$Godot;sha256=$engineHash;version=$version};arguments=$PSBoundParameters;mode=$Mode;sources=$sourceFiles;receipts=$receipts;started_at=[DateTimeOffset]::Now.ToString('o')}
    Write-Json "$evidence/identity.json" $identity
    $results = @()
    foreach ($registration in $selected) { $results += Invoke-Case $registration "$evidence/$($registration.case_id)" }
    foreach ($item in $sourceFiles) { if ((Get-Sha "$root/$($item.path)") -cne $item.sha256) { throw "Source changed during run: $($item.path)" } }
    exit (Complete-Run $results $evidence)
} catch {
    if ($evidence) { Write-Json "$evidence/summary.json" @{status='FAIL';exit_code=1;failures=@($_.Exception.Message)} }
    [Console]::Error.WriteLine($_.Exception.Message)
    exit 1
}
