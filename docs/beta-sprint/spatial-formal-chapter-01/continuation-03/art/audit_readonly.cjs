// Read existing artwork only. Decode/resize into raw memory; never render SVG,
// execute Art scripts, encode/save artwork, or replace/restore source assets.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const cp = require('child_process');
if (process.argv.length !== 3 || !path.isAbsolute(process.argv[2])) {
  throw new Error('Usage: node audit_readonly.cjs <new-absolute-output-directory>; parent directory must exist.');
}
const out = path.resolve(process.argv[2]);
// Atomic exclusive directory creation: EEXIST stops before any audit or output.
// Preserve a partial run directory on failure; choose a new directory to retry.
fs.mkdirSync(out);
const sharp = require('C:/Users/QCYM/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/sharp');
const repo = path.resolve(__dirname, '../../../../..');
const root = 'E:/Study/方块娘项目/若叶睦/model/art/production/work/GAME_ART_MECHANICS_BATCH_01';
const backup = root + '_SCOPE_RECOVERY_20261013';
const build = 'E:/godot/beta-sprint-builds/beta_spatial_formal_chapter_20261019_01';
const rels = ['design/states/face_lock_D.svg', 'design/states/face_lock_D.png', 'reports/DRAWING_CONTACT_SHEET.png'];
const sha = b => crypto.createHash('sha256').update(b).digest('hex');
const hash = p => sha(fs.readFileSync(p));
const json = p => JSON.parse(fs.readFileSync(p, 'utf8'));
const manifestPath = path.join(root, 'tests/PACKAGE_SHA256.json');
const manifest = new Map(json(manifestPath).map(r => [r.path.replaceAll('\\', '/'), r.sha256]));
const indexPath = path.join(root, 'design/revisions/DRAWING_INDEX.json');
const index = json(indexPath);
const watched = [...rels.flatMap(p => [path.join(root,p),path.join(backup,p)]), manifestPath,indexPath,
  path.join(root,'scripts/build_boards.cjs'),path.join(backup,'scripts/build_boards.cjs'),
  ...index.map(r=>path.join(root,r.png))];
