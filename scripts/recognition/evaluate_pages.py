#!/usr/bin/env python
"""Đánh giá cục bộ pipeline nhận dạng trên ảnh TRANG (BE-21/BE-22). Không chạy trong CI, không in họ tên.

Chạy pipeline + mô hình thật (như dịch vụ nhận dạng) trên từng ảnh trang, ghép kết quả với nhãn ô theo
(người, tờ, trang, stt) từ ``06_ANH_O_CAT/<valid|test>/manifest_*_{num,txt}.csv``, rồi tính độ chính xác từng kênh,
độ chính xác giá trị cuối, tỷ lệ Xanh/Vàng/Đỏ, số dòng Xanh sai (lỗi im lặng) và số dòng gán sai học sinh, tách phone/scan.

    python scripts/recognition/evaluate_pages.py run    --split dev|test      # chạy mô hình, lưu .local/eval/<split>.json
    python scripts/recognition/evaluate_pages.py report --split dev|test [--floor 0.0]
    python scripts/recognition/evaluate_pages.py tune   --split dev           # dò mức sàn đồng thuận (chỉ DEV)

Tập dữ liệu (không dùng tập TRAIN): DEV = P05, R03, T03; TEST = P08, R04, R05, T06, T07.
Bước ``run`` cần torch/vietocr (venv ``.local/venv-ml``) và biến RECOGNITION_{CRNN,VIETOCR,NAME}_WEIGHTS (có thể kèm
*_SHA256; thiếu thì lấy hash của chính tệp, chỉ chấp nhận cho đánh giá cục bộ). ``report``/``tune`` chỉ đọc bộ nhớ đệm.
Họ tên học sinh chỉ dùng trong bộ nhớ và trong tệp ``.local/eval`` (git ignore); không bao giờ in ra.
"""
from __future__ import annotations

import argparse
import collections
import csv
import json
import html
import os
import re
import shutil
import statistics
import subprocess
import sys
import time
import zipfile
from decimal import Decimal
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "apps" / "recognition-service"))

from src.domain import (  # noqa: E402
    ChannelPrediction,
    Suggestion,
    classify_channels,
    thresholds_from_env,
)
from src.domain.written_grade import (  # noqa: E402
    grade_decimal,
    nan_diem_chu,
    so_tu_chuoi_chu,
    so_tu_chuoi_so,
)

DATA = Path(os.environ.get("KLCN_DATA", r"D:\HocTap\KhoaLuan\App\KLCN_2026"))
WEIGHTS = Path(os.environ.get("RECOGNITION_WEIGHTS_DIR", r"D:\HocTap\KhoaLuan\App\weights"))
CACHE_DIR = ROOT / ".local" / "eval"
SPLITS = {
    "dev": ("valid", "manifest_val", {"P05", "R03", "T03"}),
    "test": ("test", "manifest_test", {"P08", "R04", "R05", "T06", "T07"}),
}
TRAIN = {"P01", "P02", "P03", "P04", "P06", "P07", "P09", "P10", "P11", "R01", "R02", "T02", "T05"}
PAGE_START = {"p1": 1, "p2": 39}  # mọi mẫu E0330113 trong bộ dữ liệu: 38 dòng ở trang 1, trang 2 bắt đầu từ STT 39
ROSTERS = DATA / "03_DU_LIEU_TONG_HOP" / "BANG_DIEM_CHEP_TAY_Sheet_01_10.xlsx"
LEVEL_RANK = {"DO": 0, "VANG": 1, "XANH": 2}


