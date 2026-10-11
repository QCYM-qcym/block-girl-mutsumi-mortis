param([string]$ReferenceRoot='E:/godot/worktrees/block-girl-game-feel-ui')
$ErrorActionPreference='Stop'
$spatialCacheRoot=(Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../..')).Path
$spatialCacheRecords=[Collections.Generic.List[object]]::new()
foreach ($spatialImport in @(git -C $spatialCacheRoot ls-files 'production/ui/beta_shell_01/*.import' 'production/ui/beta_shell_01/**/*.import')) {
 $spatialImportFull=Join-Path $spatialCacheRoot $spatialImport
 $spatialImportText=Get-Content -LiteralPath $spatialImportFull -Raw
 if ($spatialImportText -notmatch '(?m)^source_file="res://([^"]+)"') { throw 'Import source absent' }
 $spatialAsset=$Matches[1]
 if ((Get-FileHash -LiteralPath (Join-Path $spatialCacheRoot $spatialAsset)).Hash -ne (Get-FileHash -LiteralPath (Join-Path $ReferenceRoot $spatialAsset)).Hash -or (Get-FileHash -LiteralPath $spatialImportFull).Hash -ne (Get-FileHash -LiteralPath (Join-Path $ReferenceRoot $spatialImport)).Hash) { throw 'Approved asset/import reference differs' }
 if ($spatialImportText -notmatch '(?m)^path="res://(\.godot/imported/[^"]+)"') { throw 'Unexpected import destination' }
 $spatialCacheRel=$Matches[1]; $spatialCacheFrom=Join-Path $ReferenceRoot $spatialCacheRel; $spatialCacheTo=Join-Path $spatialCacheRoot $spatialCacheRel
 $spatialResolvedCache=[IO.Path]::GetFullPath($spatialCacheTo); $spatialIntendedCache=[IO.Path]::GetFullPath((Join-Path $spatialCacheRoot '.godot/imported/'))
 if (-not $spatialResolvedCache.StartsWith($spatialIntendedCache,[StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $spatialCacheFrom)) { throw 'Invalid/missing approved cache file' }
 New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($spatialResolvedCache)) -Force | Out-Null
 Copy-Item -LiteralPath $spatialCacheFrom -Destination $spatialResolvedCache
 $spatialCacheRecords.Add([ordered]@{path=$spatialCacheRel;sha256=(Get-FileHash -LiteralPath $spatialResolvedCache).Hash.ToLowerInvariant();asset=$spatialAsset;asset_sha256=(Get-FileHash -LiteralPath (Join-Path $spatialCacheRoot $spatialAsset)).Hash.ToLowerInvariant();reference=$ReferenceRoot})
}
if ($spatialCacheRecords.Count -le 0) { throw 'No actual approved theme cache copied' }
New-Item -ItemType Directory -Path (Join-Path $spatialCacheRoot '.godot/spatial-ui') -Force | Out-Null
[IO.File]::WriteAllText((Join-Path $spatialCacheRoot '.godot/spatial-ui/theme_cache_reference.json'),(@($spatialCacheRecords.ToArray()) | ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
Write-Output "Prepared $($spatialCacheRecords.Count) byte-verified approved theme import files; no importer/shared files changed"
