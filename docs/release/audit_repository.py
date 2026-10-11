"""Read-only Git inventory; writes audit data only beside this script."""
import collections
import datetime
import json
import os
import pathlib
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf-8')

os.environ['GIT_OPTIONAL_LOCKS'] = '0'


def git(*args, cwd=None):
    result = subprocess.run(['git', *args], cwd=cwd, capture_output=True, check=True)
    return result.stdout.decode('utf-8', 'replace').rstrip('\r\n')


def ancestor(a, b):
    result = subprocess.run(['git', 'merge-base', '--is-ancestor', a, b], capture_output=True)
    if result.returncode not in (0, 1):
        raise RuntimeError(result.stderr.decode('utf-8', 'replace'))
    return result.returncode == 0


def commits(*args):
    rows = []
    for line in git('log', '--reverse', '--format=%H%x09%P%x09%aI%x09%an%x09%s', *args).splitlines():
        sha, parents, date, author, subject = line.split('\t', 4)
        rows.append(dict(sha=sha, parents=parents.split(), author_date=date, author=author, subject=subject))
    return rows


def tree(ref):
    rows = []
    for item in git('ls-tree', '-r', '-l', '-z', ref).split('\0'):
        if not item:
            continue
        meta, path = item.split('\t', 1)
        mode, kind, sha, size = meta.split()
        if kind == 'blob':
            rows.append(dict(sha=sha, bytes=int(size), path=path))
    return rows


def disksize(path):
    total = count = 0
    for base, dirs, files in os.walk(path):
        for name in files:
            total += (pathlib.Path(base) / name).stat().st_size
            count += 1
    return dict(bytes=total, files=count)


root = pathlib.Path(git('rev-parse', '--show-toplevel'))
remote_refs = {line.split('\t')[0]: line.split('\t')[1] for line in
               git('for-each-ref', '--format=%(refname:short)%09%(objectname)', 'refs/remotes/origin').splitlines()}
main = git('rev-parse', 'main')
remote = git('rev-parse', 'origin/main')
candidate = git('rev-parse', 'feat/game-feel-full-slice-01')
branches = []
for line in git('for-each-ref', '--format=%(refname:short)%09%(objectname)%09%(upstream:short)', 'refs/heads').splitlines():
    name, sha, upstream = line.split('\t')
    behind, ahead = map(int, git('rev-list', '--left-right', '--count', 'origin/main...' + sha).split())
    outside = int(git('rev-list', '--count', sha, '--not', candidate))
    corresponding_remote = 'origin/' + name if 'origin/' + name in remote_refs else None
    remote_counts = list(map(int, git('rev-list', '--left-right', '--count', corresponding_remote + '...' + sha).split())) if corresponding_remote else None
    branches.append(dict(name=name, sha=sha, upstream=upstream, behind_origin_main=behind,
                         ahead_origin_main=ahead, merged_into_main=ancestor(sha, main),
                         corresponding_remote=corresponding_remote, remote_behind_ahead=remote_counts,
                         merged_into_candidate=ancestor(sha, candidate), outside_candidate=outside,
                         unpushed_to_any_origin_ref=int(git('rev-list', '--count', sha, '--not', '--remotes=origin')),
                         exclusive_commits=commits(candidate + '..' + sha) if outside else []))
worktrees = []
for block in git('worktree', 'list', '--porcelain').split('\n\n'):
    row = dict(line.partition(' ')[::2] for line in block.splitlines())
    if row:
        row['status'] = git('status', '--porcelain=v1', '--untracked-files=all', cwd=row['worktree']).splitlines()
        worktrees.append(row)
raw = git('rev-list', '--objects', '--all')
batch = subprocess.run(['git', 'cat-file', '--batch-check=%(objectname) %(objecttype) %(objectsize) %(rest)'],
                       input=(raw + '\n').encode('utf-8'), capture_output=True, check=True)
blobs = []
for line in batch.stdout.decode('utf-8', 'replace').splitlines():
    parts = line.split(' ', 3)
    if len(parts) == 4 and parts[1] == 'blob':
        blobs.append(dict(sha=parts[0], bytes=int(parts[2]), path=parts[3]))
main_tree = tree(main)
candidate_tree = tree(candidate)
large = sorted((b for b in blobs if b['bytes'] >= 10 * 1024 * 1024), key=lambda b: -b['bytes'])
new_ids = {s.split(' ', 1)[0] for s in git('rev-list', '--objects', candidate, '--not', '--remotes=origin').splitlines()}
references = ['26387d6c34a869ad7035ee13ee77d8d5c24d796a', '99f2f1db9d9646d8fc7f3856fc4e64df81ff6cff',
              'e12d3931cdd482bd970bb07b1db12cd81acfc5b2', 'fe370ad832bb62cd31a6d22909ce1a5bd1fe1311',
              'a741ee5e29dd2a849df13ff40100c08a9f1a2dc7']
