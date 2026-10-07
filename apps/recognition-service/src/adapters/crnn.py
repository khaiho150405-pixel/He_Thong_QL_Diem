"""Adapter CRNN + CTC đọc ô chữ số viết tay (cột Đ.số và cột STT).

Nguồn gốc: ``ket_hop/suy_luan_hai_mo_hinh.py`` — class ``CRNN`` (kiến trúc sao chép nguyên vẹn từ ``train_crnn_num.py``),
``tien_xu_ly_anh`` (xám, chiều cao 32, rộng 128, đệm trắng ở giữa, chuẩn hóa (x/255-0.5)/0.5) và
``decode_ctc_voi_do_tin_cay`` (giải mã greedy; độ tin cậy ``conf_mean`` là trung bình xác suất các khung phát ký tự;
``conf_min`` và ``conf_path`` được giữ lại để hiệu chỉnh ngưỡng ở BE-22).

An toàn nạp mô hình:
- trước khi nạp luôn kiểm SHA-256 của tệp với giá trị kỳ vọng; sai hoặc thiếu → ``ModelUnavailableError``;
- nạp bằng chế độ an toàn của torch (``weights_only=True``); không nạp được thì ``ModelUnavailableError``, tuyệt đối
  không hạ sang chế độ pickle tùy ý;
- không tải gì từ Internet; torch được import khi nạp mô hình nên module này nhập được khi thiếu torch.
"""
from __future__ import annotations

import hashlib
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import cv2
import numpy as np

from .errors import ModelUnavailableError

