"""Validate schema, arithmetic, real evidence identities and Markdown consistency.

Requires jsonschema >= 4 with Draft202012Validator. Does not render or score images.
Optional --dependency-dir locates an isolated dependency installation.
"""
from pathlib import Path
from datetime import datetime, timezone
import argparse
import copy
import hashlib
import json
import re
import struct
import sys

HERE = Path(__file__).resolve().parent
WEIGHTS = {'V1': 30, 'V2': 20, 'V3': 15, 'V4': 15, 'V5': 10, 'V6': 10}
LABELS = {'CURRENT_REFERENCE': '当前材质参照', 'OPTION_A': '方案 A', 'OPTION_B': '方案 B'}

def load(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def require(condition, message):
    if not condition:
        raise ValueError(message)

def semantic_check(data, check_files=True):
    text = json.dumps(data, ensure_ascii=False)
    require(not re.search(r'<实际>|TODO|待填写|待评估|待填充', text), 'Unfilled placeholder')
    date = datetime.fromisoformat(data['review']['review_date'])
    require(date.tzinfo is not None, 'Review date must include timezone')
    ev = {row['id']: row for row in data['evidence']}
    require(len(ev) == len(data['evidence']), 'Duplicate evidence ID')
    def refs(value):
        if isinstance(value, dict):
            for key, item in value.items():
                if key.endswith('evidence_ids'):
                    require(all(i in ev for i in item), 'Unknown evidence reference')
                elif key.endswith('evidence_id'):
                    require(item in ev, 'Unknown evidence reference')
                refs(item)
        elif isinstance(value, list):
            for item in value:
                refs(item)
    refs(data)
    for key, candidate in data['candidates'].items():
        metrics = candidate['metrics']
        require({k: m['weight'] for k, m in metrics.items()} == WEIGHTS, 'Wrong rubric weights')
        assessed = [m for m in metrics.values() if m['status'] == 'ASSESSED']
        for metric in assessed:
            require(metric['weighted_score'] == round(metric['score'] / 5 * metric['weight'], 1), 'Wrong weighted score')
            require(any(ev[i]['kind'] == 'IMAGE' for i in metric['evidence_ids']), 'Score lacks image evidence')
        totals = candidate['totals']
        subtotal = round(sum(m['weighted_score'] for m in assessed), 1)
        require(totals['assessed_subtotal'] == subtotal, 'Wrong subtotal')
        require(totals['assessed_items'] == len(assessed), 'Wrong assessed item count')
        require(totals['assessed_weight'] == sum(m['weight'] for m in assessed), 'Wrong assessed weight')
        require(totals['weight_sum'] == sum(WEIGHTS.values()) == 100, 'Wrong total weight')
        require(totals['total'] == (subtotal if len(assessed) == 6 else None), 'Partial total fabricated')
        views = candidate['views']
        require([v['quadrant'] for v in views] == [0, 1, 2, 3], 'Wrong camera coverage')
        values = [v['score'] for v in views if v['status'] == 'ASSESSED']
        summary = candidate['view_summary']
        require(summary['assessed_view_count'] == len(values), 'Wrong view count')
        require(summary['minimum'] == (min(values) if values else None), 'Wrong minimum')
        require(summary['average'] == (round(sum(values) / len(values), 1) if values else None), 'Wrong average')
        require(summary['coverage'] == ('COMPLETE' if len(values) == 4 else 'PARTIAL'), 'False four-view coverage')
        for view in views:
            for i in view['evidence_ids']:
                require(ev[i]['kind'] == 'IMAGE', 'View requires image evidence')
    comparison = data['comparison']
    pairs = [('a_minus_current', 'OPTION_A', 'CURRENT_REFERENCE'), ('b_minus_current', 'OPTION_B', 'CURRENT_REFERENCE'), ('a_minus_b', 'OPTION_A', 'OPTION_B')]
    common = [k for k in WEIGHTS if all(c['metrics'][k]['status'] == 'ASSESSED' for c in data['candidates'].values())]
    require(comparison['common_assessed_weight'] == sum(WEIGHTS[k] for k in common), 'Wrong common weight')
    for label, a, b in pairs:
        ca, cb = data['candidates'][a], data['candidates'][b]
        subtotal_delta = round(sum(ca['metrics'][k]['weighted_score'] - cb['metrics'][k]['weighted_score'] for k in common), 1)
        require(comparison[label + '_subtotal'] == subtotal_delta, 'Wrong common-subtotal delta')
        expected = None if ca['totals']['total'] is None or cb['totals']['total'] is None else round(ca['totals']['total'] - cb['totals']['total'], 1)
        require(comparison[label + '_total'] == expected, 'False complete-score delta')
    gates = [g['status'] for g in data['hard_gates'].values()]
    overall = data['final_status']['overall_visual_review']
    final = data['final_status']
    require(final['input_preparation']['execution_status'] == final['graphical_diagnostic'], 'Contradictory input execution status')
    require(final['human_qa_preparation']['execution_status'] == final['human_qa'], 'Contradictory human execution status')
    if 'FAIL' in gates:
        require(overall == 'FAIL', 'Hard failure hidden by score')
    elif 'NOT_ASSESSED' in gates or any(c['totals']['total'] is None for c in data['candidates'].values()):
        require(overall == 'PARTIAL', 'Missing assessment hidden')
    if data['final_status']['road_recognition'] == 'PASS':
        require(all(c['view_summary']['assessed_view_count'] == 4 and c['view_summary']['minimum'] >= 3 for c in data['candidates'].values()), 'Weak view hidden by aggregate')
    if check_files:
        require(Path(data['review']['preview_root']).is_dir(), 'Missing preview root')
        for row in ev.values():
            path = Path(row['path'])
            require(path.is_absolute() and path.is_file(), 'Missing/non-absolute evidence: ' + row['path'])
            require(digest(path) == row['sha256'], 'Evidence hash mismatch: ' + row['id'])
            if row['kind'] == 'IMAGE':
                raw = path.read_bytes()
                require(raw[:8] == b'\x89PNG\r\n\x1a\n', 'Not a PNG')
                require(tuple(struct.unpack('>II', raw[16:24])) == (row['width'], row['height']), 'Wrong PNG dimensions')
        source = data['source_asset']
        for path_key, hash_key in [('path', 'sha256'), ('authoring_path', 'authoring_sha256'), ('original_manifest_path', 'original_manifest_sha256')]:
            require(digest(Path(source[path_key])) == source[hash_key], 'Source identity mismatch')
    return {'evidence_count': len(ev), 'image_count': sum(e['kind'] == 'IMAGE' for e in ev.values()), 'arithmetic': 'PASS', 'reference_integrity': 'PASS'}

def display(value):
    return 'NOT_ASSESSED' if value is None else (f'{value:.1f}' if isinstance(value, float) else str(value))

def markdown(data):
    ev = {e['id']: e for e in data['evidence']}
    def links(ids):
        return ' · '.join(f"[{Path(ev[i]['path']).name}]({ev[i]['path']})" for i in ids)
    r, source, candidates, final = data['review'], data['source_asset'], data['candidates'], data['final_status']
    lines = ['# Floating Cube Visual Acceptance Report', '', f"Task ID: `{data['task_id']}`", '', f"Review Date: {r['review_date']}  ", f"Reviewer: {r['reviewer']}  ", f"Review Mode: {r['review_mode']}  ", f"Project: {r['project']}  ", f"Godot: {r['godot_version']}  ", f"Blender Version: {r['blender_version'] or 'NOT_ASSESSED / NOT_APPLICABLE'} — {r['blender_detection']}", '', f"**OVERALL_VISUAL_REVIEW = {final['overall_visual_review']}**；**FORMAL_ASSET_APPROVAL = NOT_GRANTED**。", '', r['review_scope'], '', r['schema_completion_note'], '', r['policy_limit'], '', '## 资产身份与来源', '', f"Source: [{Path(source['path']).name}]({source['path']})  ", f"Source SHA-256: `{source['sha256']}`  ", f"Authoring: [{Path(source['authoring_path']).name}]({source['authoring_path']})  ", f"Authoring SHA-256: `{source['authoring_sha256']}`  ", f"Original Build manifest: [{Path(source['original_manifest_path']).name}]({source['original_manifest_path']})  ", f"Manifest SHA-256: `{source['original_manifest_sha256']}`", '', source['identity_chain'], '', f"Preview Source: `{source['preview_source_commit']}`；Formal Build Source: `{source['formal_build_source_commit']}`；审查基线：`{r['base_sha']}`。", '', '| 字段 | 当前材质参照 | A | B |', '|---|---|---|---|']
    for field in ['variant', 'model', 'material', 'blender_status', 'geometry_and_role', 'same_pose', 'isolated', 'identity_status']:
        lines.append('| '+field+' | '+' | '.join(str(c['identity'][field]) for c in candidates.values())+' |')
    lines += ['', 'Blender file：三组均为 null；没有把相似的 Blender 设计灰模当作此实际 roof。源码与材质的完整文件 SHA 见末尾证据清单。', '', '## 加权评分', '', '完整总分需要六项均可评。V5 缺失，以下仅显示原始权重小计，不归一化，不替代100分总分。所有分数是 Codex 图像观察判断，不是真人理解率。', '', '| 编号 | 项目 | 权重 | 当前分 | 当前加权 | A分 | A加权 | B分 | B加权 |', '|---|---|---:|---:|---:|---:|---:|---:|---:|']
    for k, w in WEIGHTS.items():
        row = [k, candidates['CURRENT_REFERENCE']['metrics'][k]['label'], str(w)+'%']
        for c in candidates.values():
            row += [display(c['metrics'][k]['score']), display(c['metrics'][k]['weighted_score'])]
        lines.append('| '+' | '.join(row)+' |')
    lines += ['', '舍入规则：'+r['rounding_rule']]
    lines += ['', '| 汇总 | 当前材质参照 | A | B |', '|---|---:|---:|---:|']
    for label, field in [('完整总分 /100', 'total'), ('已评估小计 /90，未归一化', 'assessed_subtotal'), ('已评估权重 %', 'assessed_weight')]:
        lines.append('| '+label+' | '+' | '.join(display(c['totals'][field]) for c in candidates.values())+' |')
    for key, candidate in candidates.items():
        lines += ['', '### '+LABELS[key]+'：逐项依据', '']
        for k, m in candidate['metrics'].items():
            lines += [f"**{k} {m['label']}：{display(m['score'])}；加权 {display(m['weighted_score'])}。**", '', m['observation'], '', m['rationale']+' '+m['deduction'], '', '未解决：'+m['unresolved']+' 主观判断：'+('YES' if m['subjective'] else 'NO')+'。', '', '图片：'+links(m['evidence_ids']), '']
    lines += ['## 四固定视角道路辨识', '', '方位来自正式 Host 与 view_contract，Q0/1/2/3 对应北/东/南/西；不是按一般世界轴猜测。每行同时查看1280×720与960×720原帧。', '', links(data['render_comparison']['camera_definition_evidence_ids']), '', '| 视角 | 当前 | A | B | 当前证据 | A证据 | B证据 |', '|---|---:|---:|---:|---|---|---|']
    for q in range(4):
        views = [c['views'][q] for c in candidates.values()]
        lines.append('| '+views[0]['name']+' | '+' | '.join(display(v['score']) for v in views)+' | '+' | '.join(links(v['evidence_ids']) for v in views)+' |')
    for key, c in candidates.items():
        lines += ['', '### '+LABELS[key]+'：逐视角问题', '']
        for v in c['views']:
            lines.append(f"- {v['name']}：{v['observation']} {v['deduction']}")
        v = c['view_summary']
        lines += ['', f"已评 {v['assessed_view_count']}/4；最低 {v['minimum']}；平均 {v['average']:.1f}。最易混淆：{v['most_confusing']} 覆盖 {v['coverage']}，仅 {v['scope']}。"]
    lines += ['', '## 同条件核验', '', data['render_comparison']['scope'], '', '| 条件 | 当前 / A / B 的实际共同条件 | 状态 | 证据 | 限制 |', '|---|---|---|---|---|']
    for c in data['render_comparison']['conditions']:
        require(len(set(c['values'].values())) == 1, 'Renderer must show divergent values explicitly')
        lines.append('| '+c['field']+' | '+c['values']['CURRENT_REFERENCE']+' | '+c['status']+' | '+links(c['evidence_ids'])+' | '+c['limit']+' |')
    lines += ['', '未覆盖：'+'；'.join(data['render_comparison']['uncovered'])+'。', '', '## 硬性门槛', '', '| 编号 | 门槛 | 状态 | 观察 | 证据 | 范围限制 |', '|---|---|---|---|---|---|']
    for k, g in data['hard_gates'].items():
        lines.append('| '+k+' | '+g['label']+' | '+g['status']+' | '+g['observation']+' | '+links(g['evidence_ids'])+' | '+g['scope_limit']+' |')
    comparison = data['comparison']
    lines += ['', '所有门槛的限定PASS不覆盖缺失的V5，也不抵消低于3分的最弱视角；整体保持PARTIAL。', '', '## 候选比较与建议', '', f"A−当前完整总分：{display(comparison['a_minus_current_total'])}；B−当前：{display(comparison['b_minus_current_total'])}；A−B：{display(comparison['a_minus_b_total'])}。", '', f"共同90%权重小计差值：A−当前 **{comparison['a_minus_current_subtotal']:.1f}**；B−当前 **{comparison['b_minus_current_subtotal']:.1f}**；A−B **{comparison['a_minus_b_subtotal']:.1f}**。{comparison['basis']}", '', 'A优势：'+comparison['a_strength'], '', 'A不足：'+comparison['a_weakness'], '', 'B优势：'+comparison['b_strength'], '', 'B不足：'+comparison['b_weakness'], '', comparison['recommendation'], '', '## 输入、真人QA与安全', '']
    for key, name in [('input_preparation', '输入诊断'), ('human_qa_preparation', '真人QA')]:
        p = final[key]
        lines += [f"- {name}准备完整性：{p['preparation_status']}；执行就绪：{p['execution_readiness']}；实际执行：{p['execution_status']}。{p['finding']} 未完成：{p['remaining']} 证据：{links(p['evidence_ids'])}"]
    lines += ['', '| 状态 | 实际 |', '|---|---|']
    for key, value in final.items():
        if not isinstance(value, (list, dict)):
            lines.append('| '+key+' | '+('NONE' if value is None else str(value))+' |')
    lines += ['', '未完成事项：', ''] + ['- '+s for s in final['remaining']]
    lines += ['', '## 可追溯证据', '', '24张评分图片由本轮实际打开观察；32张历史捕获重新核验哈希，另外8张C未纳入评分。历史261项图形检查不是本轮新增执行。所有路径在本机核实存在，SHA由实际字节计算。', '', '| ID | 文件 | SHA-256 | 本轮检查 |', '|---|---|---|---|']
    for e in data['evidence']:
        lines.append(f"| {e['id']} | [{Path(e['path']).name}]({e['path']}) | `{e['sha256']}` | {e['inspection']} |")
    lines += ['', '## 结构与复核', '', '[结构规范](SCORING_RESULTS.schema.json) · [实际评分JSON](SCORING_RESULTS.json) · [验证工具](validate_scoring.py)', '', 'Schema为Draft 2020-12；语义验证另检查权重、算式、NA传播、比较范围、证据路径/哈希及本Markdown一致性。Schema通过不代表正式资产批准。', '']
    # Keep paragraph breaks without trailing-space hard breaks rejected by Git.
    return '\n'.join(line.rstrip() + ('\n' if line.endswith('  ') else '') for line in lines)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dependency-dir', type=Path)
    parser.add_argument('--write-markdown', action='store_true')
    parser.add_argument('--receipt', type=Path)
    args = parser.parse_args()
    if args.dependency_dir:
        sys.path.insert(0, str(args.dependency_dir.resolve()))
    from jsonschema import Draft202012Validator, FormatChecker
    schema = load(HERE / 'SCORING_RESULTS.schema.json')
    data = load(HERE / 'SCORING_RESULTS.json')
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema, format_checker=FormatChecker())
    validator.validate(data)
    results = semantic_check(data)
    negative = []
    def rejected(label, mutate):
        test = copy.deepcopy(data)
        mutate(test)
        try:
            validator.validate(test)
            semantic_check(test)
        except Exception as error:
            negative.append({'case': label, 'result': 'REJECTED', 'reason': type(error).__name__})
            return
        raise ValueError('Invalid data accepted: '+label)
    rejected('NA score changed to 0', lambda d: d['candidates']['OPTION_B']['metrics']['V5'].update(score=0))
    rejected('NA total changed to 100', lambda d: d['candidates']['OPTION_A']['totals'].update(total=100))
    rejected('wrong formal weight', lambda d: d['candidates']['OPTION_A']['metrics']['V1'].update(weight=25))
    rejected('wrong weighted arithmetic', lambda d: d['candidates']['OPTION_A']['metrics']['V1'].update(weighted_score=30))
    rejected('fabricated comparison', lambda d: d['comparison'].update(a_minus_current_total=15))
    rejected('bad hash format', lambda d: d['evidence'][0].update(sha256='abc'))
    rejected('valid-format wrong hash', lambda d: d['evidence'][0].update(sha256='0'*64))
    rejected('missing evidence file', lambda d: d['evidence'][0].update(path=str(HERE/'missing-evidence-should-not-exist.png')))
    rejected('unknown evidence reference', lambda d: d['candidates']['OPTION_A']['metrics']['V1'].update(evidence_ids=['unregistered']))
    rejected('hard gate failure hidden', lambda d: d['hard_gates']['G6'].update(status='FAIL'))
    rejected('unassessed gate hidden by PASS', lambda d: (d['hard_gates']['G3'].update(status='NOT_ASSESSED'), d['final_status'].update(overall_visual_review='PASS')))
    rejected('formal approval granted', lambda d: d['final_status'].update(formal_asset_approval='APPROVED'))
    rejected('wrong camera quadrant', lambda d: d['candidates']['OPTION_A']['views'][0].update(quadrant=3))
    rejected('unknown field', lambda d: d.update(unexpected='value'))
    rejected('weak views labeled road PASS', lambda d: d['final_status'].update(road_recognition='PASS'))
    rejected('contradictory human execution PASS', lambda d: d['final_status']['human_qa_preparation'].update(execution_status='PASS'))
    rejected('contradictory input execution PASS', lambda d: d['final_status']['input_preparation'].update(execution_status='PASS'))
    rendered = markdown(data)
    md = HERE / 'SCORING_RESULTS.md'
    if args.write_markdown:
        md.write_text(rendered, encoding='utf-8', newline='\n')
    require(md.is_file() and md.read_text(encoding='utf-8') == rendered, 'Markdown differs from JSON')
    receipt = {'verified_utc': datetime.now(timezone.utc).isoformat(), 'validator': 'jsonschema Draft202012Validator + FormatChecker + semantic/evidence validator', 'schema_valid': True, 'results_valid': True, **results, 'negative_cases': negative, 'markdown_matches_json': True, 'formal_asset_approval': 'NOT_GRANTED', 'schema_sha256': digest(HERE/'SCORING_RESULTS.schema.json'), 'data_sha256': digest(HERE/'SCORING_RESULTS.json'), 'markdown_sha256': digest(md), 'validator_sha256': digest(Path(__file__))}
    if args.receipt:
        require(args.receipt.is_absolute() and not args.receipt.exists(), 'Receipt must be new absolute file')
        with args.receipt.open('x', encoding='utf-8', newline='\n') as stream:
            json.dump(receipt, stream, ensure_ascii=False, indent=2)
            stream.write('\n')
    print(json.dumps(receipt, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    main()