# ───────────────────────────── dữ liệu ─────────────────────────────
def load_labels(split: str) -> dict[tuple, dict]:
    folder, stem, people = SPLITS[split]
    labels: dict[tuple, dict] = {}
    seen: set[str] = set()
    for kind in ("num", "txt"):
        path = DATA / "06_ANH_O_CAT" / folder / f"{stem}_{kind}.csv"
        if not path.is_file():
            raise SystemExit(f"Thiếu nhãn: {path}")
        for row in csv.DictReader(path.open(encoding="utf-8-sig")):
            person = row["nguoi"]
            if person in TRAIN or person not in people:
                raise SystemExit(f"Người {person} không thuộc tập {split}: dừng.")
            seen.add(person)
            key = (person, row["to"], row["trang"], row["nguon"], int(row["stt"]))
            value = (
                grade_decimal(so_tu_chuoi_so(row["nhan"]))
                if kind == "num"
                else grade_decimal(so_tu_chuoi_chu(nan_diem_chu(row["nhan"])))
            )
            labels.setdefault(key, {"bo": row["bo_nhan"]})[kind] = value
    if seen != people:
        raise SystemExit(f"Nhãn thiếu người: {sorted(people - seen)}")
    return labels


def page_image(person: str, sheet: str, page: str, source: str) -> Path:
    folder = "BAN_PHONE" if source == "phone" else "BAN_SCAN"
    path = DATA / "05_BANG_DIEM_GOC" / folder / f"PERSON_{person}" / f"{person}_{sheet}_{page}_{source}.jpg"
    if not path.is_file():
        raise SystemExit(f"Thiếu ảnh trang: {path}")
    return path


def page_keys(labels: dict) -> list[tuple]:
    return sorted({k[:4] for k in labels})


# ───────────────────────────── chạy mô hình ─────────────────────────────
def channel_json(c: ChannelPrediction) -> dict:
    return {
        "value": None if c.value is None else str(c.value),
        "confidence": None if c.confidence is None else str(c.confidence),
        "blank": c.is_blank,
    }


def run(split: str, limit: int | None, tag: str = "") -> None:
    from src.adapters.crnn import sha256_of
    from src.adapters.model import configured_model

    env = dict(os.environ)
    env.setdefault("APP_ENV", "production")
    env["RECOGNITION_MODEL_MODE"] = "weights"
    env["RECOGNITION_STT_CHECK"] = "1"  # luôn đọc STT khi đánh giá; bật/tắt lớp xác nhận STT ở bước report/ghép
    for prefix, name in (
        ("CRNN", "crnn_num_best_dot5.pth"),
        ("VIETOCR", "vietocr_best_tang4.pth"),
        ("NAME", "vietocr_vgg_seq2seq_pretrained.pth"),
    ):
        path = Path(env.setdefault(f"RECOGNITION_{prefix}_WEIGHTS", str(WEIGHTS / name)))
        env.setdefault(f"RECOGNITION_{prefix}_SHA256", sha256_of(path))
    model = configured_model(env)
    # Ghi nhận ô họ tên nào thực sự được thu khe (compact_name_cell trả ảnh khác ảnh vào), theo thứ tự dòng.
    import src.pipeline.rows as rows_module

    collapsed: list[bool] = []
    original_compact = rows_module.compact_name_cell

    def recording_compact(cell):
        result = original_compact(cell)
        collapsed.append(cell is not None and result is not cell)
        return result

    rows_module.compact_name_cell = recording_compact
    labels = load_labels(split)
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache_path = CACHE_DIR / f"{split}{tag}.json"
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.is_file() else {"pages": {}}
    keys = page_keys(labels)[: limit or None]
    for index, key in enumerate(keys, 1):
        name = "|".join(key)
        if name in cache["pages"]:
            continue
        started = time.time()
        collapsed.clear()
        try:
            result = model.recognize(page_image(*key).read_bytes())
            # compact_name_cell chỉ được gọi cho dòng không bị gạch, theo thứ tự dòng.
            recorded = iter(collapsed)
            flags = [None if r.struck else next(recorded, None) for r in result.rows]
            cache["modelVersion"] = result.model_version
            cache["pages"][name] = {
                "seconds": round(time.time() - started, 2),
                "rows": [
                    {
                        "index": r.row_index,
                        "struck": r.struck,
                        "numeric": channel_json(r.numeric),
                        "written": channel_json(r.written),
                        "nameRaw": r.name.raw_output,
                        "nameBlank": r.name.is_blank,
                        "gapCollapsed": flags[i],
                        "stt": {"value": r.stt.value, "read": r.stt_read, "position": r.stt_from_position},
                    }
                    for i, r in enumerate(result.rows)
                ],
            }
        except Exception as error:  # noqa: BLE001 - ghi mã lỗi ổn định, không in nội dung
            cache["pages"][name] = {"seconds": round(time.time() - started, 2), "error": type(error).__name__ + ":" + str(getattr(error, "code", ""))}
        cache_path.write_text(json.dumps(cache), encoding="utf-8")
        print(f"[{index}/{len(keys)}] {key[0]} {key[1]} {key[2]} {key[3]}: {cache['pages'][name]['seconds']}s", flush=True)


