param([Parameter(Mandatory)][string]$SourceCommit)
$ErrorActionPreference='Stop'
if ($SourceCommit -notmatch '^[0-9a-f]{40}$') { throw 'Use an actual full source commit SHA' }
$spatialBindRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).Path
$spatialBindPath=Join-Path $PSScriptRoot 'DELIVERY_BINDING.json'
if (Test-Path -LiteralPath $spatialBindPath) { throw 'Binding is append-only' }
if ((git -C $spatialBindRoot rev-parse $SourceCommit).Trim() -ne $SourceCommit) { throw 'Commit missing' }
$spatialBoundSources=@{}
$spatialBindings=[Collections.Generic.List[object]]::new()
foreach ($spatialRunName in @('integrated_final_headless_01','integrated_renderer_02')) {
 $spatialReportPath=Join-Path $PSScriptRoot "evidence/$spatialRunName/run_report.json"
 $spatialReport=Get-Content -LiteralPath $spatialReportPath -Raw | ConvertFrom-Json
 if ($spatialReport.status -ne 'PASS' -or $spatialReport.source_drift -ne $false -or $spatialReport.behavioral_checks -le 0) { throw 'Run is not valid PASS' }
 foreach ($spatialSource in $spatialReport.source_files) {
  $spatialLiveHash=(Get-FileHash -LiteralPath (Join-Path $spatialBindRoot $spatialSource.path)).Hash.ToLowerInvariant()
  if ($spatialLiveHash -ne $spatialSource.sha256) { throw "Live source mismatch: $($spatialSource.path)" }
  if (-not $spatialBoundSources.ContainsKey($spatialSource.path)) {
   $spatialGitInfo=[Diagnostics.ProcessStartInfo]::new('git')
   $spatialGitInfo.UseShellExecute=$false; $spatialGitInfo.CreateNoWindow=$true
   $spatialGitInfo.RedirectStandardOutput=$true; $spatialGitInfo.RedirectStandardError=$true
   foreach ($spatialGitArg in @('-C',$spatialBindRoot,'cat-file','blob',($SourceCommit+':'+$spatialSource.path))) { $spatialGitInfo.ArgumentList.Add($spatialGitArg) }
   $spatialGitProcess=[Diagnostics.Process]::Start($spatialGitInfo)
   $spatialBlob=[IO.MemoryStream]::new()
   $spatialGitProcess.StandardOutput.BaseStream.CopyTo($spatialBlob)
   $spatialGitError=$spatialGitProcess.StandardError.ReadToEnd(); $spatialGitProcess.WaitForExit()
   if ($spatialGitProcess.ExitCode -ne 0 -or $spatialGitError.Length -ne 0) { throw "Cannot read committed blob: $($spatialSource.path)" }
   $spatialBlobHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($spatialBlob.ToArray())).ToLowerInvariant()
   $spatialBlob.Dispose(); $spatialGitProcess.Dispose()
   $spatialBoundSources[$spatialSource.path]=$spatialBlobHash
  }
  if ($spatialBoundSources[$spatialSource.path] -ne $spatialSource.sha256) { throw "Git blob differs from tested bytes: $($spatialSource.path)" }
 }
 foreach ($spatialCache in $spatialReport.import_cache_files) { if ((Get-FileHash -LiteralPath (Join-Path $spatialBindRoot $spatialCache.path)).Hash.ToLowerInvariant() -ne $spatialCache.sha256) { throw 'Import cache drift' } }
 if ((Get-FileHash -LiteralPath $spatialReport.engine_path).Hash.ToLowerInvariant() -ne $spatialReport.engine_sha256) { throw 'Engine drift' }
 foreach ($spatialStage in $spatialReport.stages) {
  if ($spatialStage.status -ne 'PASS' -or $spatialStage.exit_code -ne 0 -or $spatialStage.stderr_bytes -ne 0 -or $spatialStage.checks -le 0) { throw 'Invalid stage' }
  if (Get-Process -Id $spatialStage.pid -ErrorAction SilentlyContinue) { throw 'Test PID still exists; check before claiming release' }
 }
 if ($spatialReport.graphical -eq 'AUTOMATED_REAL_RENDERER') {
  $spatialMenu=Get-Content -LiteralPath (Join-Path $PSScriptRoot "evidence/$spatialRunName/menu/report.json") -Raw | ConvertFrom-Json
  if ($spatialMenu.display -ne 'Windows' -or $spatialMenu.captures.Count -ne 24) { throw 'Actual renderer evidence incomplete' }
  foreach ($spatialCapture in $spatialMenu.captures) { if ((Get-FileHash -LiteralPath (Join-Path $PSScriptRoot "evidence/$spatialRunName/menu/$($spatialCapture.path)")).Hash.ToLowerInvariant() -ne $spatialCapture.sha256) { throw 'PNG drift' } }
 }
 $spatialBindings.Add([ordered]@{run=$spatialRunName;report_sha256=(Get-FileHash -LiteralPath $spatialReportPath).Hash.ToLowerInvariant();execution_head=$spatialReport.head;execution_dirty=$spatialReport.dirty;checks=$spatialReport.behavioral_checks;display=$spatialReport.display;tested_live_git_blob_matches=$spatialReport.source_files.Count;import_cache_matches=$spatialReport.import_cache_files.Count;processes_exited=$true;source_drift=$false;engine_sha256=$spatialReport.engine_sha256;human_qa='NOT_RUN'})
}
$spatialBinding=[ordered]@{source_commit=$SourceCommit;worktree=$spatialBindRoot;branch=(git -C $spatialBindRoot branch --show-current).Trim();base='7442e8172e865d093ff1e73570d891f60d9134af';integrated_dependency='9386f4a084cbd1132c94ab9277a40106cd1d2cb7';status='TESTED_LIVE_GIT_BLOBS_MATCH';unique_source_files=$spatialBoundSources.Count;runs=@($spatialBindings.ToArray());approved_save_store_and_ui_tokens_unchanged=$true;owner_scope='07 Menu/Save/UI lifecycle only';full_batch_acceptance='Coordinator/QA responsibility';push='NOT_RUN'}
if (@(git -C $spatialBindRoot diff 7442e8172e865d093ff1e73570d891f60d9134af -- game/shell/save_store.gd game/shell/visual_01/tokens.gd production/ui/beta_shell_01).Count -ne 0) { throw 'Approved Store/theme drift' }
[IO.File]::WriteAllText($spatialBindPath,($spatialBinding | ConvertTo-Json -Depth 14)+"`n",[Text.UTF8Encoding]::new($false))
Write-Output "Bound $($spatialBoundSources.Count) exact tested/live/Git blobs to $SourceCommit; all recorded test PIDs exited"