const before = Object.fromEntries([...new Set(watched)].map(p=>[p,hash(p)]));
function git(args,cwd=repo) {
  const r=cp.spawnSync('git',args,{cwd,encoding:'utf8',maxBuffer:64*1024*1024});
  return {args,exit_code:r.status,stdout:r.stdout.trim(),stderr:r.stderr.trim()};
}
function chunks(p) {
  const b=fs.readFileSync(p), rows=[];
  for(let at=8;at<b.length;) {
    const size=b.readUInt32BE(at),type=b.toString('ascii',at+4,at+8);
    rows.push({type,length:size,payload_sha256:sha(b.subarray(at+8,at+8+size))});
    at+=12+size;
  }
  return rows;
}
function differences(a,b,width) {
  if(a.length!==b.length)throw Error('Different raw buffer lengths');
  let pixels=0, channels=0, max=0, minX=width,minY=Infinity,maxX=-1,maxY=-1;
  for(let i=0;i<a.length;i+=4) {
    let changed=false;
    for(let c=0;c<4;c++){const d=Math.abs(a[i+c]-b[i+c]);if(d){channels++;changed=true;max=Math.max(max,d);}}
    if(changed){pixels++;const p=i/4,x=p%width,y=Math.floor(p/width);minX=Math.min(minX,x);minY=Math.min(minY,y);maxX=Math.max(maxX,x);maxY=Math.max(maxY,y);}
  }
  return {different_pixels:pixels,different_channels:channels,max_channel_delta:max,bbox:pixels?[minX,minY,maxX,maxY]:null};
}
(async()=>{
  const files=[];
  for(const p of rels) {
    const f={path:p,original_sha256:manifest.get(p),current_sha256:hash(path.join(root,p)),backup_sha256:hash(path.join(backup,p))};
    if(p.endsWith('.png')) {
      f.current_chunks=chunks(path.join(root,p));
      const current=await sharp(path.join(root,p)).ensureAlpha().raw().toBuffer({resolveWithObject:true});
      const old=await sharp(path.join(backup,p)).ensureAlpha().raw().toBuffer();
      f.current_raw={...current.info,sha256:sha(current.data)};
      f.backup_pixel_diff=differences(current.data,old,current.info.width);
    }
    files.push(f);
  }
  const tiles=[];
  for(let i=0;i<index.length;i++) {
    const p=index[i].png.replaceAll('\\','/'),left=i%4*480,top=Math.floor(i/4)*270;
    const resized=await sharp(path.join(root,p)).resize(480,270).ensureAlpha().raw().toBuffer();
    const expected=await sharp({create:{width:480,height:270,channels:3,background:'#f1f2eb'}})
      .composite([{input:resized,raw:{width:480,height:270,channels:4}}]).ensureAlpha().raw().toBuffer();
    const actual=await sharp(path.join(root,rels[2])).extract({left,top,width:480,height:270}).ensureAlpha().raw().toBuffer();
    tiles.push({index:i,path:p,left,top,source_sha256:hash(path.join(root,p)),original_sha256:manifest.get(p),
      source_matches_original:hash(path.join(root,p))===manifest.get(p),composited_source_rgba_sha256:sha(expected),
      sheet_tile_rgba_sha256:sha(actual),uncomposited_diff:differences(resized,actual,480),...differences(expected,actual,480)});
  }
  const face=await sharp(path.join(root,rels[1])).ensureAlpha().raw().toBuffer({resolveWithObject:true});
  const samples=[];
  for(let i=0;i<6;i++) {
    const x=48+i%3*620,y=175+Math.floor(i/3)*380;
    const get=(dx,dy)=>{const at=((y+dy)*face.info.width+x+dx)*4;return {x:x+dx,y:y+dy,rgba:[...face.data.subarray(at,at+4)]};};
    samples.push({panel:i,modified_rail_only:get(132,133),original_rail_only:get(472,155),background:get(475,110)});
  }
  const objectScan=git(['rev-list','--objects','--all']);
  const objectLines=objectScan.stdout.split('\n');
  const history={external_repo:git(['rev-parse','--show-toplevel'],root),
    path_log:git(['log','--all','--format=%H %ad %s','--date=iso-strict','--','**/face_lock_D.svg','**/face_lock_D.png','**/DRAWING_CONTACT_SHEET.png']),
    reachable_objects:{exit_code:objectScan.exit_code,objects_examined:objectLines.length,
      matching_names:objectLines.filter(s=>/(?:^|\/)(?:face_lock_D\.(?:svg|png)|DRAWING_CONTACT_SHEET\.png)$/.test(s))},
    limitations:'Local existing refs only; no dangling-object scan, remote ref fetch, alternate-name content search, private-folder crawl, or original reconstruction.'};
  const identityPath=path.join(build,'BUILD_IDENTITY.json');
  const prior=json(path.join(repo,'docs/beta-sprint/spatial-formal-chapter-01/art/continuation_02/ART_AUDIT.json'));
  const after=Object.fromEntries(Object.keys(before).map(p=>[p,hash(p)]));
  const result={task:'SPATIAL_FORMAL_CHAPTER_01_CONTINUATION_03',owner:'05 Art',checked_utc:new Date().toISOString(),
    repository:{root:repo,branch:git(['branch','--show-current']).stdout,base:git(['rev-parse','HEAD']).stdout},
    external_evidence_root:out,source_root:root,backup_root:backup,manifest_sha256:hash(manifestPath),
    manifest_provenance:'CORROBORATED_LOCAL_PREINCIDENT_MANIFEST_NO_INDEPENDENT_IMMUTABLE_ANCHOR',
    files,history,sharp_versions:sharp.versions,contact_sheet:{tiles,exact_pixel_tiles:tiles.filter(t=>t.different_pixels===0).length,
      original_hash_source_tiles:tiles.filter(t=>t.source_matches_original).length,
      method:'Sharp.resize(480,270) default kernel, then raw-buffer composite onto #f1f2eb background versus extract of existing sheet. No encoded artwork or composite saved.'},
    rail_samples:samples,
    build:{path:build,current_identity_sha256:hash(identityPath),prior_identity_sha256:prior.build.identity_sha256,
      provenance:'Prior continuation_02 full 1783-file manifest audit and literal-closure audit retained; current identity file hash rechecked only. This run does not establish unchanged payload files.',
      previous_conclusion:prior.build.conclusion,limits:prior.build.limits},
    read_only:{watched_count:Object.keys(before).length,before,after,drift:Object.keys(before).filter(p=>before[p]!==after[p]),
      source_writes:false,generator_execution:false,svg_render:false,image_encoding_or_export:false,recovery:false},
    statuses:{art_recovery:'PENDING',floating_cube:'PENDING_USER_REVIEW',art_implementation:'NOT_AUTHORIZED',production_changes:'NONE'}};
  fs.writeFileSync(path.join(out,'ART_INCREMENTAL_EVIDENCE.json'),JSON.stringify(result,null,2)+'\n',{flag:'wx'});
  console.log(JSON.stringify({files:files.map(f=>({path:f.path,current:f.current_sha256})),tiles:result.contact_sheet.exact_pixel_tiles,
    unchanged_sources:result.contact_sheet.original_hash_source_tiles,rail_samples:samples,history,build:result.build,drift:result.read_only.drift},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});
