param([Parameter(Mandatory)][string]$SourceCommit)
$ErrorActionPreference='Stop'
$polishBindRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../../..')).Path
$polishBindPath=Join-Path $PSScriptRoot 'DELIVERY_BINDING.json'
$polishBase='e4fe5365334e93138dc9b8856d09670478789abc'
if($SourceCommit -notmatch '^[0-9a-f]{40}$' -or (git -C $polishBindRoot rev-parse HEAD).Trim() -ne $SourceCommit){throw 'Exact current source HEAD required'}
if(Test-Path -LiteralPath $polishBindPath){throw 'Binding append-only'}
git -C $polishBindRoot merge-base --is-ancestor $polishBase $SourceCommit
if($LASTEXITCODE -ne 0){throw 'Wrong base'}
foreach($path in @(git -C $polishBindRoot diff --name-only $polishBase $SourceCommit)){
 if($path -ne 'experiments/spatial_puzzle_batch_01/ui/main.gd' -and $path -notmatch '^(tests/beta_sprint/spatial_owner_07/polish_03/|docs/beta-sprint/spatial-puzzle-batch-01/ui/polish_03/)'){throw "Owner scope violation: $path"}
}
$polishRunPath=Join-Path $PSScriptRoot 'evidence/reset_full_02/run_report.json'
$polishCasePath=Join-Path $PSScriptRoot 'evidence/reset_full_02/report.json'
$polishRun=Get-Content -LiteralPath $polishRunPath -Raw | ConvertFrom-Json
$polishCase=Get-Content -LiteralPath $polishCasePath -Raw | ConvertFrom-Json
if($polishRun.status -ne 'PASS' -or $polishRun.source_drift -ne $false -or $polishRun.exit_code -ne 0 -or $polishRun.stderr_bytes -ne 0 -or $polishRun.checks -le 0 -or $polishRun.failures.Count -ne 0 -or $polishRun.base -ne $polishBase){throw 'Run not valid PASS'}
if($polishCase.checks -ne $polishRun.checks -or $polishCase.pid -ne $polishRun.pid -or $polishCase.failures.Count -ne 0 -or $polishCase.display -ne 'headless' -or $polishRun.graphical -ne 'NOT_RUN' -or $polishRun.human_qa -ne 'NOT_RUN'){throw 'Case/process/scope mismatch'}
if(Get-Process -Id $polishRun.pid -ErrorAction SilentlyContinue){throw 'Recorded PID currently exists; inspect before exit claim'}
$polishBound=[Collections.Generic.HashSet[string]]::new()
foreach($source in $polishRun.source_files){
 if(-not $polishBound.Add($source.path)){throw 'Duplicate source'}
 if((Get-FileHash -LiteralPath (Join-Path $polishBindRoot $source.path)).Hash.ToLowerInvariant() -ne $source.sha256){throw "Live differs from tested: $($source.path)"}
 $polishGitInfo=[Diagnostics.ProcessStartInfo]::new('git')
 $polishGitInfo.UseShellExecute=$false; $polishGitInfo.CreateNoWindow=$true; $polishGitInfo.RedirectStandardOutput=$true; $polishGitInfo.RedirectStandardError=$true
 foreach($arg in @('-C',$polishBindRoot,'cat-file','blob',($SourceCommit+':'+$source.path))){$polishGitInfo.ArgumentList.Add($arg)}
 $polishGit=[Diagnostics.Process]::Start($polishGitInfo); $polishBytes=[IO.MemoryStream]::new()
 $polishGit.StandardOutput.BaseStream.CopyTo($polishBytes); $polishGitError=$polishGit.StandardError.ReadToEnd(); $polishGit.WaitForExit()
 if($polishGit.ExitCode -ne 0 -or $polishGitError.Length){throw 'Git blob read failed'}
 $polishHash=[Convert]::ToHexString([Security.Cryptography.SHA256]::HashData($polishBytes.ToArray())).ToLowerInvariant()
 $polishBytes.Dispose(); $polishGit.Dispose()
 if($polishHash -ne $source.sha256){throw "Committed bytes differ from tested: $($source.path)"}
}
foreach($cache in $polishRun.import_cache_files){if((Get-FileHash -LiteralPath (Join-Path $polishBindRoot $cache.path)).Hash.ToLowerInvariant() -ne $cache.sha256){throw 'Cache drift'}}
if((Get-FileHash -LiteralPath $polishRun.engine_path).Hash.ToLowerInvariant() -ne $polishRun.engine_sha256){throw 'Engine drift'}
$polishBinding=[ordered]@{task=$polishRun.task;defect=$polishRun.defect;base=$polishBase;source_commit=$SourceCommit;worktree=$polishBindRoot;branch=(git -C $polishBindRoot branch --show-current).Trim();status='TESTED_LIVE_GIT_BLOBS_MATCH';source_files=$polishBound.Count;import_cache_matches=$polishRun.import_cache_files.Count;engine_sha256=$polishRun.engine_sha256;checks=$polishRun.checks;pid=$polishRun.pid;process_exited=$true;report_sha256=(Get-FileHash -LiteralPath $polishRunPath).Hash.ToLowerInvariant();case_report_sha256=(Get-FileHash -LiteralPath $polishCasePath).Hash.ToLowerInvariant();execution_head=$polishRun.execution_head;execution_dirty=$polishRun.execution_dirty;production_change='experiments/spatial_puzzle_batch_01/ui/main.gd only';host_runtime_goal_save_maps_tokens_project_unchanged=$true;graphical='NOT_RUN';human_qa='NOT_RUN';integration='PENDING_00';push='NOT_RUN_AT_BINDING_CREATION';publication_receipt='Current chat final Handoff after ordinary Owner Push and independent remote SHA verification'}
[IO.File]::WriteAllText($polishBindPath,($polishBinding | ConvertTo-Json -Depth 14).Replace("`r`n","`n")+"`n",[Text.UTF8Encoding]::new($false))
Write-Output "Bound $($polishBound.Count) tested/live/Git blobs to $SourceCommit; $($polishRun.checks) PASS checks, exited PID$($polishRun.pid), cache$($polishRun.import_cache_files.Count)"
