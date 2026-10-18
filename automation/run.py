#!/usr/bin/env python
"""Điều phối tự động: Claude CLI hiện thực → gate (lint/test) → reviewer (Codex/Gemini) → sửa → ... theo từng phase.

Chạy từ thư mục gốc repo (He_Thong_QL_Diem):

    python automation/run.py --precheck                  # chạy mọi gate trên code hiện tại (nên làm 1 lần trước)
    python automation/run.py                             # chạy các phase còn lại, reviewer mặc định codex
    python automation/run.py --reviewer gemini           # dùng Gemini làm reviewer
    python automation/run.py --only P2                   # chỉ chạy một phase
    python automation/run.py --until P3                  # chạy tới hết P3 rồi dừng
    python automation/run.py --status                    # xem tiến độ
    python automation/run.py --unblock P2                # sau khi ghi quyết định vào decisions.md, cho phase chạy tiếp
    python automation/run.py --simulate                  # chạy thử đường ống với agent giả (không gọi AI, không sửa code)

Luật dừng (chống hai agent cãi nhau vô hạn):
- tối đa `max_review_rounds` lượt review và `max_total_rounds` lượt sửa (kể cả lượt sửa vì gate fail) mỗi phase;
- reviewer chỉ được chặn bằng finding BLOCKER/MAJOR gắn với một AC của phase;
- finding đã bị agent hiện thực DISPUTED mà reviewer vẫn giữ → escalate → BLOCKED;
- một finding bị mở lại sau khi agent ghi FIXED quá `max_same_finding_reopen` lần → BLOCKED;
- reviewer sửa file trong repo → script cất các thay đổi đó vào git stash, không giữ lại.
Chỉ dùng thư viện chuẩn Python.
"""
from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

AUTO = Path(__file__).resolve().parent
REPO = AUTO.parent
RUNS = AUTO / "runs"
STATE_FILE = RUNS / "state.json"
SUMMARY_FILE = RUNS / "SUMMARY.md"
IS_WIN = os.name == "nt"
BLOCKING = ("BLOCKER", "MAJOR")


# ───────────────────────────── tiện ích ─────────────────────────────
def now() -> str:
    return dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")


def log(msg: str) -> None:
    line = f"[{now()}] {msg}"
    print(line, flush=True)
    RUNS.mkdir(parents=True, exist_ok=True)
    with open(RUNS / "run.log", "a", encoding="utf-8") as f:
        f.write(line + "\n")


def rel(p: Path) -> str:
    return p.resolve().relative_to(REPO).as_posix()


def load_json(path: Path, default=None):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def save_json(path: Path, data) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)


def git(*args: str, check: bool = True) -> str:
    r = subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True, encoding="utf-8", errors="replace")
    if check and r.returncode != 0:
        raise SystemExit(f"git {' '.join(args)} lỗi:\n{r.stderr}")
    return r.stdout.strip()


def head() -> str:
    return git("rev-parse", "HEAD")


def dirty_paths() -> list[str]:
    """File khác HEAD về NỘI DUNG (bỏ qua khác biệt chỉ do CRLF/LF) + file mới chưa track (không tính .gitignore)."""
    def z(*args: str) -> list[str]:
        r = subprocess.run(["git", *args], cwd=REPO, capture_output=True, text=True, encoding="utf-8", errors="replace")
        return [x for x in r.stdout.split("\0") if x]
    changed = z("diff", "--name-only", "-z", "HEAD")
    untracked = z("ls-files", "--others", "--exclude-standard", "-z")
    return sorted(set(changed) | set(untracked))


def kill_tree(proc: subprocess.Popen) -> None:
    try:
        if IS_WIN:
            subprocess.run(["taskkill", "/T", "/F", "/PID", str(proc.pid)], capture_output=True)
        else:
            proc.kill()
    except Exception:
        pass