# ───────────────────────────── phân loại ─────────────────────────────
def prediction(c: dict) -> ChannelPrediction:
    return ChannelPrediction(
        raw_output=None,
        value=None if c["value"] is None else Decimal(c["value"]),
        confidence=None if c["confidence"] is None else Decimal(c["confidence"]),
        is_blank=c["blank"],
    )


def legacy_classify(numeric: ChannelPrediction, written: ChannelPrediction, tau_n: Decimal, tau_w: Decimal):
    """Luật TRƯỚC BE-22 (chỉ để so sánh): Xanh khi hai kênh khớp VÀ cả hai ≥ ngưỡng; lệch/một kênh = Vàng; Đỏ khi không
    kênh nào đọc được. Giá trị gợi ý theo màn hình đối chiếu cũ: KHỚP → điểm số; MỘT_KÊNH → kênh đọc được; còn lại không."""
    readable = [c for c in (numeric, written) if c.readable]
    if not readable:
        return "DO", None
    if len(readable) == 1:
        return "VANG", (numeric.value if numeric.readable else written.value)
    if numeric.value != written.value:
        return "VANG", None
    confident = (numeric.confidence or 0) >= tau_n and (written.confidence or 0) >= tau_w
    return ("XANH" if confident else "VANG"), numeric.value


def research_classify(numeric, written, tau_n, tau_w, floor: Decimal):
    result = classify_channels(
        numeric, written,
        numeric_confidence=tau_n, written_confidence=tau_w,
        numeric_floor=floor, written_floor=floor,
    )
    value = None
    if result.suggestion is Suggestion.NUMERIC:
        value = numeric.value
    elif result.suggestion is Suggestion.WRITTEN:
        value = written.value
    return {"XANH": "XANH", "VANG": "VANG", "DO": "DO"}[result.level.value], value


# ───────────────────────────── ghép học sinh (bộ ghép thật của API) ─────────────────────────────
def read_sheet(path: str, index: int) -> dict[int, dict]:
    """Đọc một sheet .xlsx bằng thư viện chuẩn (không cần openpyxl): {số dòng: {cột: giá trị}}."""
    z = zipfile.ZipFile(path)
    shared = []
    if "xl/sharedStrings.xml" in z.namelist():
        for si in re.findall(r"<si>(.*?)</si>", z.read("xl/sharedStrings.xml").decode("utf8"), re.S):
            shared.append(html.unescape("".join(re.findall(r"<t[^>]*>(.*?)</t>", si, re.S))))
    xml = z.read(f"xl/worksheets/sheet{index}.xml").decode("utf8")
    rows = {}
    for r in re.findall(r"<row [^>]*r=\"(\d+)\"[^>]*>(.*?)</row>", xml, re.S):
        cells = {}
        for ref, attrs, body in re.findall(r"<c r=\"([A-Z]+)\d+\"([^>]*?)(?:/>|>(.*?)</c>)", r[1], re.S):
            v = re.search(r"<v>(.*?)</v>", body or "", re.S)
            if not v: 
                t = re.search(r"<t[^>]*>(.*?)</t>", body or "", re.S)
                cells[ref] = html.unescape(t.group(1)) if t else None
                continue
            cells[ref] = shared[int(v.group(1))] if 't="s"' in attrs else v.group(1)
        rows[int(r[0])] = cells
    return rows


