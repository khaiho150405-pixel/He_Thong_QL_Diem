# Tự động hóa đợt "Mẫu bảng điểm"

Script `run.py` chạy lần lượt các phase P1 → P6. Mỗi phase lặp theo vòng:

```
Claude CLI làm phase ─► script chạy gate (lint/test) ─► Codex/Gemini review ─► PASS → commit, sang phase sau
        ▲                     │ fail                            │ FAIL
        └──── Claude sửa ◄────┴─────────────────────────────────┘   (tối đa 3 lượt review, 5 vòng / phase)
```

Bạn chỉ cần chạy một lệnh. Script dừng ở một trong ba tình huống: xong hết; một phase **BLOCKED** (cần bạn quyết); hoặc agent lỗi (hết hạn mức hay hết giờ).

## Cấu trúc thư mục

| File                                      | Vai trò                                                                |
| ----------------------------------------- | ---------------------------------------------------------------------- |
| `run.py`                                  | Script điều phối. Chỉ dùng thư viện chuẩn Python                       |
| `config.json`                             | Lệnh gọi Claude/Codex/Gemini, các gate, giới hạn vòng, timeout         |
| `phases/P1.md … P6.md`                    | Đề bài từng phase: phạm vi, việc cần làm, **tiêu chí nghiệm thu (AC)** |
| `prompts/implement.md, fix.md, review.md` | Khuôn prompt cho từng vai                                              |
| `schemas/*.json`                          | Khung JSON bắt buộc cho kết quả review và phản hồi sửa                 |
| `decisions.md`                            | **Quyết định của bạn.** Đưa vào mọi prompt                             |
| `runs/` (git ignore)                      | Log, prompt đã điền, kết quả review, `SUMMARY.md`, `state.json`        |

## A. Chuẩn bị một lần

### 1. Git

Mở PowerShell tại `F:\HK1_Nam04\KLCN\He_Thong_QL_Diem`:

```powershell
git status                                   # còn thay đổi thì commit trước
git add -A
git commit -m "chore: luu thay doi truoc dot mau bang diem"
git switch -c feat/form-templates            # nhánh riêng cho đợt này
```

Thư mục `automation/`, `CLAUDE.md`, `GEMINI.md`, ADR-0016 và `docs/design/ui-rules.md` đã được Claude đặt sẵn vào repo. Commit chúng trên nhánh mới:

```powershell
git add automation CLAUDE.md GEMINI.md docs/adr/0016-form-templates.md docs/design/ui-rules.md .gitignore
git commit -m "chore: bo tu dong hoa va ADR-0016 mau bang diem"
```

> Chạy ngay trong thư mục repo, **không dùng git worktree**. Worktree không có `node_modules`, `.local/venv-ml`, `.env` và trọng số mô hình, nên gate sẽ fail. Nhánh riêng cùng các commit `auto(Px)` là đủ để quay lại khi cần.

### 2. Cài CLI reviewer vào ổ F

```powershell
npm config get prefix                        # xem npm đang cài global vào đâu
npm config set prefix F:\tools\npm           # chuyển sang ổ F (chỉ ảnh hưởng gói cài MỚI)
# Thêm F:\tools\npm vào PATH (Settings → Environment Variables → Path), mở lại PowerShell.

npm install -g @openai/codex                 # Codex CLI
npm install -g @google/gemini-cli            # Gemini CLI (nếu muốn dùng Gemini)

codex login                                  # đăng nhập 1 lần
gemini                                       # mở 1 lần để đăng nhập, rồi /quit
```

Kiểm tra cả ba lệnh đều chạy được: `claude --version`, `codex --version`, `gemini --version`.

### 3. Đối chiếu cờ lệnh với phiên bản của bạn

CLI đổi cờ khá thường xuyên. Chạy `claude --help`, `codex exec --help`, `gemini --help` rồi so với `config.json`:

- **Claude:** cần `-p`, `--permission-mode acceptEdits`, `--allowedTools`, `--max-turns`, `--output-format json`.
- **Codex:** cần `exec`, `--sandbox`, `--output-last-message`. Nếu bản của bạn không có `--output-schema`, xóa 2 phần tử `"--output-schema", "{schema_file}"`; script vẫn tự kiểm JSON.
  - Nếu Codex báo lỗi sandbox trên Windows, đổi `"workspace-write"` thành `"danger-full-access"`. Script vẫn cất mọi thay đổi reviewer để lại vào git stash.
- **Gemini:** sửa `"model"` thành đúng tên model của bạn (xem bằng `/model` trong Gemini CLI). Nếu bản của bạn dùng `--yolo` thay cho `--approval-mode yolo`, sửa lại cho khớp.

### 4. (Rất nên làm) DB test cho P2, P3

Các gate `db` và `integration` chỉ chạy khi có biến `TEST_RUNTIME_URL`. Thiếu biến thì gate được **bỏ qua**, nghĩa là migration và transaction không được kiểm bằng DB thật. Cách dựng DB test: `docs/development/onboarding.md`. Sau khi dựng xong, thêm `TEST_MIGRATION_URL` và `TEST_RUNTIME_URL` vào `.env`.

