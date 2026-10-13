"""Offline evidence index. Reads unchanged Viewport PNGs; creates no replacement images."""
from pathlib import Path
import hashlib
import json
import sys
from PIL import Image, ImageChops

root = Path(sys.argv[1]).resolve()
allowed = Path(r"E:\godot\beta-sprint-builds\QA\art_preview_polish03").resolve()
assert root.is_relative_to(allowed) and root != allowed
assert not (root / "REVIEW.html").exists(), "Do not overwrite a previous review"
report = json.loads((root / "captures/report.json").read_text(encoding="utf-8"))
assert len(report["captures"]) == 32 and not report["failures"]
rows = report["captures"]
measurements = []
for row in rows:
    path = root / "captures" / row["file"]
    assert path.parent == root / "captures"
    assert hashlib.sha256(path.read_bytes()).hexdigest() == row["sha256"]
    with Image.open(path) as im:
        im.load()
        assert list(im.size) == row["size"]
    if row["variant"] in ["A", "B"]:
        original = root / "captures" / row["file"].replace(row["variant"] + "_", "ORIGINAL_", 1)
        with Image.open(original) as before, Image.open(path) as after:
            # Ignore the variant badge in the top 150 px, then measure changed pixels.
            diff = ImageChops.difference(before.convert("RGB"), after.convert("RGB"))
            bounds = diff.crop((0, 150, after.width, after.height)).getbbox()
            bounds = [bounds[0], bounds[1] + 150, bounds[2], bounds[3] + 150] if bounds else None
            measurements.append({"file": row["file"], "changed_pixel_bounds_below_y150": bounds,
                                 "meaning": "material-affected pixel extent, not guaranteed full mesh silhouette"})

payload = json.dumps(rows, ensure_ascii=False).replace("<", "\\u003c")
page = '''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Roof 四向实际对照 · 提案待审</title>
<style>body{margin:0;background:#141b21;color:#edf0ed;font:16px/1.55 system-ui,sans-serif}main{max-width:1380px;margin:auto;padding:28px}h1{font-size:29px;margin:0}p{max-width:1050px;color:#c6d0d2}nav{display:flex;gap:16px;flex-wrap:wrap;align-items:center;padding:16px 0;position:sticky;top:0;background:#141b21;z-index:2}select,a{font:inherit}select{padding:7px;background:#26323c;color:white;border:1px solid #697a85;border-radius:4px}a{color:#90d4dc}#frame{overflow:auto;border:1px solid #40515d;background:#4a4a4a}img{display:block;max-width:none}#meta{white-space:pre-wrap;font:13px/1.6 monospace;overflow-wrap:anywhere}small{color:#bdcbcc}article{padding:16px 0;border-top:1px solid #40515d}</style>
<main><small>POLISH_03 · ART_CHANGE=PROPOSAL_ONLY · HUMAN QA=NOT_RUN</small>
<h1>同一空间，四种表现</h1><p>32 张真实 Godot Viewport 原帧。默认按原生像素显示，窗口不足时横向滚动，不自动缩图。
仅覆盖 Surface/source 静止状态；四向相机通过正式 Runtime 动作自然完成。角色为现有实验 Host 调试外观，并非正式 Wakaba 美术验收。</p>
<nav><label>版本 <select id="v"><option value="ORIGINAL">原版</option><option value="A">A · 不透明粗纹</option><option value="B">B · 内收边框</option><option value="C">C · 必要用途说明</option></select></label>
<label>视角 <select id="q"><option value="0">NORTH Q0</option><option value="1">EAST Q1</option><option value="2">SOUTH Q2</option><option value="3">WEST Q3</option></select></label>
<label>实际窗口 <select id="s"><option value="960">960 × 720</option><option value="1280">1280 × 720</option></select></label><a id="raw" target="_blank">打开原图</a></nav>
<div id="frame"><img id="picture" alt="原始游戏视口对照"></div><pre id="meta"></pre>
<article><b>评审边界</b><p>A 纹样明显，但仍可能被理解为可攀爬纹理；B 的封闭边框有箱体、压力板或锁的误读风险；C 明示用途，属于辅助解释，不能作为未经提示推理解谜的证据。
两尺寸同为 720 高，机关像素尺度基本相同：本轮覆盖窄窗口布局，没有验证更小对象尺寸。
gate 站位、Shift/Reset、H 触发、动态纹理稳定性和真人误读测试 PENDING/NOT_RUN。未选胜者，未接入生产。</p></article>
<article><b>证据</b><p><a href="captures/report.json">原始图形收据</a> · <a href="process.json">来源、进程与源文件保护</a> · <a href="REVIEW_EVIDENCE.json">离线校验及像素范围</a></p></article></main>
<script>const rows=__ROWS__;const v=document.getElementById('v'),q=document.getElementById('q'),s=document.getElementById('s');
function show(){const r=rows.find(r=>r.variant===v.value&&r.quadrant===Number(q.value)&&r.size[0]===Number(s.value)); const path='captures/'+r.file; const img=document.getElementById('picture');img.src=path;img.width=r.size[0];img.height=r.size[1];document.getElementById('raw').href=path;document.getElementById('meta').textContent=r.file+'\\nSHA256 '+r.sha256+'\\n'+r.statekey;}
[v,q,s].forEach(x=>x.addEventListener('change',show));show();</script></html>'''.replace("__ROWS__", payload)
(root / "REVIEW.html").write_text(page, encoding="utf-8", newline="\n")
evidence = {"source_report_sha256": hashlib.sha256((root / "captures/report.json").read_bytes()).hexdigest(),
            "capture_sha256_verified": 32, "png_decode_and_resolution_verified": 32,
            "original_images_modified": False, "measurements": measurements,
            "review_html_sha256": hashlib.sha256((root / "REVIEW.html").read_bytes()).hexdigest()}
(root / "REVIEW_EVIDENCE.json").write_text(json.dumps(evidence, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print(json.dumps({"review": str(root / "REVIEW.html"), "images_verified": 32, "measurements": measurements},ensure_ascii=False))