def roster_names(sheet_number: int) -> list[str]:
    rows = read_sheet(str(ROSTERS), sheet_number)
    names = []
    for index in range(16, 60):
        cells = rows.get(index, {})
        if cells.get("B") and cells.get("D"):
            names.append(f"{cells['D']} {cells.get('E') or ''}".strip())
    return names


def match_pages(cache: dict, labels: dict, stt_check: bool = False, struck_active: bool = False) -> dict[str, dict]:
    """Chạy bộ ghép dòng THẬT (row-matching.ts) cho các trang có danh sách lớp (Sheet_xx). Trang khác: không đánh giá."""
    rosters: dict[str, list[str]] = {}
    pages = []
    for name, page in cache["pages"].items():
        person, sheet, trang, source = name.split("|")
        if "rows" not in page or not sheet.startswith("S") or not any(
            labels_key[:4] == (person, sheet, trang, source) and labels[labels_key]["bo"].startswith("Sheet_")
            for labels_key in labels
        ):
            continue
        number = int(sheet[1:])
        rosters.setdefault(sheet, roster_names(number))
        pages.append({"key": name, "sheet": sheet, "start": PAGE_START[trang], "rows": page["rows"]})
    source = CACHE_DIR / "match-input.json"
    source.write_text(json.dumps({"rosters": rosters, "pages": pages, "sttCheck": stt_check, "struckStudentsActive": struck_active}), encoding="utf-8")
    out = subprocess.run(
        [shutil.which("node") or "node", "--import", "tsx", "scripts/recognition/evaluate_matching.ts", str(source)],
        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True,
    )
    return {item["key"]: item for item in json.loads(out.stdout)}


# ───────────────────────────── báo cáo ─────────────────────────────
def evaluate(cache: dict, labels: dict, matches: dict, rule: str, floor: Decimal) -> dict:
    tau_n, tau_w = thresholds_from_env(os.environ)
    groups: dict[str, collections.Counter] = {s: collections.Counter() for s in ("phone", "scan", "all")}
    confidences = {"num_ok": [], "num_bad": [], "txt_ok": [], "txt_bad": []}
    seconds = []
    for name, page in cache["pages"].items():
        person, sheet, trang, source = name.split("|")
        seconds.append(page["seconds"])
        by_index = {r["index"]: r for r in page.get("rows", [])}
        match = matches.get(name)
        for key, label in labels.items():
            if key[:4] != (person, sheet, trang, source):
                continue
            c = groups[source]
            c["labelled"] += 1
            if "error" in page:
                c["page_error"] += 1
                continue
            row = by_index.get(key[4] - PAGE_START[trang] + 1)
            if row is None or row["struck"] or (row["numeric"]["blank"] and row["written"]["blank"]):
                c["lost"] += 1
                continue
            numeric, written = prediction(row["numeric"]), prediction(row["written"])
            stt = row.get("stt")
            if stt is not None:
                c["stt_rows"] += 1
                c["stt_read_ok"] += stt["read"] == key[4]
                c["stt_position_ok"] += stt["position"] == key[4]
                c["stt_value_present"] += stt["value"] is not None
                c["stt_value_ok"] += stt["value"] == key[4]
            if not row["nameBlank"] and row.get("gapCollapsed") is not None:
                c["name_ink"] += 1
                c["name_collapsed"] += bool(row["gapCollapsed"])
            truth = label["num"]
            c["read"] += 1
            num_ok = numeric.value == truth
            txt_ok = written.value == label["txt"]
            c["num_ok"] += num_ok
            c["txt_ok"] += txt_ok
            if numeric.confidence is not None:
                confidences["num_ok" if num_ok else "num_bad"].append(float(numeric.confidence))
            if written.confidence is not None:
                confidences["txt_ok" if txt_ok else "txt_bad"].append(float(written.confidence))
            if label["num"] != label["txt"]:
                c["labels_disagree"] += 1
            level, value = (
                legacy_classify(numeric, written, tau_n, tau_w)
                if rule == "legacy"
                else research_classify(numeric, written, tau_n, tau_w, floor)
            )
            c[f"grade_{level}"] += 1
            correct = value is not None and value == truth
            c["final_correct"] += correct
            c["final_suggested"] += value is not None
            if level == "XANH" and not correct:
                c["green_wrong"] += 1
            if level == "VANG" and value is not None and not correct:
                c["yellow_wrong"] += 1
            if match is not None and match["ok"]:
                assigned = next((m for m in match["matches"] if m["rowIndex"] == row["index"]), None)
                if assigned is not None:
                    c["match_eval"] += 1
                    wrong = assigned["paperIndex"] != key[4] - 1
                    c["match_wrong"] += wrong
                    final = level if LEVEL_RANK[level] <= LEVEL_RANK[assigned["level"]] else assigned["level"]
                    c[f"final_{final}"] += 1
                    if assigned["level"] == "VANG" and assigned.get("note") in ("STT_MISMATCH", "STT_UNCONFIRMED", "DUPLICATE_NAME"):
                        c["yellow_" + assigned["note"].lower()] += 1
                    c["final_green_wrong"] += (final == "XANH") and (wrong or not correct)
            elif match is not None:
                c["match_page_failed_rows"] += 1
    c_all = groups["all"]
    for source in ("phone", "scan"):
        c_all.update(groups[source])
    return {"groups": {k: dict(v) for k, v in groups.items()}, "seconds": seconds, "confidences": confidences}


