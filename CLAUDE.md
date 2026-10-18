@AGENTS.md

# Đợt hiện tại: Mẫu bảng điểm (ADR-0016)

Đợt này thêm tính năng "Mẫu bảng điểm" để nhận dạng được nhiều loại tờ, nhiều cột, nhiều trang. Công việc chia thành phase P1–P6 trong `automation/phases/`, và thường được chạy tự động bằng `automation/run.py`.

Trước khi làm, đọc theo thứ tự:

1. `AGENTS.md`: bất biến mục 7 luôn thắng mọi tài liệu khác.
2. `automation/decisions.md`: quyết định của chủ dự án cho đợt này.
3. `docs/adr/0016-form-templates.md`: thiết kế.
4. File phase đang làm, đặc biệt các mục "Phạm vi được sửa", "Không được đụng" và "Tiêu chí nghiệm thu".
5. Khi sửa Flutter: `docs/design/ui-rules.md`.

## Quy tắc chung

- Phase cho phép sửa backend, migration mới, dịch vụ Python, client sinh lại hoặc Flutter ở đâu thì chỉ sửa ở đó. Không sửa ngoài phạm vi phase.
- Không sửa migration đã có. Không sửa tay `packages/api_client_dart` (dùng `pnpm client:generate`).
- Không thêm dependency (npm, pub, pip) nếu phase không cho phép rõ ràng. Không cài gì lên ổ C.
- Không sửa thư mục `automation/` ngoài file báo cáo trong `automation/runs/`.
- Khi chạy qua `automation/run.py`: **không** `git commit` / `git push` / `git reset` / `git stash`. Script tự commit.
- Thiếu thông tin thì chọn phương án theo ADR-0016 và `decisions.md`, giữ hành vi cũ ở những chỗ không thuộc phase, rồi ghi giả định vào báo cáo. Không dừng lại để hỏi.

## Lệnh kiểm tra

- API/DB: `pnpm check`, `pnpm contracts:check`; `pnpm test:db` và `pnpm test:integration` khi đã cấu hình DB test (`TEST_RUNTIME_URL`).
- Dịch vụ nhận dạng: `.local/venv-ml/Scripts/python.exe -m unittest discover -s tests`, chạy trong `apps/recognition-service`.
- Flutter: `dart run melos run check`.
