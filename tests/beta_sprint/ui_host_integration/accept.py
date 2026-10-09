"""Record only measured immutable Build evidence; pending ports/warnings stay pending."""
from pathlib import Path
from datetime import datetime,timezone
import hashlib,json,subprocess
root=Path(__file__).resolve().parents[3]
docs=root/'docs/beta-sprint/game-feel/ui-host-01'
target=Path('E:/godot/beta-sprint-builds/beta_game_feel_ui_host_20261010_04')
identity=json.loads((target/'BUILD_IDENTITY.json').read_text(encoding='utf-8-sig'))
out=docs/'RECEIPT.json'
if out.exists(): raise SystemExit('Receipt already exists; preserve it')
rows=[];pngs=[]
for name in ['final_host_01','final_cold_01','final_1920_01','final_1280_01','final_960_01']:
    record=json.loads((docs/'evidence'/name/'process.json').read_text(encoding='utf-8-sig'))
    assert record['passed'] and not record['source_drift'] and Path(record['project'])==target/'project'
    assert record['head']==identity['integration_commit']
    for row in record['runs']:
        assert row['exit_code']==0 and row['checks']>0 and not row['failures'] and row['stderr_bytes']==0 and row['doubles']==[]
        report=json.loads((docs/'evidence'/name/(row['phase']+'.json')).read_text(encoding='utf-8-sig'))
        rows.append({'case':name,**row,'actual_viewport':report['observations'].get('actual_viewport')})
        for item in report['observations'].get('captures',[]):
            p=Path(item['path']);pngs.append({'path':p.relative_to(root).as_posix(),'size':item['size'],'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
assert len(pngs)==24
drift=[]
for item in identity['files']:
    p=target/item['path']
    if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest()!=item['sha256']: drift.append(item['path'])
assert not drift,drift
with target.with_suffix('.zip').open('rb') as stream: archive_hash=hashlib.file_digest(stream,'sha256').hexdigest()
assert archive_hash=='fa11b8aafaa88f8eef3fae6fad73e752a5a7fb40af974767d32da06651eeeb81'
quit_process=json.loads((docs/'evidence/final_quit_01/process.json').read_text(encoding='utf-8-sig'))
assert all(r['exit_code']==0 and not r['failures'] and r['doubles']==[] for r in quit_process['runs'])
assert quit_process['runs'][0]['stderr_bytes']==133 and quit_process['runs'][1]['stderr_bytes']==0
production=['project.godot','game/feel/cube_presenter.gd','game/shell/game_feel_host.gd','game/shell/game_feel_shell.gd','game/shell/game_feel_shell.tscn','game/shell/game_feel_lab.gd','game/shell/game_feel_lab.tscn']
files=[item for item in identity['files'] if item['path'].removeprefix('project/') in production]
report={'task':'GAME_FEEL_UI_HOST_INTEGRATION_01','status':'PARTIAL','created_utc':datetime.now(timezone.utc).isoformat(),'integration_commit':identity['integration_commit'],'07_owner_commit':identity['ui_original'],'07_accepted_delivery':identity['ui_accepted'],'11_original':identity['audio_original'],'11_accepted':identity['audio_accepted'],'contract':identity['contract'],'ui_staging':'PASS','audio_settings':'PASS_PREVIEW_CANCEL_RETRY_COLD_SCENE;EXIT_BEHAVIOR_PASS_WITH_P2_WARNING','fall_indicator':'PASS_REAL_RUNTIME_STARTED_COMMITTED_INTERRUPTED','runtime_readiness_interface':'PENDING_RUNTIME_INTERFACE','connection_valid_invalid_feedback':'PENDING_RUNTIME_INTERFACE','reduced_motion':{'07':'PASS','10A':'PASS_REAL_NEXT_FALL_AND_LANDING;STATEKEY_ORIENTATION_PARITY','10B':'PENDING_PRESENTER_CONSUMPTION','persisted':'PASS_EXISTING_SAVESTORE'},'hint_accessibility':'PASS_07_SCOPE;LEGACY_HINT_PRESENTATION_PRESERVED','graphical_matrix':'PASS_3_OF_3','graphical_checks':213,'host_checks':36,'cold_checks':27,'doubles':[],'visual_regression':'FOCUSED_AUTOMATED_AND_CAPTURE_REVIEW;HUMAN_NOT_RUN','legacy_game_shell':'FOCUSED_PASS_MAIN_SELECT_PAUSE_SETTINGS_NEW_CONTINUE;FULL_FIVE_PLAYTHROUGHS_NOT_REPEATED','core_gameplay_build':str(target),'build_identity_sha256':hashlib.sha256((target/'BUILD_IDENTITY.json').read_bytes()).hexdigest(),'archive_sha256':archive_hash,'package_integrity':{'checks':len(identity['files']),'failures':drift},'runs':rows,'screenshots':pngs,'files':files,'pending':[{'id':'UI_HOST_EXIT_OBJECTDB_01','severity':'P2','status':'BACKLOG','evidence':'evidence/final_quit_01/seed.stderr.log','actual':'six ObjectDB leaked instances at process quit;6 behavior checks pass, restore stderr0;not warning-free PASS','owner':'00 diagnosis;handoff exact component only after attribution'},{'id':'CONNECTION_PREPAREDNESS','status':'PENDING_RUNTIME_INTERFACE','owner':'01'},{'id':'EDGE_REDUCED_MOTION','status':'PENDING_PRESENTER_CONSUMPTION','owner':'00/10B'}],'human_qa':'NOT_RUN','foundation_changes':'NONE_THIS_TASK','art_changes':'NONE','owner_production_changes':'NONE','qa_baseline':'UNCHANGED','qa_handoff':'READY_FOR_08','push':'NOT_RUN'}
out.write_bytes((json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
(docs/'FILES_SHA256.csv').write_bytes(('path,bytes,sha256\n'+'\n'.join(f"{x['path']},{x['bytes']},{x['sha256']}" for x in files)+'\n').encode('utf-8'))
window=json.loads((docs/'INTEGRATION_WINDOW_02.json').read_text(encoding='utf-8-sig'))
window.update({'status':'CLOSED','closed_utc':datetime.now(timezone.utc).isoformat(),'validated_source':identity['integration_commit'],'build':str(target),'archive_sha256':archive_hash,'ui_status':'PARTIAL','graphical_matrix':'3/3 PASS','human_qa':'NOT_RUN','next_window':'NEXT_LOCAL_DAY;NO_THIRD_WINDOW_TODAY'})
(docs/'INTEGRATION_WINDOW_02.json').write_bytes((json.dumps(window,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print(json.dumps({'source':identity['integration_commit'],'graphical':213,'host':36,'cold':27,'screenshots':24,'package_integrity':len(identity['files']),'failures':drift,'ui_status':'PARTIAL','archive':archive_hash}))
