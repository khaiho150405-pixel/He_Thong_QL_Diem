#!/usr/bin/env python
"""Đánh giá cục bộ pipeline nhận dạng trên ảnh TRANG (BE-21/BE-22). Không chạy trong CI, không in họ tên.

Chạy pipeline + mô hình thật (như dịch vụ nhận dạng) trên từng ảnh trang, ghép kết quả với nhãn ô theo
(người, tờ, trang, stt) từ ``06_ANH_O_CAT/<valid|test>/manifest_*_{num,txt}.csv``, rồi tính độ chính xác từng kênh,
độ chính xác giá trị cuối, tỷ lệ Xanh/Vàng/Đỏ, số dòng Xanh sai (lỗi im lặng) và số dòng gán sai học sinh, tách phone/scan.

    python scripts/recognition/evaluate_pages.py run    --split dev|test      # chạy mô hình, lưu .local/eval/<split>.json
    python scripts/recognition/evaluate_pages.py report --split dev|test [--floor 0.0]
    python scripts/recognition/evaluate_pages.py tune   --split dev           # dò mức sàn đồng thuận (chỉ DEV)

Đường v2 theo mẫu (ADR-0016, phase P6):
    python scripts/recognition/evaluate_pages.py make-layout --split dev --out scripts/recognition/layouts/e0330113.json
    python scripts/recognition/evaluate_pages.py run     --split dev --layout scripts/recognition/layouts/e0330113.json   # → dev_v2.json
    python scripts/recognition/evaluate_pages.py compare --split dev                    # bảng v1 (dev.json) so với v2 (dev_v2.json)
    python scripts/recognition/evaluate_pages.py scores  --split dev --layout <layout> --others <thư mục ảnh mẫu khác>  # D-04
Tập TEST chỉ chạy MỘT lần (tệp đệm ghi ``completedAt``; chạy lại bị từ chối).

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

def _default_data_dir() -> str:
    """Thư mục dữ liệu: KLCN_DATA, rồi ``data_dir`` trong automation/config.json, rồi đường dẫn cũ."""
    if os.environ.get("KLCN_DATA"):
        return os.environ["KLCN_DATA"]
    config = ROOT / "automation" / "config.json"
    if config.is_file():
        try:
            value = json.loads(config.read_text(encoding="utf-8")).get("data_dir")
        except ValueError:
            value = None
        if value and Path(value).is_dir():
            return value
    return r"D:\HocTap\KhoaLuan\App\KLCN_2026"


def _default_weights_dir() -> str:
    """Thư mục trọng số: RECOGNITION_WEIGHTS_DIR, rồi ``.local/weights`` của repo, rồi đường dẫn cũ."""
    if os.environ.get("RECOGNITION_WEIGHTS_DIR"):
        return os.environ["RECOGNITION_WEIGHTS_DIR"]
    local = ROOT / ".local" / "weights"
    return str(local) if local.is_dir() else r"D:\HocTap\KhoaLuan\App\weights"


DATA = Path(_default_data_dir())
WEIGHTS = Path(_default_weights_dir())
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
    skipped: set[str] = set()
    for kind in ("num", "txt"):
        path = DATA / "06_ANH_O_CAT" / folder / f"{stem}_{kind}.csv"
        if not path.is_file():
            raise SystemExit(f"Thiếu nhãn: {path}")
        for row in csv.DictReader(path.open(encoding="utf-8-sig")):
            person = row["nguoi"]
            if person in TRAIN:
                raise SystemExit(f"Người {person} thuộc tập TRAIN: dừng.")
            if person not in people:
                # Người có trong manifest nhưng chưa được khai báo ở SPLITS (ví dụ T04 trong test/): bỏ qua, không đoán tập.
                skipped.add(person)
                continue
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
    if skipped:
        print(f"Bỏ qua người không khai báo trong tập {split}: {sorted(skipped)}", file=sys.stderr)
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


def eval_model():
    """Mô hình thật (trọng số) cấu hình như dịch vụ nhận dạng; chỉ dùng cho đánh giá cục bộ."""
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
    return configured_model(env), env


def load_layout(path: Path):
    """``layout`` của ``/v2/recognize`` từ tệp JSON (cùng bộ kiểm của dịch vụ)."""
    from src.domain.layout import parse_layout

    return parse_layout(Path(path).read_text(encoding="utf-8"))


def error_code(error: Exception) -> str:
    return type(error).__name__ + ":" + str(getattr(error, "code", ""))


def run(split: str, limit: int | None, tag: str = "", layout_path: Path | None = None, min_score: float | None = None) -> None:
    """Chạy mô hình trên từng ảnh trang và lưu bộ nhớ đệm. Có ``layout_path`` thì chạy đường v2 (``recognize_v2``), không thì
    đường v1 (``recognize``, tự chọn cột bằng hình học). Cả hai ghi cùng định dạng nên ``report`` dùng chung."""
    cache_path = CACHE_DIR / f"{split}{tag}.json"
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    cache = json.loads(cache_path.read_text(encoding="utf-8")) if cache_path.is_file() else {"pages": {}}
    if split == "test" and cache.get("completedAt"):
        # Tập TEST chỉ được chạy MỘT lần sau khi khóa cấu hình trên DEV (ADR-0016, phase P6): không cho chạy lại.
        raise SystemExit(f"TEST đã chạy xong lúc {cache['completedAt']} ({cache_path.name}); không chạy lại.")
    model, env = eval_model()
    layout = load_layout(layout_path) if layout_path else None
    if layout is not None:
        from src.pipeline.template_match import nguong_khop_mau

        threshold = nguong_khop_mau(env) if min_score is None else min_score
        grade_key = layout.grade_columns[0].key
        cache["layout"] = Path(layout_path).name
        cache["minScore"] = threshold
        cache["gradeKey"] = grade_key
        import src.pipeline.layout as rows_module  # cat_dong_theo_mau gọi compact_name_cell của mô-đun này
    else:
        import src.pipeline.rows as rows_module
    # Ghi nhận ô họ tên nào thực sự được thu khe (compact_name_cell trả ảnh khác ảnh vào), theo thứ tự dòng.
    collapsed: list[bool] = []
    original_compact = rows_module.compact_name_cell

    def recording_compact(cell):
        result = original_compact(cell)
        collapsed.append(cell is not None and result is not cell)
        return result

    rows_module.compact_name_cell = recording_compact
    labels = load_labels(split)
    cache.setdefault("startedAt", time.strftime("%Y-%m-%dT%H:%M:%S%z"))
    keys = page_keys(labels)[: limit or None]
    for index, key in enumerate(keys, 1):
        name = "|".join(key)
        if name in cache["pages"]:
            continue
        started = time.time()
        collapsed.clear()
        try:
            image = page_image(*key).read_bytes()
            if layout is None:
                result = model.recognize(image)
                template_score = None
            else:
                result = model.recognize_v2(image, layout, threshold)
                template_score = result.template_score
            # compact_name_cell chỉ được gọi cho dòng không bị gạch, theo thứ tự dòng.
            recorded = iter(collapsed)
            flags = [None if r.struck else next(recorded, None) for r in result.rows]
            rows = []
            for i, r in enumerate(result.rows):
                if layout is None:
                    numeric, written = r.numeric, r.written
                else:
                    grade = next(g for g in r.grades if g.key == grade_key)
                    numeric, written = grade.numeric, grade.written
                rows.append(
                    {
                        "index": r.row_index,
                        "struck": r.struck,
                        "numeric": channel_json(numeric),
                        "written": channel_json(written) if written is not None else {"value": None, "confidence": None, "blank": True},
                        "nameRaw": r.name.raw_output,
                        "nameBlank": r.name.is_blank,
                        "gapCollapsed": flags[i],
                        "stt": {"value": r.stt.value, "read": r.stt_read, "position": r.stt_from_position},
                    }
                )
            cache["modelVersion"] = result.model_version
            cache["pages"][name] = {"seconds": round(time.time() - started, 2), "rows": rows}
            if template_score is not None:
                cache["pages"][name]["templateScore"] = template_score
        except Exception as error:  # noqa: BLE001 - ghi mã lỗi ổn định, không in nội dung
            cache["pages"][name] = {"seconds": round(time.time() - started, 2), "error": error_code(error)}
            score = getattr(error, "details", {}).get("score")
            if score is not None:
                cache["pages"][name]["templateScore"] = score
        cache_path.write_text(json.dumps(cache), encoding="utf-8")
        print(f"[{index}/{len(keys)}] {key[0]} {key[1]} {key[2]} {key[3]}: {cache['pages'][name]['seconds']}s", flush=True)
    if limit is None and all("|".join(k) in cache["pages"] for k in keys):
        cache["completedAt"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
        cache_path.write_text(json.dumps(cache), encoding="utf-8")


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
        groups[source]["pages"] += 1
        if "error" in page:
            groups[source]["pages_error"] += 1
            groups[source]["pages_template_mismatch"] += page["error"].endswith(":TEMPLATE_MISMATCH")
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


def num(c: collections.Counter, a: str, b: str) -> float | None:
    return None if not c[b] else 100 * c[a] / c[b]


def regression_checks(a: collections.Counter, b: collections.Counter) -> dict[str, bool]:
    """Điều kiện AC-1 (v1 = ``a``, v2 = ``b``). Độ đúng chấm trên MỌI dòng có nhãn của cùng tập: dòng thuộc trang bị
    từ chối vẫn tính là chưa đọc đúng, nên không thể che sự thụt lùi bằng cách loại chúng khỏi mẫu số."""
    checks = {
        "gán sai học sinh = 0": b["match_wrong"] == 0,
        "Xanh sai = 0": b["green_wrong"] == 0 and b["final_green_wrong"] == 0,
    }
    for field, label in (("num_ok", "Đ.số"), ("txt_ok", "Điểm chữ")):
        v1, v2 = num(a, field, "labelled"), num(b, field, "labelled")
        if v1 is None or v2 is None:
            checks[f"độ đúng {label} trên mọi dòng có nhãn"] = False
            continue
        checks[f"độ đúng {label} trên mọi dòng có nhãn không thấp hơn v1 quá 0,5 điểm % (v1 {v1:.2f}, v2 {v2:.2f})"] = v2 >= v1 - 0.5
    return checks


def compare(split: str, tag_v2: str, floor: Decimal, struck_active: bool) -> bool:
    """Bảng so sánh đường v1 (hình học, không mẫu) với đường v2 (mẫu) trên cùng một tập; in Markdown. ``True`` khi đạt AC-1."""
    labels = load_labels(split)
    groups = {}
    for name, tag in (("v1", ""), ("v2", tag_v2)):
        cache = load_cache(split, tag)
        matches = match_pages(cache, labels, True, struck_active)
        groups[name] = evaluate(cache, labels, matches, "research", floor)["groups"]
        groups[name]["modelVersion"] = cache.get("modelVersion")
        groups[name]["layout"] = cache.get("layout")
        groups[name]["minScore"] = cache.get("minScore")
    print(f"Tập {split.upper()} — mô hình {groups['v1']['modelVersion']}; v2 dùng layout {groups['v2']['layout']}, ngưỡng khớp mẫu {groups['v2']['minScore']}")
    verdict = True
    for source in ("all", "phone", "scan"):
        a, b = collections.Counter(groups["v1"][source]), collections.Counter(groups["v2"][source])
        rows = [
            ("Dòng có nhãn", a["labelled"], b["labelled"]),
            ("Dòng đọc được", a["read"], b["read"]),
            ("Đ.số đúng (trên dòng đọc được)", pct(a["num_ok"], a["read"]), pct(b["num_ok"], b["read"])),
            ("Điểm chữ đúng (trên dòng đọc được)", pct(a["txt_ok"], a["read"]), pct(b["txt_ok"], b["read"])),
            ("Đ.số đúng (trên mọi dòng có nhãn)", pct(a["num_ok"], a["labelled"]), pct(b["num_ok"], b["labelled"])),
            ("Điểm chữ đúng (trên mọi dòng có nhãn)", pct(a["txt_ok"], a["labelled"]), pct(b["txt_ok"], b["labelled"])),
            ("Xanh / Vàng / Đỏ (theo điểm)", *(f"{c['grade_XANH']} / {c['grade_VANG']} / {c['grade_DO']}" for c in (a, b))),
            ("Xanh / Vàng / Đỏ (mức cuối, sau ghép học sinh)", *(f"{c['final_XANH']} / {c['final_VANG']} / {c['final_DO']}" for c in (a, b))),
            ("Xanh sai (theo điểm)", a["green_wrong"], b["green_wrong"]),
            ("Xanh cuối sai (kể cả gán sai học sinh)", a["final_green_wrong"], b["final_green_wrong"]),
            ("Gán sai học sinh", f"{a['match_wrong']} / {a['match_eval']}", f"{b['match_wrong']} / {b['match_eval']}"),
            ("Trang TEMPLATE_MISMATCH", f"{a['pages_template_mismatch']} / {a['pages']}", f"{b['pages_template_mismatch']} / {b['pages']}"),
            ("Trang lỗi khác", a["pages_error"] - a["pages_template_mismatch"], b["pages_error"] - b["pages_template_mismatch"]),
        ]
        print(f"\n### Nhóm `{source}`\n\n| Chỉ số | v1 (hình học) | v2 (mẫu) |\n| --- | --- | --- |")
        for label, left, right in rows:
            print(f"| {label} | {left} | {right} |")
        if source != "all":
            continue
        checks = regression_checks(a, b)
        print()
        for label, ok in checks.items():
            print(f"- {'ĐẠT' if ok else 'KHÔNG ĐẠT'}: {label}")
        verdict = all(checks.values())
    print(f"\nAC-1 ({split.upper()}): {'ĐẠT' if verdict else 'KHÔNG ĐẠT'}")
    return verdict


# ───────────────────────────── chữ ký lưới, điểm khớp mẫu (D-04) ─────────────────────────────
SIGNATURE_CACHE = CACHE_DIR / "signatures.json"
E0330113_COLUMNS = [  # 9 cột dữ liệu: STT | Mã SV | Họ tên | Ngày sinh | Tên lớp | Đ.số | Điểm chữ | Ký tên | Ghi chú
    {"index": 0, "role": "STT"},
    {"index": 2, "role": "HO_TEN"},
    {"index": 5, "role": "DIEM", "key": "CK1", "writtenIndex": 6},
    {"index": 6, "role": "DIEM_CHU"},
]


def sig_key(path: Path) -> str:
    """Khóa bộ nhớ đệm chữ ký: đường dẫn tương đối với thư mục dữ liệu, hoặc đường dẫn tuyệt đối nếu ảnh nằm ngoài."""
    resolved = path.resolve()
    try:
        return resolved.relative_to(DATA.resolve()).as_posix()
    except ValueError:
        return resolved.as_posix()


def image_signatures(paths: list[Path]) -> dict[str, dict]:
    """Chữ ký lưới (đọc cả tiêu đề cột bằng mô hình họ tên, như ``/v2/layout/analyze``) của từng ảnh; có bộ nhớ đệm."""
    from src.pipeline.layout import phan_tich_bo_cuc

    cache = json.loads(SIGNATURE_CACHE.read_text(encoding="utf-8")) if SIGNATURE_CACHE.is_file() else {}
    model = None
    for path in paths:
        key = sig_key(path)
        if key in cache:
            continue
        if model is None:
            model, _ = eval_model()
        try:
            cache[key] = {"signature": phan_tich_bo_cuc(path.read_bytes(), model.ocr_ham).signature}
        except Exception as error:  # noqa: BLE001
            cache[key] = {"error": error_code(error)}
        SIGNATURE_CACHE.parent.mkdir(parents=True, exist_ok=True)
        SIGNATURE_CACHE.write_text(json.dumps(cache), encoding="utf-8")
    return {sig_key(path): cache[sig_key(path)] for path in paths}


def dev_page_paths() -> list[Path]:
    return [page_image(*key) for key in page_keys(load_labels("dev"))]


def make_layout(out: Path) -> None:
    """Sinh layout của mẫu E0330113 từ chữ ký các trang DEV: trung vị bề rộng từng cột, chữ tiêu đề phổ biến nhất."""
    entries = image_signatures(dev_page_paths())
    signatures = [e["signature"] for e in entries.values() if "signature" in e]
    count = collections.Counter(len(s["columnWidths"]) for s in signatures)
    columns = count.most_common(1)[0][0]
    same = [s for s in signatures if len(s["columnWidths"]) == columns]
    print(f"{len(signatures)}/{len(entries)} trang phân tích được; {len(same)} trang có {columns} cột (số cột: {dict(count)})")
    if columns != 9:
        raise SystemExit("Mẫu E0330113 phải có 9 cột dữ liệu.")
    widths = [round(statistics.median(s["columnWidths"][i] for s in same), 4) for i in range(columns)]
    texts = [collections.Counter(s["headerTexts"][i] for s in same).most_common(1)[0][0] for i in range(columns)]
    signature = {
        "version": 1,
        "columnWidths": widths,
        "headerTexts": texts,
        "headerRows": collections.Counter(s["headerRows"] for s in same).most_common(1)[0][0],
        "rowHeightMm": round(statistics.median(s["rowHeightMm"] for s in same), 4),
        "tableWidthMm": round(statistics.median(s["tableWidthMm"] for s in same), 4),
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"signature": signature, "columns": E0330113_COLUMNS}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Đã ghi {out}")


THAYHA_COLUMNS = [  # 14 cột: STT|Mã SV|Họ tên|Ng.sinh|Lớp|ĐQT×6|ĐTK|Điểm chữ|Chữ ký; đọc TX1, TX2 (một kênh) và ĐTK + Điểm chữ
    {"index": 0, "role": "STT"},
    {"index": 2, "role": "HO_TEN"},
    {"index": 5, "role": "DIEM", "key": "TX1"},
    {"index": 6, "role": "DIEM", "key": "TX2"},
    {"index": 11, "role": "DIEM", "key": "DTK", "writtenIndex": 12},
    {"index": 12, "role": "DIEM_CHU"},
]


def make_second_layout(out: Path, directory: Path, columns: int = 14) -> None:
    """Layout của mẫu thứ hai (tờ "Điểm quá trình/ĐTK" trong Data_thayHa, 14 cột) từ các ảnh có đúng ``columns`` cột trong
    thư mục (ảnh không nhãn, nhận theo số cột và chữ in "điểm quá trình" — không dùng điểm khớp)."""
    entries = image_signatures(image_files(directory))
    same = [
        e["signature"] for e in entries.values()
        if len(e.get("signature", {}).get("columnWidths", [])) == columns and "diemquatrinh" in e["signature"]["headerTexts"]
    ]
    if not same:
        raise SystemExit("Không có ảnh nào đúng mẫu thứ hai.")
    print(f"{len(same)}/{len(entries)} ảnh có {columns} cột")
    signature = {
        "version": 1,
        "columnWidths": [round(statistics.median(s["columnWidths"][i] for s in same), 4) for i in range(columns)],
        "headerTexts": [collections.Counter(s["headerTexts"][i] for s in same).most_common(1)[0][0] for i in range(columns)],
        "headerRows": collections.Counter(s["headerRows"] for s in same).most_common(1)[0][0],
        "rowHeightMm": round(statistics.median(s["rowHeightMm"] for s in same), 4),
        "tableWidthMm": round(statistics.median(s["tableWidthMm"] for s in same), 4),
    }
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps({"signature": signature, "columns": THAYHA_COLUMNS}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Đã ghi {out}")


def qualitative(layout_path: Path, images: list[Path], min_score: float | None) -> None:
    """Chạy đường v2 trên ảnh KHÔNG NHÃN và in số liệu định tính (không in họ tên, không in giá trị điểm)."""
    from src.pipeline.template_match import nguong_khop_mau

    model, env = eval_model()
    layout = load_layout(layout_path)
    threshold = nguong_khop_mau(env) if min_score is None else min_score
    print(f"layout {layout_path.name}, ngưỡng khớp mẫu {threshold}")
    for path in images:
        label = path.name if len(path.name) <= 24 else path.name[:10] + "…" + path.name[-8:]
        started = time.time()
        try:
            result = model.recognize_v2(path.read_bytes(), layout, threshold)
        except Exception as error:  # noqa: BLE001
            details = getattr(error, "details", {})
            print(f"- {label}: LỖI {error_code(error)}" + (f" (điểm {details['score']}, cột không ánh xạ {details.get('unmappedColumns')}, cột ảnh {details.get('imageColumns')}/mẫu {details.get('templateColumns')})" if "score" in details else ""))
            continue
        rows = result.rows
        struck = sum(r.struck for r in rows)
        parts = []
        for column in layout.grade_columns:
            grades = [next(g for g in r.grades if g.key == column.key) for r in rows if not r.struck]
            blank = sum(g.numeric.is_blank for g in grades)
            read = sum(g.numeric.value is not None for g in grades)
            parts.append(f"{column.key}: đọc được {read}, trống {blank}, có mực nhưng không đọc được {len(grades) - read - blank}")
        print(f"- {label}: điểm khớp {result.template_score}, {len(rows)} dòng (gạch bỏ {struck}), {time.time() - started:.1f}s | " + "; ".join(parts))


def image_files(directory: Path) -> list[Path]:
    return sorted(p for p in directory.rglob("*") if p.suffix.lower() in {".jpg", ".jpeg", ".png"})


def histogram(values: list[float], low: float = 0.0, high: float = 1.0, step: float = 0.05) -> str:
    bins = int(round((high - low) / step))
    counts = [0] * bins
    for v in values:
        counts[min(bins - 1, max(0, int((v - low) / step)))] += 1
    return "\n".join(
        f"    {low + i * step:.2f}–{low + (i + 1) * step:.2f} | {'#' * c} {c}" for i, c in enumerate(counts) if c
    )


def template_scores(layout_path: Path, others: list[Path], other_files: list[Path], same_sheet: list[Path]) -> None:
    """Phân bố điểm khớp mẫu của ảnh ĐÚNG mẫu (các trang DEV) so với ảnh MẪU KHÁC, và quét ngưỡng (D-04). Chỉ DEV."""
    from src.pipeline.layout import cot_can_doc
    from src.pipeline.template_match import DEFAULT_MIN_SCORE, khop_mau

    layout = load_layout(layout_path)
    needed = cot_can_doc(layout)
    groups: dict[str, list[Path]] = {"dev": dev_page_paths()}
    candidates = [p for d in others for p in image_files(d)] + other_files
    groups["other"] = []
    groups["same_sheet_info"] = [p for d in same_sheet for p in image_files(d)]
    # Nhãn "mẫu khác" theo CHỮ IN trên tờ (tiêu đề Đ.số + Điểm chữ = tờ E0330113), KHÔNG theo điểm khớp (tránh vòng tròn):
    # một thư mục như Data_thayHa trộn cả hai loại tờ.
    for path, entry in image_signatures(candidates).items():
        texts = entry.get("signature", {}).get("headerTexts", [])
        printed_like_template = "dso" in texts and "diemchu" in texts
        target = "same_sheet_info" if printed_like_template else "other"
        groups[target].append(next(p for p in candidates if sig_key(p) == path))
    if not groups["same_sheet_info"]:
        del groups["same_sheet_info"]
    results: dict[str, list[tuple[float, bool]]] = {}  # (điểm khớp, đủ cột cần đọc được ánh xạ 1–1)
    for name, paths in groups.items():
        entries = image_signatures(paths)
        found, failed = [], collections.Counter()
        for entry in entries.values():
            if "signature" not in entry:
                failed[entry["error"]] += 1
                continue
            score, column_map = khop_mau(entry["signature"], layout.signature)
            found.append((score, all(i in column_map for i in needed)))
        results[name] = found
        raw = [score for score, _ in found]
        title = {"dev": "Ảnh ĐÚNG mẫu (các trang DEV)", "other": "Ảnh MẪU KHÁC", "same_sheet_info": "Ảnh ngoài DEV có chữ in giống tờ E0330113 (chỉ tham khảo, KHÔNG dùng chọn ngưỡng)"}[name]
        print(f"\n{title}: {len(paths)} ảnh, phân tích được {len(raw)}, lỗi pipeline {dict(failed) or 0}, không ánh xạ đủ cột cần đọc {sum(not ok for _, ok in found)}")
        if raw:
            print(f"  điểm: nhỏ nhất {min(raw):.4f}, trung vị {statistics.median(raw):.4f}, lớn nhất {max(raw):.4f}")
            print(histogram(raw))
    pos, neg = results["dev"], results["other"]
    print("\nQuét ngưỡng (TEMPLATE_MISMATCH khi điểm < ngưỡng HOẶC có cột cần đọc không ánh xạ được).")
    print("Từ chối nhầm = ảnh đúng mẫu bị từ chối; nhận nhầm = ảnh mẫu khác được nhận; 'chỉ theo điểm' bỏ qua luật cột không ánh xạ:")
    for step in range(50, 100, 5):
        t = step / 100
        print(
            f"  ngưỡng {t:.2f}: từ chối nhầm {sum(s < t or not ok for s, ok in pos)}/{len(pos)} "
            f"(chỉ theo điểm {sum(s < t for s, _ in pos)}), nhận nhầm {sum(s >= t and ok for s, ok in neg)}/{len(neg)} "
            f"(chỉ theo điểm {sum(s >= t for s, _ in neg)})"
        )
    mapped_pos = [s for s, ok in pos if ok]
    if mapped_pos and neg:
        low, high = max(s for s, _ in neg), min(mapped_pos)
        print(f"\nĐiểm cao nhất của ảnh mẫu khác = {low:.4f}; điểm thấp nhất của ảnh đúng mẫu đã ánh xạ đủ cột = {high:.4f}")
        if low < high:
            print(f"Chỉ riêng điểm đã tách được hai nhóm với ngưỡng trong ({low:.4f}, {high:.4f}]; điểm giữa = {(low + high) / 2:.4f}; mặc định hiện tại {DEFAULT_MIN_SCORE} {'nằm trong' if low < DEFAULT_MIN_SCORE <= high else 'NẰM NGOÀI'} khoảng đó")
        else:
            print("Điểm KHÔNG tách được hoàn toàn hai nhóm.")


def main() -> None:
    sys.stdout.reconfigure(encoding="utf-8")  # console Windows mặc định cp1252, không in được tiếng Việt
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("command", choices=["run", "report", "tune", "compare", "scores", "make-layout", "make-second-layout", "qualitative"])
    parser.add_argument("--split", choices=list(SPLITS), default=None, help="bắt buộc, trừ make-second-layout và qualitative (ảnh không nhãn)")
    parser.add_argument("--images", type=Path, nargs="*", default=[], help="qualitative: ảnh không nhãn; make-second-layout: thư mục ảnh của mẫu thứ hai")
    parser.add_argument("--floor", default="0.00", help="mức sàn đồng thuận mỗi kênh (luật nghiên cứu = 0)")
    parser.add_argument("--limit", type=int, default=None, help="chỉ chạy N trang đầu (thử nhanh)")
    parser.add_argument("--tag", default="", help="hậu tố tên bộ nhớ đệm (so sánh trước/sau khi sửa)")
    parser.add_argument("--stt-check", action="store_true", help="bật lớp xác nhận STT khi ghép học sinh (RECOGNITION_STT_CHECK)")
    parser.add_argument("--struck-active", action="store_true", help="danh sách lớp CÓ học sinh ở dòng bị gạch (còn theo học); mặc định: không có (đã nghỉ)")
    parser.add_argument("--no-match", action="store_true", help="không chạy bộ ghép học sinh")
    parser.add_argument("--layout", type=Path, default=None, help="run: chạy đường v2 với layout (JSON của /v2/recognize); mặc định tag bộ nhớ đệm là _v2; scores: layout để chấm điểm khớp mẫu")
    parser.add_argument("--min-score", type=float, default=None, help="run --layout: ngưỡng khớp mẫu (mặc định RECOGNITION_TEMPLATE_MIN_SCORE hoặc 0,80)")
    parser.add_argument("--v2-tag", default="_v2", help="compare: hậu tố bộ nhớ đệm của đường v2")
    parser.add_argument("--out", type=Path, default=None, help="make-layout: tệp layout đầu ra")
    parser.add_argument("--others", type=Path, nargs="*", default=[], help="scores: thư mục ảnh của MẪU KHÁC")
    parser.add_argument("--others-file", type=Path, nargs="*", default=[], help="scores: tệp ảnh riêng của mẫu khác")
    parser.add_argument("--same-sheet", type=Path, nargs="*", default=[], help="scores: thư mục ảnh cùng loại tờ, chỉ in để tham khảo")
    args = parser.parse_args()
    if args.command == "qualitative":
        if args.layout is None or not args.images:
            raise SystemExit("qualitative cần --layout và --images.")
        qualitative(args.layout, args.images, args.min_score)
        return
    if args.command == "make-second-layout":
        if args.out is None or len(args.images) != 1:
            raise SystemExit("make-second-layout cần --out và --images <thư mục>.")
        make_second_layout(args.out, args.images[0])
        return
    if args.split is None:
        raise SystemExit("Thiếu --split.")
    if args.command in ("tune", "scores", "make-layout") and args.split != "dev":
        raise SystemExit("Chỉ được dò tham số trên DEV.")
    if args.command == "make-layout":
        if args.out is None:
            raise SystemExit("make-layout cần --out.")
        make_layout(args.out)
        return
    if args.command == "scores":
        if args.layout is None:
            raise SystemExit("scores cần --layout.")
        template_scores(args.layout, args.others, args.others_file, args.same_sheet)
        return
    if args.command == "compare":
        sys.exit(0 if compare(args.split, args.v2_tag, Decimal(args.floor), args.struck_active) else 1)
    if args.command == "run":
        run(args.split, args.limit, args.tag or ("_v2" if args.layout else ""), args.layout, args.min_score)
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
