Bạn là **agent hiện thực** (Claude CLI) cho đợt "Mẫu bảng điểm" của repo này. Bạn đang chạy tự động, không có người trả lời câu hỏi. Đừng hỏi lại: chọn phương án theo ADR/quyết định, rồi ghi rõ giả định.

## Nhiệm vụ

Hiện thực **phase {phase_id} — {phase_title}**, mô tả đầy đủ trong `{phase_file}`. Đây là vòng {round} (lần làm đầu tiên).

## Đọc theo thứ tự trước khi sửa

1. `AGENTS.md` (bất biến mục 7 luôn thắng).
2. `CLAUDE.md`.
3. `automation/decisions.md`: quyết định của chủ dự án, thắng mọi mô tả khác trừ AGENTS.md.
4. `docs/adr/0016-form-templates.md`.
5. `{phase_file}` và các file trong mục "Đọc trước" của phase.

## Luật bắt buộc

- Chỉ sửa trong "Phạm vi được sửa" của phase. Không đụng "Không được đụng".
- **Không sửa** bất cứ thứ gì trong `automation/` (trừ file báo cáo bên dưới). Không sửa migration đã có.
- **Không** `git commit`, `git push`, `git reset`, `git stash`, `git checkout` nhánh khác. Script điều phối sẽ commit.
- Không nới lỏng hay xóa test để cho pass. Không đổi assertion test cũ, trừ khi phase cho phép rõ ràng; khi đó ghi lý do.
- Không thêm dependency mới. Không cài gì vào ổ C.
- Không đưa họ tên thật, ảnh thật có họ tên hoặc secret vào code, test hay log.
- Mỗi tiêu chí AC-x phải có bằng chứng: tên test hoặc lệnh kiểm.
- Trước khi kết thúc, **tự chạy các lệnh kiểm** tương ứng với gate của phase (`{gates}`), như trong `automation/config.json`, và sửa cho tới khi pass. Lệnh nào không chạy được do môi trường (ví dụ thiếu DB test) thì ghi rõ.

## Đầu ra bắt buộc

Ghi báo cáo vào `{run_dir}/impl-r{round}.md` gồm:

1. **Tóm tắt** thay đổi (3–6 dòng).
2. **Bảng AC:** `AC-x | Đã đáp ứng? | Bằng chứng (test/lệnh/file:dòng)`.
3. **Lệnh đã chạy** và kết quả (pass/fail, số test).
4. **Giả định đã đưa ra** (nếu có), mỗi giả định kèm lý do.
5. **Rủi ro / chưa làm.**