CHARSET = ['.', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9']
BLANK_IDX = 0
IDX2CHAR = {i + 1: c for i, c in enumerate(CHARSET)}
NUM_CLASSES = len(CHARSET) + 1
IMG_H, IMG_W = 32, 128
MAX_STT = 500
_SHA256 = re.compile(r"^[0-9a-f]{64}$")
_STT_TEXT = re.compile(r"^[0-9]{1,3}$")


@dataclass(frozen=True, slots=True)
class CellRead:
    """Kết quả CTC greedy của một ô."""

    text: str
    conf_mean: float
    conf_min: float
    conf_path: float


@dataclass(frozen=True, slots=True)
class SttRead:
    """STT đọc từ ô chữ số: chỉ nhận số nguyên dương; ô không đọc được → ``value`` là ``None``."""

    raw: str
    value: int | None
    confidence: float


def _torch():
    try:
        import torch
    except ImportError as error:  # pragma: no cover - phụ thuộc môi trường
        raise ModelUnavailableError("torch is not installed") from error
    return torch


def _build_model(torch):
    nn = torch.nn

    class CRNN(nn.Module):
        def __init__(self, num_classes=NUM_CLASSES):
            super().__init__()
            self.conv = nn.Sequential(
                nn.Conv2d(1, 64, 3, padding=1), nn.BatchNorm2d(64), nn.ReLU(True),
                nn.MaxPool2d(2, 2),
                nn.Conv2d(64, 128, 3, padding=1), nn.BatchNorm2d(128), nn.ReLU(True),
                nn.MaxPool2d(2, 2),
                nn.Conv2d(128, 256, 3, padding=1), nn.BatchNorm2d(256), nn.ReLU(True),
                nn.Conv2d(256, 256, 3, padding=1), nn.BatchNorm2d(256), nn.ReLU(True),
                nn.MaxPool2d((2, 1), (2, 1)),
                nn.Conv2d(256, 512, 3, padding=1), nn.BatchNorm2d(512), nn.ReLU(True),
                nn.MaxPool2d((2, 1), (2, 1)),
                nn.Conv2d(512, 512, (2, 1), padding=0), nn.BatchNorm2d(512), nn.ReLU(True),
            )
            self.lstm1 = nn.LSTM(512, 128, bidirectional=True, batch_first=True)
            self.lstm2 = nn.LSTM(256, 128, bidirectional=True, batch_first=True)
            self.fc = nn.Linear(256, num_classes)

        def forward(self, x):
            f = self.conv(x)
            f = f.squeeze(2).permute(0, 2, 1)
            out, _ = self.lstm1(f)
            out, _ = self.lstm2(out)
            return self.fc(out)

    return CRNN()


def tien_xu_ly_anh(img) -> np.ndarray:
    """Ô ảnh (BGR hoặc xám, mảng NumPy) → mảng float32 [32, 128] đã chuẩn hóa. Giống hệt khi huấn luyện."""
    if img is None or getattr(img, "size", 0) == 0:
        img = np.ones((IMG_H, IMG_W), dtype=np.uint8) * 255
    elif img.ndim == 3:
        img = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    h, w = img.shape[:2]
    scale = IMG_H / max(h, 1)
    new_w = int(w * scale)
    if new_w > IMG_W:
        resized = cv2.resize(img, (IMG_W, IMG_H))
    else:
        resized = cv2.resize(img, (max(new_w, 1), IMG_H))
        pad = np.ones((IMG_H, IMG_W), dtype=np.uint8) * 255
        start_x = (IMG_W - resized.shape[1]) // 2
        pad[:, start_x : start_x + resized.shape[1]] = resized
        resized = pad
    return (resized.astype(np.float32) / 255.0 - 0.5) / 0.5


def decode_ctc(probs: np.ndarray) -> list[CellRead]:
    """Giải mã CTC greedy từ xác suất ``[B, T, C]``; độ tin cậy ở ba dạng (xem docstring module)."""
    pmax = probs.max(axis=-1)
    idx = probs.argmax(axis=-1)
    out: list[CellRead] = []
    for b in range(idx.shape[0]):
        chars: list[str] = []
        cps: list[float] = []
        prev = None
        for t, tok in enumerate(idx[b]):
            if tok != prev:
                if tok != BLANK_IDX:
                    chars.append(IDX2CHAR.get(int(tok), ""))
                    cps.append(float(pmax[b, t]))
                prev = tok
        conf_mean = float(np.mean(cps)) if cps else 0.0
        conf_min = float(np.min(cps)) if cps else 0.0
        conf_path = float(np.exp(np.mean(np.log(np.clip(pmax[b], 1e-12, 1.0)))))
        out.append(CellRead("".join(chars), conf_mean, conf_min, conf_path))
    return out


def sha256_of(path: Path) -> str:
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


class CrnnReader:
    """Đọc ô chữ số bằng CRNN đã nạp và kiểm hash."""

    def __init__(self, model: Any, device: str, sha256: str) -> None:
        self._model = model
        self._device = device
        self.sha256 = sha256

    @classmethod
    def load(cls, path: str | Path, expected_sha256: str, device: str = "cpu") -> "CrnnReader":
        expected = (expected_sha256 or "").strip().lower()
        if not _SHA256.match(expected):
            raise ModelUnavailableError("CRNN expected SHA-256 is missing or malformed")
        file = Path(path)
        if file.is_symlink() or not file.is_file():
            raise ModelUnavailableError("CRNN weights file is missing")
        if sha256_of(file) != expected:
            raise ModelUnavailableError("CRNN weights SHA-256 does not match")
        torch = _torch()
        try:
            checkpoint = torch.load(file, map_location=device, weights_only=True)
        except Exception as error:
            # Không hạ sang chế độ pickle tùy ý: tệp chứa đối tượng pickle bị từ chối.
            raise ModelUnavailableError("CRNN checkpoint cannot be loaded safely") from error
        state = checkpoint.get("model_state_dict") if isinstance(checkpoint, dict) else None
        if state is None and isinstance(checkpoint, dict):
            state = checkpoint
        model = _build_model(torch)
        try:
            model.load_state_dict(state)
        except Exception as error:
            raise ModelUnavailableError("CRNN checkpoint does not match the architecture") from error
        model.to(device).eval()
        return cls(model, device, expected)

    def read_cells(self, images: Sequence[Any], batch_size: int = 64) -> list[CellRead]:
        """Đọc theo lô; kết quả cùng thứ tự với ``images``."""
        torch = _torch()
        results: list[CellRead] = []
        for start in range(0, len(images), batch_size):
            batch = images[start : start + batch_size]
            tensor = torch.from_numpy(
                np.stack([tien_xu_ly_anh(image) for image in batch])
            ).unsqueeze(1).to(self._device)
            with torch.no_grad():
                probs = torch.softmax(self._model(tensor), dim=-1).cpu().numpy()
            results.extend(decode_ctc(probs))
        return results

    def read_stt(self, images: Sequence[Any], batch_size: int = 64) -> list[SttRead]:
        """Đọc ô STT: chỉ chấp nhận số nguyên 1..500 (không dấu chấm, không số 0 đầu quá dài)."""
        out: list[SttRead] = []
        for read in self.read_cells(images, batch_size):
            value: int | None = None
            if _STT_TEXT.match(read.text):
                number = int(read.text)
                if 1 <= number <= MAX_STT:
                    value = number
            out.append(SttRead(read.text, value, read.conf_mean if value is not None else 0.0))
        return out
