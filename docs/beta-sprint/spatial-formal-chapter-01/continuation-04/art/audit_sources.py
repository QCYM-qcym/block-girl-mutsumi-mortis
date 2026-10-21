"""Bounded, read-only provenance search. Writes JSON only to a fresh evidence directory.

Never invokes Blender, renderers, generators, GUI, extraction or source writes.
Run: python audit_sources.py <fresh-output-directory>
"""
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import zipfile
from datetime import datetime, timezone

ART = Path('E:/Study/方块娘项目/若叶睦/model/art')
BUILDS = Path('E:/godot/beta-sprint-builds')
SOURCE = ART / 'production/work/GAME_ART_MECHANICS_BATCH_01'
BACKUP = SOURCE.with_name(SOURCE.name + '_SCOPE_RECOVERY_20261013')
TARGETS = ['design/states/face_lock_D.svg', 'design/states/face_lock_D.png', 'reports/DRAWING_CONTACT_SHEET.png']
NEEDLE = re.compile(r'face_lock|drawing_contact_sheet|game_art_mechanics_batch_01', re.I)
EXCLUDED = {'.git', '.godot', 'qa-profile', 'node_modules', '__pycache__'}
MAX_FILES = 100000
MAX_ARCHIVES = 60
MAX_ARCHIVE_ENTRIES = 50000
MAX_MEMBER_BYTES = 16 * 1024 * 1024
MAX_IMAGE_BYTES = 2 * 1024 * 1024 * 1024
TEXT_SUFFIXES = {'.json', '.md', '.txt', '.log', '.py', '.js', '.mjs', '.html', '.csv'}