def run_proc(cmd, log_file: Path, timeout_min: float, cwd: Path = REPO, shell: bool = False) -> tuple[int, str]:
    """Chạy lệnh, ghi stdout+stderr vào log_file, trả (exit_code, output). Hết giờ → exit 124."""
    log_file.parent.mkdir(parents=True, exist_ok=True)
    if not shell:
        exe = shutil.which(cmd[0])
        if exe is None:
            raise SystemExit(f"Không tìm thấy lệnh '{cmd[0]}' trong PATH. Cài đặt hoặc sửa automation/config.json.")
        cmd = [exe, *cmd[1:]]
    with open(log_file, "w", encoding="utf-8", errors="replace") as out:
        out.write(f"# {now()}  cwd={cwd}\n# {cmd if shell else ' '.join(cmd)}\n\n")
        out.flush()
        proc = subprocess.Popen(cmd, cwd=cwd, stdout=out, stderr=subprocess.STDOUT, stdin=subprocess.DEVNULL, shell=shell)
        try:
            code = proc.wait(timeout=timeout_min * 60)
        except subprocess.TimeoutExpired:
            kill_tree(proc)
            out.write(f"\n# HẾT GIỜ sau {timeout_min} phút\n")
            code = 124
    return code, log_file.read_text(encoding="utf-8", errors="replace")


def env_has(key: str) -> bool:
    if os.environ.get(key):
        return True
    env = REPO / ".env"
    if env.exists():
        for line in env.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.strip().startswith(key + "=") and line.split("=", 1)[1].strip():
                return True
    return False


def parse_phase(pid: str) -> dict:
    path = AUTO / "phases" / f"{pid}.md"
    text = path.read_text(encoding="utf-8")
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n", text, re.S)
    meta = {}
    if m:
        for line in m.group(1).splitlines():
            if ":" in line:
                k, v = line.split(":", 1)
                meta[k.strip()] = v.strip()
    gates = [g.strip() for g in meta.get("gates", "").split(",") if g.strip()]
    return {"id": pid, "title": meta.get("title", pid), "gates": gates, "file": rel(path)}


def extract_json(text: str):
    """Lấy object JSON cuối cùng hợp lệ trong một chuỗi (phòng khi reviewer in kèm chữ)."""
    text = text.strip()
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    for m in reversed(list(re.finditer(r"\{", text))):
        chunk = text[m.start():]
        depth = 0
        for i, ch in enumerate(chunk):
            depth += ch == "{"
            depth -= ch == "}"
            if depth == 0:
                try:
                    obj = json.loads(chunk[: i + 1])
                    if isinstance(obj, dict) and "verdict" in obj:
                        return obj
                except json.JSONDecodeError:
                    pass
                break
    return None


def validate_review(obj) -> str | None:
    if not isinstance(obj, dict):
        return "không phải object JSON"
    for k in ("phase", "round", "verdict", "findings", "escalate"):
        if k not in obj:
            return f"thiếu trường '{k}'"
    if obj["verdict"] not in ("PASS", "FAIL"):
        return "verdict phải là PASS hoặc FAIL"
    for f in obj["findings"]:
        for k in ("id", "severity", "criterion", "status", "evidence", "fix_hint"):
            if k not in f:
                return f"finding thiếu '{k}'"
        if f["severity"] not in ("BLOCKER", "MAJOR", "MINOR"):
            return f"severity sai: {f['severity']}"
        if f["status"] not in ("NEW", "STILL_OPEN", "RESOLVED"):
            return f"status sai: {f['status']}"
    return None