def pct(a: int, b: int) -> str:
    return "n/a" if not b else f"{100 * a / b:.1f}%"


def print_report(title: str, result: dict) -> None:
    print(f"\n== {title}")
    for source in ("phone", "scan", "all"):
        c = collections.Counter(result["groups"][source])
        read = c["read"]
        n = c["labelled"]
        print(
            f"  [{source:5}] nhãn {n}, đọc được dòng {read}, mất dòng {c['lost']}, lỗi trang {c['page_error']} | "
            f"Đ.số đúng {pct(c['num_ok'], read)}, Điểm chữ đúng {pct(c['txt_ok'], read)} | "
            f"Xanh/Vàng/Đỏ {c['grade_XANH']}/{c['grade_VANG']}/{c['grade_DO']} "
            f"({pct(c['grade_XANH'], read)}/{pct(c['grade_VANG'], read)}/{pct(c['grade_DO'], read)}) | "
            f"giá trị cuối đúng {pct(c['final_correct'], n)} (trên dòng có gợi ý {pct(c['final_correct'], c['final_suggested'])}) | "
            f"Xanh SAI {c['green_wrong']}, Vàng gợi ý sai {c['yellow_wrong']}"
        )
        if c["stt_rows"]:
            print(
                f"           STT: đọc đúng {pct(c['stt_read_ok'], c['stt_rows'])}, suy theo vị trí đúng {pct(c['stt_position_ok'], c['stt_rows'])}, "
                f"sttOnPaper có giá trị {pct(c['stt_value_present'], c['stt_rows'])} và đúng {pct(c['stt_value_ok'], c['stt_rows'])} "
                f"(sai {c['stt_value_present'] - c['stt_value_ok']} dòng)"
            )
        if c["name_ink"]:
            print(f"           ô họ tên được thu khe: {c['name_collapsed']}/{c['name_ink']} ({pct(c['name_collapsed'], c['name_ink'])})")
        if c["match_eval"] or c["match_page_failed_rows"]:
            print(
                f"           ghép học sinh: {c['match_eval']} dòng, gán sai {c['match_wrong']}, dòng ở trang ghép lỗi {c['match_page_failed_rows']}; "
                f"mức cuối Xanh/Vàng/Đỏ {c['final_XANH']}/{c['final_VANG']}/{c['final_DO']}, Xanh cuối sai {c['final_green_wrong']}; "
                f"Vàng do STT lệch {c['yellow_stt_mismatch']}, do không xác nhận được STT {c['yellow_stt_unconfirmed']}, do trùng họ tên {c['yellow_duplicate_name']}"
            )
    conf = result["confidences"]
    for name, label in (("num", "Đ.số"), ("txt", "Điểm chữ")):
        ok, bad = conf[f"{name}_ok"], conf[f"{name}_bad"]
        print(
            f"  tin cậy {label}: đúng trung vị {statistics.median(ok):.3f} (n={len(ok)}), "
            f"sai trung vị {statistics.median(bad):.3f} (n={len(bad)})" if ok and bad else f"  tin cậy {label}: n/a"
        )
    sec = result["seconds"]
    if sec:
        print(f"  thời gian/ảnh trang: trung vị {statistics.median(sec):.1f}s, lớn nhất {max(sec):.1f}s ({len(sec)} ảnh)")


