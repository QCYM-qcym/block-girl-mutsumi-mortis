param([Parameter(Mandatory)][string]$SourceCommit)
$ErrorActionPreference='Stop'
$feedbackBindRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../../..')).Path
$feedbackBindingPath=Join-Path $PSScriptRoot 'DELIVERY_BINDING.json'
$feedbackBase='088d4ba815884a431f44e73d93cfb6881ff7faa3'
if ($SourceCommit -notmatch '^[0-9a-f]{40}$' -or (git -C $feedbackBindRoot rev-parse HEAD).Trim() -ne $SourceCommit) { throw 'Use actual current full source commit SHA' }
if (Test-Path -LiteralPath $feedbackBindingPath) { throw 'Binding is append-only' }
git -C $feedbackBindRoot merge-base --is-ancestor $feedbackBase $SourceCommit
if ($LASTEXITCODE -ne 0) { throw 'Wrong base' }
foreach ($feedbackChanged in @(git -C $feedbackBindRoot diff --name-only $feedbackBase $SourceCommit)) {
 if ($feedbackChanged -notmatch '^(tests/beta_sprint/spatial_owner_07/feedback_02/|docs/beta-sprint/spatial-puzzle-batch-01/ui/feedback_02/)') { throw "Owner scope violation: $feedbackChanged" }
}
$feedbackReportPath=Join-Path $PSScriptRoot 'evidence/feedback02_final_01/run_report.json'
$feedbackRun=Get-Content -LiteralPath $feedbackReportPath -Raw | ConvertFrom-Json
if ($feedbackRun.status -ne 'PASS' -or $feedbackRun.source_drift -ne $false -or $feedbackRun.checks -le 0 -or $feedbackRun.source_files.Count -eq 0 -or $feedbackRun.base -ne $feedbackBase) { throw 'Run is not valid PASS' }
if ($feedbackRun.display -ne 'headless' -or $feedbackRun.graphical -ne 'NOT_RUN' -or $feedbackRun.human_qa -ne 'NOT_RUN' -or $feedbackRun.migration -ne 'PRE_MIGRATION_BASELINE') { throw 'Scope mismatch' }
$feedbackBound=[Collections.Generic.HashSet[string]]::new()
foreach ($feedbackSource in $feedbackRun.source_files) {
 if (-not $feedbackBound.Add($feedbackSource.path)) { throw 'Duplicate source entry' }
 if ((Get-FileHash -LiteralPath (Join-Path $feedbackBindRoot $feedbackSource.path)).Hash.ToLowerInvariant() -ne $feedbackSource.sha256) { throw "Live source mismatch: $($feedbackSource.path)" }
 $feedbackGitInfo=[Diagnostics.ProcessStartInfo]::new('git')
 $feedbackGitInfo.UseShellExecute=$false; $feedbackGitInfo.CreateNoWindow=$true
 $feedbackGitInfo.RedirectStandardOutput=$true; $feedbackGitInfo.RedirectStandardError=$true
 foreach ($feedbackGitArg in @('-C',$feedbackBindRoot,'cat-file','blob',($SourceCommit+':'+$feedbackSource.path))) { $feedbackGitInfo.ArgumentList.Add($feedbackGitArg) }
 $feedbackGitProcess=[Diagnostics.Process]::Start($feedbackGitInfo)
 $feedbackBlob=[IO.MemoryStream]::new()
 $feedbackGitProcess.StandardOutput.BaseStream.CopyTo($feedbackBlob)
 $feedbackGitError=$feedbackGitProcess.StandardError.ReadToEnd(); $feedbackGitProcess.WaitForExit()
 if ($feedbackGitProcess.ExitCode -ne 0 -or $feedbackGitError.Length -ne 0) { throw "Cannot read committed blob: $($feedbackSource.path)" }
 $feedbackBlobHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($feedbackBlob.ToArray())).ToLowerInvariant()
 $feedbackBlob.Dispose(); $feedbackGitProcess.Dispose()
 if ($feedbackBlobHash -ne $feedbackSource.sha256) { throw "Git blob differs from tested bytes: $($feedbackSource.path)" }
}
foreach ($feedbackCache in $feedbackRun.import_cache_files) { if ((Get-FileHash -LiteralPath (Join-Path $feedbackBindRoot $feedbackCache.path)).Hash.ToLowerInvariant() -ne $feedbackCache.sha256) { throw 'Import cache drift' } }
if ((Get-FileHash -LiteralPath $feedbackRun.engine_path).Hash.ToLowerInvariant() -ne $feedbackRun.engine_sha256) { throw 'Engine drift' }
if ($feedbackRun.stages.Count -ne 3 -or @($feedbackRun.stages.pid | Sort-Object -Unique).Count -ne 3) { throw 'Three actual distinct processes required' }
$feedbackTotal=0
$feedbackRaw=[Collections.Generic.List[object]]::new()
foreach ($feedbackStage in $feedbackRun.stages) {
 if ($feedbackStage.status -ne 'PASS' -or $feedbackStage.exit_code -ne 0 -or $feedbackStage.stderr_bytes -ne 0 -or $feedbackStage.checks -le 0 -or $feedbackStage.failures.Count -ne 0) { throw 'Invalid stage' }
 if (Get-Process -Id $feedbackStage.pid -ErrorAction SilentlyContinue) { throw 'Test PID currently exists; inspect before claiming exit' }
 $feedbackPhasePath=Join-Path $PSScriptRoot "evidence/feedback02_final_01/$($feedbackStage.phase)/report.json"
 $feedbackPhase=Get-Content -LiteralPath $feedbackPhasePath -Raw | ConvertFrom-Json
 if ($feedbackPhase.phase -ne $feedbackStage.phase -or $feedbackPhase.pid -ne $feedbackStage.pid -or $feedbackPhase.checks -ne $feedbackStage.checks -or $feedbackPhase.failures.Count -ne 0 -or $feedbackPhase.display -ne 'headless') { throw 'Actual phase report mismatch' }
 $feedbackTotal += [int]$feedbackStage.checks
 $feedbackRaw.Add([ordered]@{phase=$feedbackStage.phase;pid=$feedbackStage.pid;checks=$feedbackStage.checks;report_sha256=(Get-FileHash -LiteralPath $feedbackPhasePath).Hash.ToLowerInvariant()})
}
if ($feedbackTotal -ne $feedbackRun.checks) { throw 'Actual check aggregation mismatch' }
$feedbackSeed=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'evidence/feedback02_final_01/loop_seed/report.json') -Raw | ConvertFrom-Json
$feedbackCold=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'evidence/feedback02_final_01/loop_restore/report.json') -Raw | ConvertFrom-Json
if ($feedbackCold.loop.seed_pid -ne $feedbackSeed.pid -or $feedbackCold.loop.restore_pid -ne $feedbackCold.pid -or $feedbackCold.pid -eq $feedbackSeed.pid -or $feedbackCold.loop.restore_user_data_dir -ne $feedbackSeed.user_data_dir -or $feedbackCold.loop.restored_key -ne $feedbackSeed.loop.initial_key -or $feedbackCold.loop.restored_key -eq $feedbackSeed.loop.looped_key -or $feedbackCold.loop.commits -ne 0) { throw 'Cold full-StateKey/process proof invalid' }
$feedbackBinding=[ordered]@{
 source_commit=$SourceCommit;base=$feedbackBase;worktree=$feedbackBindRoot;branch=(git -C $feedbackBindRoot branch --show-current).Trim();status='TESTED_LIVE_GIT_BLOBS_MATCH';
 report='feedback02_final_01';report_sha256=(Get-FileHash -LiteralPath $feedbackReportPath).Hash.ToLowerInvariant();execution_head=$feedbackRun.execution_head;execution_dirty=$feedbackRun.execution_dirty;
 unique_source_files=$feedbackBound.Count;import_cache_matches=$feedbackRun.import_cache_files.Count;engine_sha256=$feedbackRun.engine_sha256;checks=$feedbackTotal;stages=@($feedbackRaw.ToArray());processes_exited=$true;
 scope='PRE_MIGRATION_BASELINE';graphical='NOT_RUN';human_qa='NOT_RUN';final_migrated_integration='PENDING_00';
 original_save_store_and_ui_tokens_unchanged=$true;push='NOT_RUN_AT_BINDING_CREATION';publication_receipt='Final task handoff after ordinary Push and independent remote SHA verification'
}
[IO.File]::WriteAllText($feedbackBindingPath,($feedbackBinding | ConvertTo-Json -Depth 14).Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false))
Write-Output "Bound $($feedbackBound.Count) tested/live/Git blobs to $SourceCommit; $feedbackTotal checks, 3 exited PIDs, $($feedbackRun.import_cache_files.Count) cache files"
