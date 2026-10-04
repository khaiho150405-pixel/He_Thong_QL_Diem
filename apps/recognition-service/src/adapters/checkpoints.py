"""Offline checkpoint inventory. Never selects or activates a production model."""

import argparse
import hashlib
import json
import math
from collections.abc import Mapping
from pathlib import Path


def scalar(value: object, maximum: float) -> float | None:
    if isinstance(value, bool) or not isinstance(value, (float, int)):
        return None
    return float(value) if math.isfinite(value) and 0 <= value <= maximum else None


def metadata(checkpoint: object) -> dict:
    if not isinstance(checkpoint, Mapping):
        return {"status": "unsupported"}
    state = checkpoint.get("model_state_dict")
    if not isinstance(state, Mapping):
        return {"status": "state-only", "tensor_count": len(checkpoint)}
    charset = checkpoint.get("charset")
    return {
        "status": "metadata-present",
        "epoch": scalar(checkpoint.get("epoch"), 1_000_000),
        "reported_accuracy_percent": scalar(checkpoint.get("val_acc"), 100),
        "reported_cer": scalar(checkpoint.get("val_cer"), 1),
        "charset": charset if isinstance(charset, str) or (
            isinstance(charset, list) and all(isinstance(c, str) for c in charset)
        ) else None,
        "num_classes": scalar(checkpoint.get("num_classes"), 100_000),
        "tensor_count": len(state),
    }


def candidates(items: list[dict]) -> dict:
    # File timestamps only identify the newest local copy, not the best model.
    numeric = [r for r in items if r["file"].startswith("crnn_num")
               and r.get("reported_accuracy_percent") is not None]
    ranked = sorted(numeric, key=lambda r: (
        -r["reported_accuracy_percent"],
        r["reported_cer"] if r.get("reported_cer") is not None else math.inf,
        r["file"],
    ))
    readable = [r for r in items if r.get("status") != "unreadable"]
    newest = max(readable, key=lambda r: (r["modified_ns"], r["file"]), default=None)
    return {
        "newest_local_copy": newest["file"] if newest else None,
        "numeric_highest_reported_accuracy": ranked[0]["file"] if ranked else None,
        "ready_for_inference": False,
        "reason": "Training architecture, preprocessing, decoding, grid extraction and a shared validation set are not verified.",
    }


def inspect(folder: Path) -> dict:
    # Torch is an optional OFFLINE dependency, not added to the API runtime.
    import torch

    items = []
    for path in sorted(folder.glob("*.pth")):
        if path.is_symlink() or not path.is_file():
            continue
        stat = path.stat()
        row = {"file": path.name, "bytes": stat.st_size, "modified_ns": stat.st_mtime_ns}
        try:
            with path.open("rb") as stream:
                row["sha256"] = hashlib.file_digest(stream, "sha256").hexdigest()
            checkpoint = torch.load(path, map_location="cpu", weights_only=True)
            row.update(metadata(checkpoint))
            del checkpoint
        except Exception as error:
            # No unsafe pickle fallback, no paths/config secrets in the report.
            row.update(status="unreadable", error_type=type(error).__name__)
        items.append(row)
    return {"checkpoints": items, "candidates": candidates(items)}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("folder", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    if not args.folder.is_dir():
        parser.error("Checkpoint directory does not exist")
    report = inspect(args.folder)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report["candidates"], ensure_ascii=False))


if __name__ == "__main__":
    main()