# ───────────────────────────── điều phối ─────────────────────────────
class Runner:
    def __init__(self, args):
        self.args = args
        self.cfg = load_json(AUTO / "config.json")
        if not self.cfg:
            raise SystemExit("Không đọc được automation/config.json")
        self.lim = self.cfg["limits"]
        self.state = load_json(STATE_FILE, {"phases": {}, "precheck": None})
        self.reviewer_name = args.reviewer
        if self.reviewer_name not in self.cfg["reviewers"]:
            raise SystemExit(f"Reviewer '{self.reviewer_name}' không có trong config.json")

    # ---------- trạng thái ----------
    def save(self):
        save_json(STATE_FILE, self.state)
        self.write_summary()

    def ph(self, pid: str) -> dict:
        return self.state["phases"].setdefault(pid, {
            "status": "PENDING", "round": 0, "stage": None, "base": None, "commits": {},
            "review_rounds": 0, "fixed_reopen": {}, "disputed": [], "extra_rounds": 0, "history": [],
        })

    def write_summary(self):
        lines = [f"# Tiến độ tự động — cập nhật {now()}", "", f"Reviewer: `{self.reviewer_name}`", ""]
        pre = self.state.get("precheck")
        if pre:
            lines.append(f"Precheck: **{pre['result']}** lúc {pre['at']} (commit {pre['commit'][:8]})")
            lines.append("")
        lines += ["| Phase | Trạng thái | Vòng | Ghi chú |", "|---|---|---|---|"]
        for pid in self.cfg["phases"]:
            p = self.state["phases"].get(pid)
            if not p:
                lines.append(f"| {pid} | PENDING | 0 | |")
                continue
            note = p["history"][-1]["note"] if p["history"] else ""
            lines.append(f"| {pid} | {p['status']} | {p['round']} | {note} |")
        lines.append("")
        for pid in self.cfg["phases"]:
            p = self.state["phases"].get(pid)
            if p and p["status"] == "BLOCKED":
                lines += [f"## {pid} đang BLOCKED", "", p.get("blocked_reason", ""), "",
                          f"Xem `automation/runs/{pid}/`. Ghi quyết định vào `automation/decisions.md`, rồi chạy "
                          f"`python automation/run.py --unblock {pid}`.", ""]
        SUMMARY_FILE.parent.mkdir(parents=True, exist_ok=True)
        SUMMARY_FILE.write_text("\n".join(lines), encoding="utf-8")

    def event(self, p: dict, note: str):
        p["history"].append({"at": now(), "round": p["round"], "note": note})
        log(note)
        self.save()

    # ---------- bảo vệ ----------
    def guard_after_agent(self, phase: dict, who: str, base: str):
        """Hoàn tác thay đổi trái phép: file điều phối, migration đã có."""
        bad = []
        for path in dirty_paths():
            if path.startswith("automation/runs/"):
                continue
            if any(path == pp or path.startswith(pp) for pp in self.cfg["protected_paths"]):
                bad.append(path)
                continue
            for root in self.cfg.get("protect_existing_under", []):
                if path.startswith(root):
                    existed = subprocess.run(["git", "cat-file", "-e", f"{base}:{path}"], cwd=REPO,
                                             capture_output=True).returncode == 0
                    if existed:
                        bad.append(path)
        for path in bad:
            tracked = subprocess.run(["git", "cat-file", "-e", f"HEAD:{path}"], cwd=REPO, capture_output=True).returncode == 0
            if tracked:
                git("checkout", "HEAD", "--", path, check=False)
            else:
                try:
                    (REPO / path).unlink()
                except OSError:
                    pass
        if bad:
            log(f"CẢNH BÁO: {who} đã sửa file bị cấm, đã hoàn tác: {bad}")
        return bad

    def guard_reviewer(self, pid: str, rnd: int):
        changed = [p for p in dirty_paths() if not p.startswith("automation/runs/")]
        if changed:
            git("stash", "push", "--include-untracked", "-m", f"auto-reviewer-changes {pid} r{rnd}", check=False)
            log(f"CẢNH BÁO: reviewer đã sửa {len(changed)} file; đã cất vào git stash (không áp dụng): {changed[:10]}")
        return changed

    # ---------- agent ----------
    def fill(self, template: str, mapping: dict) -> str:
        out = template
        for k, v in mapping.items():
            out = out.replace("{" + k + "}", str(v))
        return out.replace("{{", "{").replace("}}", "}")

    def call_implementer(self, pid: str, rnd: int, kind: str, prompt_file: Path, timeout: float) -> int:
        short = (f"Đọc file {rel(prompt_file)} trong repo này và làm đúng toàn bộ yêu cầu trong đó. "
                 f"Không hỏi lại; ghi giả định vào báo cáo.")
        logf = RUNS / pid / f"{kind}-r{rnd}.agent.log"
        if self.args.simulate:
            logf.write_text("SIMULATE: không gọi Claude.\n", encoding="utf-8")
            if kind == "fix":
                save_json(RUNS / pid / f"fix-r{rnd}.json", {"round": rnd, "responses": []})
            else:
                (RUNS / pid / f"impl-r{rnd}.md").write_text("SIMULATE\n", encoding="utf-8")
            return 0
        cmd = [self.fill(c, {"short_prompt": short}) for c in self.cfg["implementer"]["command"]]
        code, _ = run_proc(cmd, logf, timeout)
        return code

    def call_reviewer(self, pid: str, rnd: int, prompt_file: Path, review_file: Path) -> dict | None:
        rcfg = self.cfg["reviewers"][self.reviewer_name]
        short = (f"Đọc file {rel(prompt_file)} trong repo này và làm đúng toàn bộ yêu cầu trong đó. "
                 f"Bạn là reviewer: KHÔNG sửa file nào của repo. Ghi kết quả JSON vào {rel(review_file)}.")
        last_msg = RUNS / pid / f"review-r{rnd}.last.txt"
        logf = RUNS / pid / f"review-r{rnd}.agent.log"
        if self.args.simulate:
            obj = {"phase": pid, "round": rnd, "verdict": "PASS", "summary": "SIMULATE", "criteria": [],
                   "findings": [], "suggestions": [], "escalate": []}
            if self.args.simulate_fail_once and rnd == 1:
                obj["verdict"] = "FAIL"
                obj["findings"] = [{"id": f"{pid}-F1", "severity": "MAJOR", "criterion": "AC-1", "status": "NEW",
                                    "location": "x:1", "evidence": "giả lập", "fix_hint": "giả lập", "note": ""}]
            save_json(review_file, obj)
            logf.write_text("SIMULATE\n", encoding="utf-8")
            return obj
        mapping = {"short_prompt": short, "last_message_file": str(last_msg),
                   "schema_file": str(AUTO / "schemas" / "review.schema.json"), "model": rcfg.get("model", "")}
        attempts = 2
        for attempt in range(1, attempts + 1):
            if review_file.exists():
                review_file.unlink()
            cmd = [self.fill(c, mapping) for c in rcfg["command"]]
            code, output = run_proc(cmd, logf.with_suffix(f".{attempt}.log"), self.lim["review_timeout_min"])
            self.guard_reviewer(pid, rnd)
            obj = load_json(review_file)
            if obj is None and last_msg.exists():
                obj = extract_json(last_msg.read_text(encoding="utf-8", errors="replace"))
            if obj is None:
                obj = extract_json(output)
            err = validate_review(obj) if obj is not None else "không tìm thấy JSON kết quả"
            if err is None:
                save_json(review_file, obj)
                return obj
            log(f"{pid} r{rnd}: kết quả review không hợp lệ ({err}), exit={code}, lần {attempt}/{attempts}")
            mapping["short_prompt"] = short + f" LẦN TRƯỚC KẾT QUẢ KHÔNG HỢP LỆ: {err}. Phải ghi đúng khung JSON."
        return None

    # ---------- gate ----------
    def run_gates(self, gates: list[str], tag: str, out_dir: Path) -> dict:
        results, ok = [], True
        out_dir.mkdir(parents=True, exist_ok=True)
        combined = out_dir / f"gate-{tag}.log"
        parts = []
        for g in gates:
            gcfg = self.cfg["gates"].get(g)
            if gcfg is None:
                raise SystemExit(f"Gate '{g}' không có trong config.json")
            if gcfg.get("require_env") and not env_has(gcfg["require_env"]):
                status = "SKIPPED" if gcfg.get("on_missing", "skip") == "skip" else "FAIL"
                results.append({"gate": g, "status": status, "reason": f"thiếu {gcfg['require_env']}"})
                parts.append(f"## {g}: {status} (thiếu biến {gcfg['require_env']})\n")
                ok = ok and status != "FAIL"
                continue
            cwd = (REPO / gcfg.get("cwd", ".")).resolve()
            venv = REPO / ".local" / "venv-ml" / ("Scripts/python.exe" if IS_WIN else "bin/python")
            for i, cmd in enumerate(gcfg["commands"]):
                cmd_s = cmd.replace("{venv_python}", f'"{venv}"')
                if self.args.simulate:
                    code, output = 0, "SIMULATE"
                else:
                    code, output = run_proc(cmd_s, out_dir / f"gate-{tag}-{g}-{i}.log", self.lim["gate_timeout_min"],
                                            cwd=cwd, shell=True)
                status = "PASS" if code == 0 else "FAIL"
                ok = ok and code == 0
                results.append({"gate": g, "command": cmd_s, "status": status, "exit": code})
                tail = "\n".join(output.splitlines()[-120:])
                parts.append(f"## {g}: {status} (exit {code})\n$ {cmd_s}\n```\n{tail}\n```\n")
                if code != 0:
                    break
        combined.write_text("\n".join(parts), encoding="utf-8")
        return {"ok": ok, "results": results, "log": rel(combined)}

    # ---------- precheck ----------
    def precheck(self):
        gates = sorted({g for pid in self.cfg["phases"] for g in parse_phase(pid)["gates"]})
        log(f"Precheck các gate {gates} trên commit {head()[:8]} ...")
        res = self.run_gates(gates, "precheck", RUNS / "precheck")
        self.state["precheck"] = {"result": "PASS" if res["ok"] else "FAIL", "at": now(), "commit": head(),
                                  "results": res["results"]}
        self.save()
        log(f"Precheck: {'PASS' if res['ok'] else 'FAIL'} — xem {res['log']}")
        if not res["ok"]:
            log("Code hiện tại đã fail gate. Sửa cho xanh (hoặc sửa config.json) trước khi chạy phase, "
                "nếu không agent sẽ đổ lỗi cho nhau về lỗi có sẵn.")
        return res["ok"]

    # ---------- một phase ----------
    def commit(self, msg: str) -> str:
        if self.args.simulate:
            return head()
        changed = [p for p in dirty_paths() if not p.startswith("automation/runs/")]
        if changed:
            git("add", "-A")
            git("commit", "-m", msg)
        return head()

    def run_phase(self, pid: str) -> str:
        phase = parse_phase(pid)
        p = self.ph(pid)
        if p["status"] == "PASS":
            return "PASS"
        if p["status"] == "BLOCKED":
            log(f"{pid} đang BLOCKED. Ghi quyết định vào automation/decisions.md rồi chạy --unblock {pid}.")
            return "BLOCKED"
        rd = RUNS / pid
        rd.mkdir(parents=True, exist_ok=True)
        if p["base"] is None:
            leftover = [x for x in dirty_paths() if not x.startswith("automation/runs/")]
            if leftover and not self.args.simulate:
                raise SystemExit(f"Repo còn thay đổi chưa commit: {leftover[:10]} ... Commit hoặc stash trước khi chạy.")
            p.update(base=head(), round=1, stage="agent", status="RUNNING")
            self.event(p, f"{pid}: bắt đầu — {phase['title']} (base {p['base'][:8]})")
        max_total = self.lim["max_total_rounds"] + p["extra_rounds"]
        max_review = self.lim["max_review_rounds"] + p["extra_rounds"]

        while True:
            rnd = p["round"]
            if p["stage"] == "agent":
                kind = "implement" if rnd == 1 else "fix"
                tpl = (AUTO / "prompts" / f"{kind}.md").read_text(encoding="utf-8")
                prev_fix = [rel(rd / f"fix-r{i}.json") for i in range(2, rnd) if (rd / f"fix-r{i}.json").exists()]
                prompt = self.fill(tpl, {
                    "phase_id": pid, "phase_title": phase["title"], "phase_file": phase["file"], "round": rnd,
                    "run_dir": rel(rd), "gates": ", ".join(phase["gates"]),
                    "prev_review_file": rel(rd / f"review-r{rnd - 1}.json"),
                    "prev_gate_log": rel(rd / f"gate-r{rnd - 1}.log"),
                    "prev_fix_files": ", ".join(prev_fix) or "(chưa có)",
                })
                pf = rd / f"prompt-r{rnd}-{kind}.md"
                pf.write_text(prompt, encoding="utf-8")
                timeout = self.lim["implement_timeout_min" if kind == "implement" else "fix_timeout_min"]
                self.event(p, f"{pid} r{rnd}: Claude {kind} ...")
                code = self.call_implementer(pid, rnd, kind, pf, timeout)
                if code != 0:
                    p["stage"] = "agent"
                    self.event(p, f"{pid} r{rnd}: Claude kết thúc với exit {code} (hết giờ/hạn mức/lỗi). "
                                  f"Dừng; chạy lại script để thử tiếp vòng này.")
                    return "AGENT_ERROR"
                self.guard_after_agent(phase, "Claude", p["base"])
                p["commits"][str(rnd)] = self.commit(f"auto({pid}): r{rnd} {kind}")
                p["stage"] = "gate"
                self.save()

            if p["stage"] == "gate":
                self.event(p, f"{pid} r{rnd}: chạy gate {phase['gates']} ...")
                g = self.run_gates(phase["gates"], f"r{rnd}", rd)
                save_json(rd / f"gate-r{rnd}.json", g)
                (rd / f"gate-r{rnd}.log").write_text((REPO / g["log"]).read_text(encoding="utf-8"), encoding="utf-8")
                if not g["ok"]:
                    failed = [r for r in g["results"] if r["status"] == "FAIL"]
                    review = {"phase": pid, "round": rnd, "verdict": "FAIL", "summary": "Gate tự động fail.",
                              "criteria": [], "suggestions": [], "escalate": [],
                              "findings": [{"id": f"GATE-{r['gate']}", "severity": "BLOCKER", "criterion": "GATE",
                                            "status": "NEW", "location": rel(rd / f"gate-r{rnd}.log"),
                                            "evidence": f"{r.get('command', '')} → exit {r.get('exit')}",
                                            "fix_hint": "Đọc log gate, sửa cho lệnh pass. Không nới test.", "note": ""}
                                           for r in failed]}
                    save_json(rd / f"review-r{rnd}.json", review)
                    self.event(p, f"{pid} r{rnd}: gate FAIL ({[r['gate'] for r in failed]}) → bỏ qua review, sửa luôn")
                    p["stage"] = "decide"
                else:
                    p["stage"] = "review"
                self.save()

            if p["stage"] == "review":
                p["review_rounds"] += 1
                tpl = (AUTO / "prompts" / "review.md").read_text(encoding="utf-8")
                impl_files = [rel(f) for f in sorted(rd.glob("impl-r*.md"))] + \
                             [rel(f) for f in sorted(rd.glob("fix-r*.json"))]
                prev_commit = p["commits"].get(str(rnd - 1), p["base"])
                scope = "" if p["review_rounds"] == 1 else (
                    f"\n6. Vòng này: review trước của bạn ở `{p.get('last_review', '')}`, "
                    f"phần sửa mới: `git diff {prev_commit}..HEAD`, phản hồi của agent hiện thực: "
                    f"`{rel(rd / f'fix-r{rnd}.json')}`.")
                review_file = rd / f"review-r{rnd}.json"
                prompt = self.fill(tpl, {
                    "phase_id": pid, "phase_title": phase["title"], "phase_file": phase["file"],
                    "round": p["review_rounds"], "max_review_rounds": max_review, "run_dir": rel(rd),
                    "gate_log": rel(rd / f"gate-r{rnd}.log"), "impl_files": ", ".join(impl_files) or "(không có)",
                    "base_commit": p["base"], "prev_commit": prev_commit, "round_scope": scope,
                    "review_file": rel(review_file),
                })
                pf = rd / f"prompt-r{rnd}-review.md"
                pf.write_text(prompt, encoding="utf-8")
                self.event(p, f"{pid} r{rnd}: {self.reviewer_name} review (lượt review {p['review_rounds']}/{max_review}) ...")
                obj = self.call_reviewer(pid, rnd, pf, review_file)
                if obj is None:
                    return self.block(p, pid, "Reviewer không trả được kết quả JSON hợp lệ sau 2 lần. "
                                              f"Xem log `automation/runs/{pid}/review-r{rnd}.agent.*.log`.")
                p["last_review"] = rel(review_file)
                p["stage"] = "decide"
                self.save()

            if p["stage"] == "decide":
                review = load_json(rd / f"review-r{rnd}.json")
                fix_now = load_json(rd / f"fix-r{rnd}.json", {"responses": []})
                # Tranh chấp: finding bị DISPUTED ở vòng này mà reviewer vẫn để mở → escalate.
                disputed_now = {r["id"] for r in fix_now.get("responses", []) if r.get("action") == "DISPUTED"}
                escalate = list(review.get("escalate", []))
                open_blocking = [f for f in review["findings"]
                                 if f["severity"] in BLOCKING and f["status"] != "RESOLVED"]
                for f in open_blocking:
                    if f["id"] in disputed_now or f["id"] in p["disputed"]:
                        escalate.append({"id": f["id"], "question": "Hai agent bất đồng sau một lượt tranh luận.",
                                         "implementer_position": "xem fix-r*.json", "reviewer_position": f["evidence"]})
                p["disputed"] = sorted(set(p["disputed"]) | disputed_now)
                # Lỗi bị mở lại sau khi đã ghi FIXED.
                fixed_now = {r["id"] for r in fix_now.get("responses", []) if r.get("action") == "FIXED"}
                for f in open_blocking:
                    if f["id"] in fixed_now and f["status"] == "STILL_OPEN":
                        p["fixed_reopen"][f["id"]] = p["fixed_reopen"].get(f["id"], 0) + 1
                reopened = [k for k, v in p["fixed_reopen"].items() if v >= self.lim["max_same_finding_reopen"]]
                esc_from_fix = [r["id"] for r in fix_now.get("responses", []) if r.get("action") == "ESCALATE"]

                if escalate or esc_from_fix:
                    ids = [e["id"] for e in escalate] + esc_from_fix
                    return self.block(p, pid, f"Cần chủ dự án quyết: {sorted(set(ids))}. Xem `review-r{rnd}.json` "
                                              f"(mục escalate) và `fix-r*.json`.")
                if reopened:
                    return self.block(p, pid, f"Finding {reopened} bị mở lại sau khi đã sửa "
                                              f"{self.lim['max_same_finding_reopen']} lần. Cần người xem.")
                if not open_blocking:
                    if review["verdict"] != "PASS":
                        log(f"{pid} r{rnd}: reviewer ghi FAIL nhưng không còn finding chặn → script coi là PASS.")
                    if not self.args.simulate:
                        git("commit", "--allow-empty", "-m", f"auto({pid}): PASS — {phase['title']}")
                    p.update(status="PASS", stage=None)
                    self.event(p, f"{pid}: PASS sau {rnd} vòng")
                    return "PASS"
                if rnd >= max_total or p["review_rounds"] >= max_review:
                    return self.block(p, pid, f"Hết số vòng (vòng {rnd}/{max_total}, review {p['review_rounds']}/{max_review}) "
                                              f"mà còn {len(open_blocking)} finding chặn: "
                                              f"{[f['id'] for f in open_blocking]}.")
                p["round"] = rnd + 1
                p["stage"] = "agent"
                self.event(p, f"{pid} r{rnd}: FAIL, {len(open_blocking)} finding chặn → vòng sửa {rnd + 1}")

    def block(self, p: dict, pid: str, reason: str) -> str:
        p.update(status="BLOCKED", blocked_reason=reason)
        self.event(p, f"{pid}: BLOCKED — {reason}")
        return "BLOCKED"

    def unblock(self, pid: str):
        p = self.ph(pid)
        if p["status"] != "BLOCKED":
            raise SystemExit(f"{pid} không ở trạng thái BLOCKED (hiện: {p['status']}).")
        p["extra_rounds"] += self.lim["unblock_extra_rounds"]
        p["disputed"] = []
        p["fixed_reopen"] = {}
        p["status"] = "RUNNING"
        if p["stage"] in ("decide", "review", None):
            p["round"] += 1
            p["stage"] = "agent"
        self.event(p, f"{pid}: mở khóa theo decisions.md, thêm {self.lim['unblock_extra_rounds']} vòng")

    # ---------- toàn bộ ----------
    def run_all(self):
        pre = self.state.get("precheck")
        if not self.args.simulate and not self.args.skip_precheck and (not pre or pre["result"] != "PASS"):
            raise SystemExit("Chưa có precheck PASS. Chạy `python automation/run.py --precheck` trước "
                             "(hoặc thêm --skip-precheck nếu chấp nhận rủi ro).")
        phases = self.cfg["phases"]
        if self.args.only:
            phases = [self.args.only]
        elif self.args.until:
            phases = phases[: phases.index(self.args.until) + 1]
        for pid in phases:
            res = self.run_phase(pid)
            if res != "PASS":
                log(f"Dừng ở {pid}: {res}. Xem automation/runs/SUMMARY.md")
                self.save()
                return 1
        log("Hoàn tất các phase được yêu cầu.")
        self.save()
        return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--reviewer", default="codex")
    ap.add_argument("--only")
    ap.add_argument("--until")
    ap.add_argument("--precheck", action="store_true")
    ap.add_argument("--skip-precheck", action="store_true")
    ap.add_argument("--status", action="store_true")
    ap.add_argument("--unblock")
    ap.add_argument("--simulate", action="store_true", help="agent giả, gate giả: chỉ kiểm đường ống")
    ap.add_argument("--simulate-fail-once", action="store_true", help="(với --simulate) reviewer FAIL ở vòng 1")
    args = ap.parse_args()
    if args.simulate:
        global RUNS, STATE_FILE, SUMMARY_FILE
        RUNS = AUTO / "runs" / "_simulate"
        STATE_FILE, SUMMARY_FILE = RUNS / "state.json", RUNS / "SUMMARY.md"
    r = Runner(args)
    if args.status:
        r.write_summary()
        print(SUMMARY_FILE.read_text(encoding="utf-8"))
        return 0
    if args.precheck:
        return 0 if r.precheck() else 1
    if args.unblock:
        r.unblock(args.unblock)
        return r.run_all()
    return r.run_all()


if __name__ == "__main__":
    sys.exit(main())
