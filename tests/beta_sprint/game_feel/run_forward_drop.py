"""Owner03 new-task recipes consume the existing strict receipt runner unchanged."""
import argparse
import json
import subprocess
from pathlib import Path
import run_yellow_target as receipt

TASK = "PFALL_FORWARD_THEN_DROP_TO_YELLOW_FIX_01"
receipt.OUT_ROOT = receipt.ROOT / "docs/beta-sprint/game-feel-owner-03/forward-drop-01/evidence"
receipt.JOBS = {"sampler": ("test_forward_drop_sampler.gd", False),
                "formal": ("test_forward_drop_graphical.gd", True),
                "input": ("test_yellow_target_input.gd", True),
                "lifecycle": ("test_yellow_target_lifecycle.gd", True),
                "core": ("test_yellow_target_core.gd", False),
                "legacy_profile": ("test_yellow_target_legacy_profile.gd", False),
                "legacy_pconn": ("test_yellow_target_pconn.gd", False),
                "legacy_graphical": ("test_yellow_target_legacy_graphical.gd", True)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("job", choices=receipt.JOBS)
    parser.add_argument("name")
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--phase", choices=["baseline-red", "candidate"], required=True)
    parser.add_argument("--animation-commit")
    opts = parser.parse_args()
    if opts.phase == "baseline-red" and opts.job != "sampler":
        parser.error("Baseline headless sampler RED only; graphical window is not granted here")
    if opts.phase == "candidate":
        import re
        if not re.fullmatch(r"[0-9a-f]{40}", opts.animation_commit or ""):
            parser.error("New combined candidate requires the delivered10A full commit SHA")
        subprocess.run(["git", "-C", str(receipt.ROOT), "merge-base", "--is-ancestor",
                        opts.animation_commit, opts.candidate], check=True)
    code = receipt.run(opts.job, opts.name, opts.candidate)
    receipt.write(receipt.OUT_ROOT / opts.name / "task_binding.json",
                  dict(task=TASK, phase=opts.phase, animation_commit=opts.animation_commit,
                       original_recipe=receipt.JOBS[opts.job][0], graphical_window="Separate coordinator authorization required",
                       baseline_result_is_new_task_acceptance=False if opts.phase == "baseline-red" else None))
    raise SystemExit(code)