def digest(path):
    with path.open('rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()

def identity(path):
    return {'path': path.as_posix(), 'bytes': path.stat().st_size, 'sha256': digest(path)}

def inventory(root):
    files = []
    for here, dirs, names in os.walk(root, followlinks=False):
        dirs[:] = sorted(d for d in dirs if d not in EXCLUDED and not Path(here, d).is_symlink())
        for name in sorted(names):
            p = Path(here, name)
            if p.is_symlink():
                continue
            files.append(p)
            if len(files) > MAX_FILES:
                raise RuntimeError('Inventory budget exceeded; narrow scope, do not infer absence')
    return files

def main():
    out = Path(sys.argv[1]).resolve()
    if out.exists() or out.parent != BUILDS:
        raise ValueError('Evidence destination must be fresh and directly under beta-sprint-builds')
    manifest = json.loads((SOURCE / 'tests/PACKAGE_SHA256.json').read_text(encoding='utf-8-sig'))
    old = {r['path'].replace('\\', '/'): r['sha256'] for r in manifest}
    watched = [SOURCE / t for t in TARGETS] + [BACKUP / t for t in TARGETS]
    watched += [SOURCE / 'tests/PACKAGE_SHA256.json', SOURCE / 'GAME_ART_MECHANICS_BATCH_01_ASSET_MANIFEST.json',
                SOURCE / 'scripts/build_design_scenes.py', SOURCE / 'scripts/finalize_design_package.py',
                SOURCE / 'tests/blender_build.log', SOURCE / 'tests/BLENDER_REOPEN.json', SOURCE / 'design/greybox/face_lock_D01.blend']
    before = [identity(p) for p in watched]
    art_files = inventory(ART)
    # Build directories: top-level package manifests and recursive indices within the
    # dated playable builds only; never user profiles, caches or unrelated QA captures.
    build_dirs = sorted(p for p in BUILDS.iterdir() if p.is_dir() and (p.name.startswith('beta_') or p.name.startswith('source_daily_')))
    build_files = []
    for p in build_dirs:
        build_files.extend(inventory(p))
    archives = sorted({p for p in art_files + list(BUILDS.iterdir()) if p.is_file() and p.suffix.lower() == '.zip'})
    if len(archives) > MAX_ARCHIVES:
        raise RuntimeError('Archive count budget exceeded')
    result = {'task': 'SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_04', 'owner': '05 Art',
              'checked_utc': datetime.now(timezone.utc).isoformat(),
              'build_source_sha': '763f0132bc58360fab0e224d0e9c54e00c92ae90',
              'base_sha': 'b3f8fa9b8a6562a25342787317f6b42bc6b973b9',
              'branch': 'docs/spatial-formal-art-cont04', 'evidence_root': out.as_posix(),
              'budgets': {'files_per_inventory': MAX_FILES, 'archives': MAX_ARCHIVES, 'entries_per_archive': MAX_ARCHIVE_ENTRIES,
                          'read_member_max_bytes': MAX_MEMBER_BYTES, 'text_read_max_bytes': MAX_MEMBER_BYTES,
                          'image_hash_bytes_per_domain': MAX_IMAGE_BYTES,
                          'excluded_directory_names': sorted(EXCLUDED)},
              'scope': {'art_root': ART.as_posix(), 'art_file_count': len(art_files), 'build_directories': [p.as_posix() for p in build_dirs],
                        'build_file_count': len(build_files), 'archive_count': len(archives)},
              'files': [], 'archive_indices': [], 'unsupported_archives': [], 'build_manifests': [], 'source_records': [],
              'target_name_candidates': [], 'manifest_text_candidates': [], 'read_errors': [],
              'image_hash_scan': {'loose_scope': ART.as_posix(), 'loose_count': 0, 'loose_bytes': 0, 'archive_count': 0, 'archive_bytes': 0,
                                  'original_matches': [], 'oversize_skipped': []}}
    for target in TARGETS:
        result['files'].append({'path': target, 'original_sha256': old[target], 'current_sha256': digest(SOURCE / target),
                                'backup_sha256': digest(BACKUP / target)})
    for p in art_files + build_files:
        if p.is_relative_to(ART) and p.suffix.lower() in {'.svg', '.png'}:
            scan = result['image_hash_scan']
            size = p.stat().st_size
            if size > MAX_MEMBER_BYTES:
                scan['oversize_skipped'].append(p.as_posix())
            else:
                scan['loose_bytes'] += size
                if scan['loose_bytes'] > MAX_IMAGE_BYTES:
                    raise RuntimeError('Loose image byte budget exceeded')
                scan['loose_count'] += 1
                h = digest(p)
                if h in {old[t] for t in TARGETS}:
                    scan['original_matches'].append({'path': p.as_posix(), 'sha256': h})
        if p.name.casefold() in {Path(t).name.casefold() for t in TARGETS}:
            row = identity(p)
            row['matches_original'] = row['sha256'] in {old[t] for t in TARGETS}
            result['target_name_candidates'].append(row)
        if p.suffix.lower() in {'.7z', '.rar', '.tar', '.gz'}:
            result['unsupported_archives'].append(p.as_posix())
    for archive in archives:
        row = {'path': archive.as_posix(), 'bytes': archive.stat().st_size, 'sha256': digest(archive), 'relevant_members': []}
        with zipfile.ZipFile(archive) as z:
            entries = z.infolist()
            if len(entries) > MAX_ARCHIVE_ENTRIES:
                raise RuntimeError('Archive entry budget exceeded')
            row['entry_count'] = len(entries)
            row['index_sha256'] = hashlib.sha256(json.dumps([(i.filename, i.file_size, i.CRC) for i in entries], ensure_ascii=False).encode()).hexdigest()
            for i in entries:
                if Path(i.filename).suffix.lower() in {'.svg', '.png'}:
                    scan = result['image_hash_scan']
                    if i.file_size > MAX_MEMBER_BYTES:
                        scan['oversize_skipped'].append(archive.as_posix() + '!' + i.filename)
                    else:
                        scan['archive_bytes'] += i.file_size
                        if scan['archive_bytes'] > MAX_IMAGE_BYTES:
                            raise RuntimeError('Archive image byte budget exceeded')
                        scan['archive_count'] += 1
                        h = hashlib.sha256(z.read(i)).hexdigest()
                        if h in {old[t] for t in TARGETS}:
                            scan['original_matches'].append({'archive': archive.as_posix(), 'member': i.filename, 'sha256': h})
                if NEEDLE.search(i.filename):
                    member = {'name': i.filename, 'bytes': i.file_size, 'crc32': f'{i.CRC:08x}'}
                    if not i.is_dir() and i.file_size <= MAX_MEMBER_BYTES:
                        data = z.read(i)
                        member['sha256'] = hashlib.sha256(data).hexdigest()
                        member['matches_original'] = member['sha256'] in {old[t] for t in TARGETS}
                    row['relevant_members'].append(member)
        result['archive_indices'].append(row)
    for p in build_files:
        if p.name in {'BUILD_IDENTITY.json', 'BUILD_MANIFEST.json', 'PACKAGE_SHA256.json', 'ART_MANIFEST.json'} and p.stat().st_size <= MAX_MEMBER_BYTES:
            data = p.read_text(encoding='utf-8-sig', errors='replace')
            row = identity(p)
            row['needle_lines'] = [{'line': n, 'text': s[:1000]} for n, s in enumerate(data.splitlines(), 1) if NEEDLE.search(s) or any(old[t] in s for t in TARGETS)]
            try:
                obj = json.loads(data)
                if isinstance(obj, dict):
                    row['identity_fields'] = {k: v for k, v in obj.items() if k in {'task', 'kind', 'integration_commit', 'source_commit', 'created_utc', 'art', 'art_expansion_01'}}
            except json.JSONDecodeError:
                pass
            result['build_manifests'].append(row)
    # Read only source-qualified manifest/delivery records, plus named generation
    # sources. Do not scan photos, documents or general user data.
    for p in art_files:
        if p.suffix.lower() not in TEXT_SUFFIXES or p.stat().st_size > MAX_MEMBER_BYTES:
            continue
        if not re.search(r'manifest|handoff|delivery|package|blender_build|blender_reopen|build_design|finalize_design|drawing_index|generate_design', p.name, re.I):
            continue
        data = p.read_text(encoding='utf-8-sig', errors='replace')
        hits = [{'line': n, 'text': s[:1000]} for n, s in enumerate(data.splitlines(), 1) if NEEDLE.search(s) or any(old[t] in s for t in TARGETS)]
        row = identity(p)
        row['needle_lines'] = hits
        result['manifest_text_candidates'].append(row)
    selected = [p for p in watched if p not in [SOURCE / t for t in TARGETS] + [BACKUP / t for t in TARGETS]]
    selected += sorted((SOURCE / 'scripts').glob('*'))
    for p in sorted(set(selected)):
        if not p.is_file():
            continue
        row = identity(p)
        relative = p.relative_to(SOURCE).as_posix()
        row['original_manifest_sha256'] = old.get(relative)
        row['matches_original_manifest'] = row['sha256'] == old.get(relative) if relative in old else None
        if '.blend' in p.name:
            data = p.read_bytes()
            row['header_hex'] = data[:12].hex()
            row['literal_target_names'] = [t for t in TARGETS if Path(t).name.encode() in data]
            row['inspection_limit'] = 'Hash, header and literal bytes only; no Blender parse/open/render; missing literal names does not exclude packed data.'
        result['source_records'].append(row)
    result['readonly_before'] = before
    result['readonly_after'] = [identity(p) for p in watched]
    result['readonly_hashes_unchanged'] = result['readonly_before'] == result['readonly_after']
    read_records = {r['path']: r['sha256'] for key in ['archive_indices', 'build_manifests', 'source_records', 'manifest_text_candidates'] for r in result[key]}
    result['read_source_recheck_count'] = len(read_records)
    result['read_source_hash_drift'] = [p for p, h in read_records.items() if digest(Path(p)) != h]
    result['candidate_search_status'] = 'ORIGINAL_HASH_CANDIDATE_REQUIRES_PROVENANCE_REVIEW' if result['image_hash_scan']['original_matches'] else 'NO_ORIGINAL_HASH_MATCH_IN_SCANNED_SCOPE'
    out.mkdir()
    (out / 'ART_SOURCE_SEARCH.json').write_text(json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')
    print(json.dumps({'evidence': str(out), 'scope': result['scope'], 'archive_entries': sum(x['entry_count'] for x in result['archive_indices']),
                      'relevant_archive_members': sum(len(x['relevant_members']) for x in result['archive_indices']),
                      'target_name_candidates': len(result['target_name_candidates']), 'manifest_text_candidates': len(result['manifest_text_candidates']),
                      'build_manifests': len(result['build_manifests']), 'readonly_hashes_unchanged': result['readonly_hashes_unchanged'],
                      'image_hash_scan': result['image_hash_scan'], 'read_source_recheck_count': result['read_source_recheck_count'],
                      'read_source_hash_drift': result['read_source_hash_drift']}, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