def load_cache(split: str, tag: str = "") -> dict:
    path = CACHE_DIR / f"{split}{tag}.json"
    if not path.is_file():
        raise SystemExit(f"Chưa có {path}; chạy `run --split {split}` trước.")
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["run", "report", "tune"])
    parser.add_argument("--split", choices=list(SPLITS), required=True)
    parser.add_argument("--floor", default="0.00", help="mức sàn đồng thuận mỗi kênh (luật nghiên cứu = 0)")
    parser.add_argument("--limit", type=int, default=None, help="chỉ chạy N trang đầu (thử nhanh)")
    parser.add_argument("--tag", default="", help="hậu tố tên bộ nhớ đệm (so sánh trước/sau khi sửa)")
    parser.add_argument("--stt-check", action="store_true", help="bật lớp xác nhận STT khi ghép học sinh (RECOGNITION_STT_CHECK)")
    parser.add_argument("--struck-active", action="store_true", help="danh sách lớp CÓ học sinh ở dòng bị gạch (còn theo học); mặc định: không có (đã nghỉ)")
    parser.add_argument("--no-match", action="store_true", help="không chạy bộ ghép học sinh")
    args = parser.parse_args()
    if args.command == "tune" and args.split != "dev":
        raise SystemExit("Chỉ được dò tham số trên DEV.")
    if args.command == "run":
        run(args.split, args.limit, args.tag)
        return
    labels = load_labels(args.split)
    cache = load_cache(args.split, args.tag)
    matches = {} if args.no_match else match_pages(cache, labels, args.stt_check, args.struck_active)
    if matches and args.stt_check:
        models = [v.get("model") for v in matches.values() if v["ok"]]
        chosen = collections.Counter(
            "không có mô hình" if m is None else f"{m['convention']}{'+gạch' if m['strikeShift'] else ''} k={m['k']}" for m in models
        )
        print(f"Mô hình STT theo trang ({'gạch còn học' if args.struck_active else 'gạch đã nghỉ'}): {dict(chosen)}")
    if args.command == "report":
        floor = Decimal(args.floor)
        print(f"Tập {args.split.upper()} — mô hình {cache.get('modelVersion')}, {len(cache['pages'])} ảnh trang")
        print_report("Luật CŨ (trước BE-22)", evaluate(cache, labels, matches, "legacy", Decimal("0")))
        print_report(f"Luật hợp nhất của nghiên cứu (sàn {floor})", evaluate(cache, labels, matches, "research", floor))
        return
    # tune: lưới 0,00–0,95 bước 0,05; chọn 0 Xanh sai với ít Vàng nhất (hòa → sàn thấp hơn)
    rows = []
    for step in range(0, 20):
        floor = Decimal(step) * Decimal("0.05")
        c = collections.Counter(evaluate(cache, labels, matches, "research", floor)["groups"]["all"])
        rows.append((floor, c["green_wrong"], c["grade_VANG"], c["grade_XANH"], c["final_correct"]))
        print(f"sàn {floor}: Xanh sai {c['green_wrong']}, Vàng {c['grade_VANG']}, Xanh {c['grade_XANH']}, giá trị cuối đúng {c['final_correct']}")
    clean = [r for r in rows if r[1] == 0]
    best = min(clean, key=lambda r: (r[2], r[0])) if clean else min(rows, key=lambda r: (r[1], r[2], r[0]))
    print(f"CHỌN sàn = {best[0]} ({'0 Xanh sai' if clean else 'KHÔNG đạt 0 Xanh sai'}; Vàng {best[2]})")


if __name__ == "__main__":
    main()
