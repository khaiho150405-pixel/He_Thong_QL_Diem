"""Adapter VietOCR (vgg_seq2seq) đọc ô chữ: cột Điểm chữ và cột Họ tên.

Nguồn gốc: ``ket_hop/suy_luan_hai_mo_hinh.py`` (``nap_cau_hinh_vietocr``, ``chay_nhanh_chu``) và
``ket_hop/vietocr_vgg_seq2seq.yml`` (sao chép vào cùng thư mục: cấu hình, KHÔNG phải trọng số).

Cấu hình đúng như lúc fine-tune: ``image_height`` 32, ``image_min_width`` 32, ``image_max_width`` 384,
``beamsearch`` False, ``cnn.pretrained`` False.

An toàn:
- tuyệt đối không tải gì từ Internet: ``weights``/``pretrain`` trong tệp yml (URL của vocr.vn) bị ghi đè và có kiểm
  tra không còn URL nào trong cấu hình; ``cnn.pretrained`` luôn False;
- không dùng ``vietocr.tool.predictor.Predictor`` (nó nạp trọng số bằng ``torch.load`` mặc định và có đường tải URL):
  mô hình được dựng bằng ``build_model`` rồi nạp state dict bằng chế độ an toàn của torch (``weights_only=True``);
  không nạp được thì ``ModelUnavailableError``, không hạ sang chế độ pickle tùy ý;
- kiểm SHA-256 của tệp trọng số trước khi nạp.
vietocr==0.3.13 được cài ``--no-deps`` (xem pyproject); thiếu gói thì ``ModelUnavailableError``.
"""
from __future__ import annotations

import re
import unicodedata
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Sequence

import cv2
import numpy as np

from .crnn import sha256_of
from .errors import ModelUnavailableError

DEFAULT_CONFIG = Path(__file__).with_name("vietocr_vgg_seq2seq.yml")
IMAGE_HEIGHT, IMAGE_MIN_WIDTH, IMAGE_MAX_WIDTH = 32, 32, 384
_SHA256 = re.compile(r"^[0-9a-f]{64}$")


@dataclass(frozen=True, slots=True)
class TextRead:
    """Văn bản NFC đã bỏ khoảng trắng đầu/cuối và xác suất của chuỗi (0..1)."""

    text: str
    prob: float


def build_config(config_path: Path, weights_path: Path, device: str) -> dict[str, Any]:
    """Đọc yml, ghi đè theo ``nap_cau_hinh_vietocr`` và loại mọi URL tải mô hình."""
    import yaml

    with config_path.open(encoding="utf-8") as stream:
        cfg = yaml.safe_load(stream)
    cfg["dataset"].update(
        image_height=IMAGE_HEIGHT, image_min_width=IMAGE_MIN_WIDTH, image_max_width=IMAGE_MAX_WIDTH
    )
    cfg["predictor"]["beamsearch"] = False
    cfg["device"] = device
    cfg["cnn"]["pretrained"] = False
    cfg["weights"] = str(weights_path)
    cfg.pop("pretrain", None)
    leftover = [key for key, value in cfg.items() if key != "vocab" and "http" in str(value).lower()]
    if leftover:
        raise ModelUnavailableError("VietOCR config still references a remote URL")
    return cfg


def _vietocr():
    try:
        from vietocr.tool import translate
    except ImportError as error:
        raise ModelUnavailableError("vietocr is not installed") from error
    return translate


def _to_pil(image):
    from PIL import Image

    if image is None or getattr(image, "size", 0) == 0:
        image = np.full((IMAGE_HEIGHT, IMAGE_MIN_WIDTH, 3), 255, np.uint8)
    rgb = (
        cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        if image.ndim == 3
        else cv2.cvtColor(image, cv2.COLOR_GRAY2RGB)
    )
    return Image.fromarray(rgb)


class VietOcrReader:
    def __init__(self, translate: Any, model: Any, vocab: Any, config: dict[str, Any], sha256: str) -> None:
        self._translate = translate
        self._model = model
        self._vocab = vocab
        self._config = config
        self.sha256 = sha256

    @classmethod
    def load(
        cls,
        weights_path: str | Path,
        expected_sha256: str,
        device: str = "cpu",
        config_path: Path = DEFAULT_CONFIG,
    ) -> "VietOcrReader":
        expected = (expected_sha256 or "").strip().lower()
        if not _SHA256.match(expected):
            raise ModelUnavailableError("VietOCR expected SHA-256 is missing or malformed")
        weights = Path(weights_path)
        if weights.is_symlink() or not weights.is_file():
            raise ModelUnavailableError("VietOCR weights file is missing")
        if sha256_of(weights) != expected:
            raise ModelUnavailableError("VietOCR weights SHA-256 does not match")
        translate = _vietocr()
        import torch

        config = build_config(config_path, weights, device)
        try:
            state = torch.load(weights, map_location=torch.device(device), weights_only=True)
        except Exception as error:
            # Không hạ sang chế độ pickle tùy ý.
            raise ModelUnavailableError("VietOCR checkpoint cannot be loaded safely") from error
        try:
            model, vocab = translate.build_model(config)
        except Exception as error:
            raise ModelUnavailableError("VietOCR model cannot be built offline") from error
        try:
            model.load_state_dict(state)
        except Exception as error:
            raise ModelUnavailableError("VietOCR checkpoint does not match the architecture") from error
        model.eval()
        return cls(translate, model, vocab, config, expected)

    def read_cells(self, images: Sequence[Any]) -> list[TextRead]:
        """Đọc từng ô; các ô cùng bề rộng sau chuẩn hóa được gom lô (như ``predict_batch`` gốc)."""
        import torch

        dataset = self._config["dataset"]
        bucket: dict[int, list[Any]] = defaultdict(list)
        position: dict[int, list[int]] = defaultdict(list)
        for index, image in enumerate(images):
            tensor = self._translate.process_input(
                _to_pil(image),
                dataset["image_height"],
                dataset["image_min_width"],
                dataset["image_max_width"],
            )
            bucket[tensor.shape[-1]].append(tensor)
            position[tensor.shape[-1]].append(index)
        results: list[TextRead | None] = [None] * len(images)
        for width, tensors in bucket.items():
            batch = torch.cat(tensors, 0).to(self._config["device"])
            sequences, probs = self._translate.translate(batch, self._model)
            texts = self._vocab.batch_decode(sequences.tolist())
            for slot, text, prob in zip(position[width], texts, probs.tolist()):
                results[slot] = TextRead(unicodedata.normalize("NFC", text.strip()), float(prob))
        return [r for r in results if r is not None]