Muốn **bắt buộc** có DB test thì đổi `"on_missing": "skip"` thành `"fail"` trong `config.json`.

### 5. Kiểm tra đường ống

```powershell
python automation/run.py --simulate --simulate-fail-once --only P1   # agent giả, không gọi AI, không sửa code
python automation/run.py --precheck                                  # chạy THẬT mọi gate trên code hiện tại
```

`--precheck` phải PASS rồi mới chạy phase. Nếu code hiện tại đã fail test, agent sẽ mất vòng để sửa lỗi có sẵn và đổ lỗi qua lại. Hãy sửa cho xanh trước, hoặc báo Claude sửa trong một lượt riêng.

## B. Chạy

```powershell
python automation/run.py                     # chạy P1 → P6, reviewer = Codex
python automation/run.py --reviewer gemini   # reviewer = Gemini
python automation/run.py --until P3          # chạy tới hết P3 rồi dừng
python automation/run.py --only P4           # chỉ một phase
python automation/run.py --status            # xem tiến độ
```

- Để cửa sổ PowerShell mở và **tắt chế độ ngủ** của máy (Settings → Power → Sleep: Never) khi chạy qua đêm.
- Mỗi phase thường mất 30–120 phút. Phase P2 và P3 lâu nhất.
- Theo dõi trong `automation/runs/SUMMARY.md` (tóm tắt) hoặc `automation/runs/run.log` (chi tiết).
- Muốn dừng thì bấm `Ctrl+C`. Chạy lại lệnh cũ, script sẽ tiếp tục từ đúng bước đang dở (dựa vào `runs/state.json`).

## C. Khi script dừng

| Thông báo     | Ý nghĩa                                                        | Bạn làm gì                                                         |
| ------------- | -------------------------------------------------------------- | ------------------------------------------------------------------ |
| `Hoàn tất`    | Mọi phase PASS                                                 | Xem `git log`, chạy thử app, rồi merge hoặc tạo PR như bình thường |
| `AGENT_ERROR` | Claude thoát lỗi: hết hạn mức, hết giờ hoặc mất mạng           | Đợi hạn mức hồi lại rồi chạy lại đúng lệnh cũ                      |
| `BLOCKED`     | Hai agent bất đồng, hết số vòng, hoặc cần quyết định nghiệp vụ | Xem bên dưới                                                       |

**Xử lý BLOCKED:**

1. Mở `automation/runs/SUMMARY.md` để xem lý do và finding nào bị kẹt.
2. Mở `automation/runs/<Phase>/review-r<N>.json` (mục `findings`, `escalate`) và `fix-r<N>.json` (lập luận của Claude).
3. Quyết định, rồi ghi vào `automation/decisions.md` ở mục "Trả lời các mục escalate". Ví dụ:
   ```
   ### P3-F2 (2026-10-21)
   Kết luận: Reviewer đúng. Lô phải rollback toàn bộ khi một trang lỗi.
   ```
4. Commit file đó: `git commit -am "decision: P3-F2"`.
5. Chạy `python automation/run.py --unblock P3`. Phase được thêm 2 vòng và tiếp tục; hai agent đều phải làm theo quyết định của bạn.

Nếu một phase hỏng nặng và muốn làm lại từ đầu phase: tìm commit `base` của phase trong `runs/state.json`, rồi chạy `git reset --hard <base>`. Thao tác này xóa mọi thay đổi của phase, nên chỉ làm khi chắc chắn. Sau đó xóa mục phase đó trong `state.json` và chạy lại.

## D. Luật chống tranh cãi (đã cài trong script và prompt)

1. Gate (lint/test) do **script** chạy. Không agent nào tự khẳng định "test pass" thay cho script.
2. Reviewer chỉ được chặn (BLOCKER/MAJOR) khi chỉ ra vi phạm một **AC cụ thể** của phase hoặc một bất biến trong AGENTS.md mục 7, kèm bằng chứng tái hiện được. Ý kiến khác chỉ được ghi vào `suggestions`, không chặn.
3. Từ vòng 2, reviewer chỉ kiểm finding cũ và lỗi mới do chính phần sửa gây ra.
4. Claude được phản bác (DISPUTED) mỗi finding **một lần**. Nếu reviewer vẫn giữ ý kiến thì phase BLOCKED để bạn quyết, không tranh luận tiếp.
5. Một finding bị mở lại 2 lần sau khi Claude báo đã sửa → BLOCKED.
6. Tối đa 3 lượt review và 5 vòng mỗi phase. Hết mà chưa PASS → BLOCKED.
7. Reviewer sửa file → script cất vào git stash. Claude sửa file điều phối hoặc migration cũ → script hoàn tác.

## E. Chi phí và hạn mức

Mỗi vòng gọi Claude một lần (lâu nhất) và reviewer một lần. Một phase thuận lợi tốn khoảng 1 lượt Claude dài và 1 lượt review. Phase khó có thể tới 5 lượt Claude. Nếu gói của bạn giới hạn theo khung giờ, nên chạy từng phần (`--until P2`, rồi `--until P4`…).
