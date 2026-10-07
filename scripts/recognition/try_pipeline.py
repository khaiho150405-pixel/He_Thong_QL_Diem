"""Thử pipeline ảnh trên ảnh bảng điểm thật (CHỈ chạy cục bộ, không chạy trong CI).

Dùng:
    py -3.12 scripts/recognition/try_pipeline.py <tệp hoặc thư mục ảnh> [...] [--reference-root DIR] [--limit N]

Với mỗi ảnh in một dòng tóm tắt (``--quiet`` bỏ qua, chỉ in bảng tổng hợp theo trang/nguồn): số dòng dò được, vai trò các cột, số dòng gạch/dòng có điểm, thời gian, mã lỗi nếu
có. KHÔNG in họ tên, không ghi ảnh/kết quả ra đĩa; ảnh thật chứa dữ liệu cá nhân nên không được đưa vào repo, log
hay fixture. ``--reference-root`` trỏ tới thư mục chứa tệp JSON kết quả của dự án huấn luyện (cùng tên ảnh, trường
``so_dong``) để so số dòng.

Chưa có OCR chữ in nên tiêu đề cột không đọc được: cột điểm được chọn bằng đường lui hình học (gắn nhãn "đoán").
"""
from __future__ import annotations

import argparse
import json
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "apps" / "recognition-service"))

from src.pipeline.errors import PipelineError  # noqa: E402
from src.pipeline.rows import NGUONG_TRONG, analyze_page  # noqa: E402

IMAGE_SUFFIXES = {".jpg", ".jpeg", ".png"}


def collect(paths: list[str]) -> list[Path]:
    found: list[Path] = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            found += sorted(
                p
                for p in path.rglob("*")
                if p.suffix.lower() in IMAGE_SUFFIXES and "_kiemtra" not in p.stem
            )
        elif path.suffix.lower() in IMAGE_SUFFIXES:
            found.append(path)
    return found


def reference(image: Path, root: Path | None) -> tuple[int, list[bool]] | None:
    """(số dòng, [dòng i có mực?]) trong JSON tham chiếu.

    Tham chiếu không đánh dấu dòng gạch/trống (``trong`` luôn false) nên "có mực" suy từ tỉ lệ mực của ô điểm số hoặc
    điểm chữ (``muc_num``/``muc_txt`` >= ngưỡng ô trống), cùng hàm đo mực với pipeline.
    """
    if root is None:
        return None
    for candidate in root.rglob(f"{image.stem}.json"):
        try:
            data = json.loads(candidate.read_text(encoding="utf-8"))
            inked = [
                max(r.get("muc_num") or 0.0, r.get("muc_txt") or 0.0) >= NGUONG_TRONG
                for r in data["dong"]
            ]
            return int(data["so_dong"]), inked
        except (OSError, ValueError, KeyError):
            return None
    return None


def group(image: Path) -> str:
    """Nhóm báo cáo: trang (p1/p2) và nguồn (phone/scan), suy từ tên tệp P01_S01_p2_scan."""
    stem = image.stem.lower()
    page = "p2" if "_p2_" in stem else "p1" if "_p1_" in stem else "p?"
    source = "scan" if stem.endswith("scan") else "phone" if stem.endswith("phone") else "?"
    return f"{page}/{source}"


def classify(rows, expected: tuple[int, list[bool]]) -> str:
    """Kết luận so với tham chiếu theo số dòng CÓ ĐIỂM; dòng trống thừa được chấp nhận.

    Dòng bị pipeline xác định là gạch bỏ không tính vào "có điểm" ở cả hai phía: tham chiếu đo mực cả nét gạch nên
    hai phía không so được ở dòng đó. Có thể so từng vị trí khi số dòng bằng nhau; khác thì chỉ so tổng.
    """
    ref_rows, ref_inked = expected
    ours = [max(r.score_ink, r.written_ink) >= NGUONG_TRONG and not r.struck for r in rows]
    if len(rows) == ref_rows:
        keep = [not r.struck for r in rows]
        missing = sum(1 for o, t, k in zip(ours, ref_inked, keep) if k and t and not o)
        extra = sum(1 for o, t, k in zip(ours, ref_inked, keep) if k and o and not t)
        if missing:
            return "THIEU_DONG_CO_DIEM"
        return "THUA_DONG_CO_DIEM" if extra else "DUNG"
    graded = sum(ours)
    ref_graded = sum(ref_inked)
    if graded < ref_graded:
        return "THIEU_DONG_CO_DIEM"
    if graded > ref_graded:
        return "THUA_DONG_CO_DIEM"
    return "DUNG_THUA_DONG_TRONG" if len(rows) > ref_rows else "DUNG_THIEU_DONG_TRONG"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("paths", nargs="+")
    parser.add_argument("--reference-root", type=Path, default=None)
    parser.add_argument("--limit", type=int, default=0)
    parser.add_argument("--quiet", action="store_true", help="chỉ in bảng tổng hợp")
    args = parser.parse_args()

    images = collect(args.paths)
    if args.limit:
        images = images[: args.limit]
    if not images:
        print("Không tìm thấy ảnh.")
        return 2

    tally: dict[tuple[str, str], int] = {}
    ok = 0
    for image in images:
        started = time.time()
        expected = reference(image, args.reference_root)
        verdict = None
        try:
            analysis = analyze_page(image.read_bytes(), None)
        except PipelineError as error:
            verdict = error.code
            line = f"{image.stem}: LỖI {error.code} · {time.time() - started:.1f}s"
            if expected is not None:
                line += f" · tham chiếu {expected[0]} dòng/{sum(expected[1])} có mực"
        else:
            ok += 1
            roles = ",".join(c["vai_tro"] or "?" for c in analysis.columns["cot"])
            rows = analysis.rows
            graded = sum(r.has_grade_ink for r in rows)
            line = (
                f"{image.stem}: {len(rows)} dòng · cột điểm #{analysis.selection['cot_diem_chinh']['chi_so']}"
                f"{' (đoán)' if analysis.guessed_columns else ''} · vai trò [{roles}]"
                f" · gạch {sum(r.struck for r in rows)} · có điểm {graded}"
                f" · có tên {sum(r.has_name_ink for r in rows)} · {time.time() - started:.1f}s"
            )
            if expected is not None:
                verdict = classify(rows, expected)
                line += f" · tham chiếu {expected[0]} dòng/{sum(expected[1])} có mực → {verdict}"
        if verdict is not None:
            key = (group(image), verdict)
            tally[key] = tally.get(key, 0) + 1
        if not args.quiet:
            print(line)

    print(f"\nTổng: {len(images)} ảnh, xử lý được {ok}")
    if tally:
        print("\nBáo cáo theo nhóm (trang/nguồn):")
        for grp in sorted({g for g, _ in tally}):
            parts = {v: n for (g, v), n in tally.items() if g == grp}
            total = sum(parts.values())
            good = sum(n for v, n in parts.items() if v.startswith("DUNG"))
            detail = ", ".join(f"{v}={n}" for v, n in sorted(parts.items()))
            print(f"  {grp}: đạt (đúng số dòng có điểm) {good}/{total} · {detail}")
        total = sum(tally.values())
        good = sum(n for (g, v), n in tally.items() if v.startswith("DUNG"))
        missing = sum(n for (g, v), n in tally.items() if v == "THIEU_DONG_CO_DIEM")
        print(f"\nTổng: đúng số dòng có điểm {good}/{total} ({good / total:.0%}); thiếu dòng có điểm: {missing}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