extensions = ['.blend', '.glb', '.png', '.wav', '.mp4', '.zip']
data = dict(audit_time=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat(),
            repository=str(root), head=git('rev-parse', 'HEAD'), branch=git('branch', '--show-current'),
            remote_url=git('remote', 'get-url', 'origin'), remote_head=remote,
            remote_live_head=git('ls-remote', '--symref', 'origin', 'HEAD'), main=main, candidate=candidate,
            merge_base=git('merge-base', main, candidate), main_is_candidate_ancestor=ancestor(main, candidate),
            remote_is_candidate_ancestor=ancestor(remote, candidate),
            initial_main_status=git('status', '--porcelain=v1', '--untracked-files=all').splitlines(),
            audit_output_status_prefix='?? docs/release/', remote_refs=remote_refs,
            branches=branches, worktrees=worktrees,
            all_local_unpushed_count=int(git('rev-list', '--count', '--branches', '--not', '--remotes=origin')),
            main_vs_candidate_behind_ahead=list(map(int, git('rev-list', '--left-right', '--count', main + '...' + candidate).split())),
            reference_commits=[dict(sha=s, subject=git('show', '-s', '--format=%s', s), in_main=ancestor(s, main),
                                    in_origin=ancestor(s, remote), in_candidate=ancestor(s, candidate)) for s in references],
            main_ahead_origin_main_commits=commits('origin/main..main'),
            candidate_ahead_origin_main_commits=commits('origin/main..' + candidate),
            main_unpushed=commits(main, '--not', '--remotes=origin'),
            candidate_unpushed=commits(candidate, '--not', '--remotes=origin'),
            all_local_unpushed=commits('--branches', '--not', '--remotes=origin'),
            candidate_after_main=commits(main + '..' + candidate),
            candidate_diff_stats=git('diff', '--shortstat', remote, candidate),
            candidate_files=git('-c', 'core.quotepath=false', 'diff', '--name-status', remote, candidate).splitlines(),
            candidate_vs_main_files=git('-c', 'core.quotepath=false', 'diff', '--name-status', main, candidate).splitlines(),
            tags=git('tag', '-n1'), count_objects=git('count-objects', '-vH'),
            git_disk=disksize(pathlib.Path(git('rev-parse', '--git-common-dir')).resolve()), main_disk=disksize(root),
            main_tracked_bytes=sum(b['bytes'] for b in main_tree), candidate_tracked_bytes=sum(b['bytes'] for b in candidate_tree),
            reachable_unique_blob_bytes=sum(b['bytes'] for b in blobs), large_history_blobs=large,
            large_candidate_new_blobs=[b for b in large if b['sha'] in new_ids],
            top_history_blobs=sorted(blobs, key=lambda b: -b['bytes'])[:30],
            media_extension_inventory=[dict(extension=e,
                history_blob_versions=sum(pathlib.PurePosixPath(b['path']).suffix.lower() == e for b in blobs),
                history_bytes=sum(b['bytes'] for b in blobs if pathlib.PurePosixPath(b['path']).suffix.lower() == e),
                candidate_files=sum(pathlib.PurePosixPath(b['path']).suffix.lower() == e for b in candidate_tree),
                candidate_bytes=sum(b['bytes'] for b in candidate_tree if pathlib.PurePosixPath(b['path']).suffix.lower() == e)) for e in extensions])
out = pathlib.Path(__file__).parent
(out / 'REPOSITORY_AUDIT_DATA.json').write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
keys = ['repository', 'head', 'remote_head', 'candidate', 'merge_base', 'main_is_candidate_ancestor',
        'remote_is_candidate_ancestor', 'candidate_diff_stats', 'git_disk', 'main_disk', 'main_tracked_bytes',
        'candidate_tracked_bytes', 'reachable_unique_blob_bytes', 'media_extension_inventory', 'large_history_blobs']
summary = {k: data[k] for k in keys}
summary['branches_not_in_candidate'] = [dict(name=b['name'], outside_candidate=b['outside_candidate'], sha=b['sha'])
                                       for b in branches if not b['merged_into_candidate']]
summary['dirty_worktrees'] = [dict(path=w['worktree'], changes=len(w['status']), sample=w['status'][:5])
                            for w in worktrees if w['status']]
summary['candidate_commit_count'] = len(data['candidate_ahead_origin_main_commits'])
summary['candidate_after_main_count'] = len(data['candidate_after_main'])
print(json.dumps(summary, ensure_ascii=False, indent=2))
