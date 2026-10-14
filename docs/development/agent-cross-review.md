# Quy trình hai agent review chéo PR

Tài liệu này dành cho hai agent AI làm song song, mỗi agent trong một git worktree riêng, review PR của nhau mà không cần chủ dự án ra lệnh từng bước. Mọi quy tắc trong [AGENTS.md](../../AGENTS.md) và [CONTRIBUTING.md](../../CONTRIBUTING.md) vẫn áp dụng; nếu mâu thuẫn thì AGENTS.md thắng.

## 1. Nguyên tắc

- Chủ dự án là người quyết định cuối cùng. Agent **không merge**, không đổi branch protection, không đóng PR của bên kia.
- Giao tiếp chính thức nằm trong PR (comment, review). Tin nhắn trực tiếp giữa hai phiên chỉ để báo "có việc mới", kết luận vẫn phải ghi vào PR.
- Mỗi agent làm việc trong phạm vi được giao. Không sửa file ngoài phạm vi; thấy lỗi ở vùng của bên kia thì ghi comment, không tự sửa.
- Không làm lại phần đã xong, không tự nhảy sang giai đoạn khác (xem AGENTS.md mục 11).

## 2. Thiết lập một lần (chủ dự án làm)

1. Tạo hai worktree từ `main`, mỗi cái một nhánh theo quy ước `feat/<issue>-<slug>`:

   ```sh
   git worktree add ../wt-a -b feat/<issue-a>-<slug> main
   git worktree add ../wt-b -b feat/<issue-b>-<slug> main
   ```

2. Điền bảng phân vai ở mục 3 và gửi cho cả hai agent câu lệnh khởi động ở mục 9.
3. Tài khoản GitHub: nếu hai agent dùng chung một tài khoản thì GitHub **không cho Approve PR của chính mình**. Khi đó review bằng comment theo mẫu ở mục 6 và ghi `LGTM` làm tín hiệu đồng ý. Nếu muốn Approve thật, dùng tài khoản hoặc bot thứ hai.

## 3. Phân vai và phạm vi (điền trước khi bắt đầu)

| Agent        | Nhánh | Worktree | Phạm vi được sửa | Không được đụng |
| ------------ | ----- | -------- | ---------------- | --------------- |
| A (tác giả)  |       |          |                  |                 |
| B (reviewer) |       |          |                  |                 |

Quy tắc phạm vi:

- Hai agent không sửa cùng một file. Nếu bắt buộc, thống nhất thứ tự merge trước và bên sau rebase.
- Không sửa tay `packages/api_client_dart`; tái sinh từ OpenAPI.
- Migration đã áp dụng không được sửa; thay đổi schema cần migration mới và phải báo chủ dự án.

## 4. Vòng đời một PR

```
A làm xong → A chạy kiểm tra → A mở PR + ghi "READY FOR REVIEW" → A CHỜ
B nhận tín hiệu → B review → B ghi kết quả (CHANGES REQUESTED hoặc LGTM) → B CHỜ
A nhận tín hiệu → A sửa, push, trả lời từng comment → A ghi "READY FOR REVIEW (vòng N)" → A CHỜ
... lặp lại đến khi LGTM hoặc hết số vòng
```

Sau đó vai trò đổi chiều: PR của B được A review theo cùng quy trình.

### Trạng thái trong PR

Mỗi agent ghi đúng một dòng trạng thái ở đầu comment mới nhất để bên kia đọc nhanh:

- `STATUS: READY FOR REVIEW (vòng N)`: tác giả đã push, mời review.
- `STATUS: CHANGES REQUESTED (vòng N)`: reviewer yêu cầu sửa.
- `STATUS: LGTM`: reviewer đồng ý, không còn comment mở.
- `STATUS: BLOCKED, CẦN CHỦ DỰ ÁN`: dừng và đợi con người (xem mục 8).

## 5. Cách chờ mà không thoát phiên

Sau khi ghi trạng thái, agent **không kết thúc phiên**. Dùng theo thứ tự ưu tiên:

1. **Đăng ký nhận hoạt động PR** của PR mình đang chờ (comment, review, push, thay đổi CI). Khi có thông báo mới thì đọc và xử lý.
2. **Hẹn giờ kiểm tra lại** nếu không nhận được thông báo: mỗi 10–20 phút chạy `gh pr view <số> --comments` và `gh pr checks <số>`. Không kiểm tra dồn dập dưới 5 phút.
3. **Nhắn trực tiếp** cho phiên kia (nếu có) chỉ để báo "đã cập nhật PR #N", không thay cho comment trong PR.

Trước khi chờ, ghi trạng thái vào `docs/development/CONTINUE.md` hoặc comment PR (đang chờ ai, ở vòng mấy, việc kế tiếp) để phiên mới vẫn biết phải làm gì nếu phiên cũ bị thu hồi.

Chờ tối đa **2 giờ** cho một lượt phản hồi. Quá hạn thì ghi `STATUS: BLOCKED` và báo chủ dự án.

## 6. Checklist reviewer

Reviewer đọc diff, kiểm tra thật và ghi kết quả từng mục (Đạt / Không đạt / Không áp dụng). Không ghi "đã kiểm" cho thứ chưa chạy.

1. **Phạm vi:** PR chỉ đổi đúng phạm vi đã giao, không format file không liên quan, không thêm dependency không lý do.
2. **Bất biến nghiệp vụ (AGENTS.md mục 7):** phân biệt `NULL` và `0.0`; người duyệt là con người; dòng Đỏ không tự điền; học sinh chỉ xem dữ liệu của mình.
3. **Phân quyền:** kiểm tra ở backend, có test âm tính; không bypass ở service nội bộ.
4. **Database:** transaction, audit, rollback; migration không sửa bản đã áp dụng; không dùng `db push`.
5. **Contract:** OpenAPI và client đã tái sinh, `pnpm contracts:check` đạt.
6. **Lỗi và trạng thái UI:** loading, empty, retry, mã lỗi ổn định.
7. **Bảo mật dữ liệu:** không secret, không PII thật, không ảnh hoặc dump DB trong commit.
8. **Kiểm thử:** tự chạy lại các lệnh dưới đây trong worktree của mình và đối chiếu kết quả tác giả báo.

   ```sh
   pnpm check
   pnpm contracts:check
   dart run melos run check   # khi đổi Flutter
   ```

   `pnpm test:db` chỉ chạy với DB test riêng (tên kết thúc `_test`), không dùng DB development.

9. **Tài liệu:** README, ADR, truy vết đã cập nhật khi hành vi thay đổi.

Mẫu comment review:

```
STATUS: CHANGES REQUESTED (vòng 1)

Đã chạy: pnpm check (đạt), pnpm contracts:check (đạt), widget test (1 lỗi)
Bắt buộc sửa:
1. <file:dòng> <vấn đề> <vì sao> <gợi ý>
Nên sửa (không chặn):
1. ...
Câu hỏi:
1. ...
```

Mỗi ý kiến "bắt buộc sửa" phải chỉ rõ file, dòng và lý do gắn với bất biến hoặc lỗi thật. Ý kiến sở thích cá nhân thuộc "nên sửa", không chặn LGTM.

## 7. Điều kiện đồng ý (LGTM)

Reviewer chỉ ghi `STATUS: LGTM` khi đủ tất cả:

- CI xanh trên commit mới nhất của PR.
- Reviewer đã tự chạy lại các lệnh kiểm tra ở mục 6 và đạt.
- Không còn comment "bắt buộc sửa" nào chưa được giải quyết.
- Mọi mục checklist là Đạt hoặc Không áp dụng (có lý do).

Khi cả hai PR đều có LGTM, hai agent dừng, tóm tắt cho chủ dự án và **chờ chủ dự án merge**.

## 8. Giới hạn vòng và khi nào phải dừng

- Tối đa **3 vòng** review cho mỗi PR.
- Tranh luận cùng một điểm quá 2 lượt mà chưa thống nhất thì ghi `STATUS: BLOCKED, CẦN CHỦ DỰ ÁN`, nêu hai phương án và đánh đổi, rồi dừng.
- Vòng 3 vẫn còn lỗi bắt buộc thì dừng và báo, không tiếp tục vòng 4.
- Bên tác giả không được "chiều" reviewer bằng cách bỏ test hoặc nới bất biến để đạt LGTM. Reviewer không được hạ tiêu chuẩn để kết thúc sớm.

Dừng ngay và báo chủ dự án, không tự quyết, khi gặp:

- Đổi schema hoặc migration, đổi phân quyền, đổi cách tính điểm, đổi xếp loại.
- Cần thêm dependency, thay stack, hoặc cần ADR mới.
- Phát hiện secret hoặc dữ liệu thật trong commit.
- Hai PR xung đột file mà không tự rebase an toàn được.
- CI lỗi do hạ tầng, không phải do code của PR.

## 9. Câu lệnh khởi động cho mỗi agent

Gửi nguyên văn, thay phần trong ngoặc nhọn:

> Bạn là agent {A|B} trong quy trình review chéo. Đọc `AGENTS.md`, `CONTRIBUTING.md` và `docs/development/agent-cross-review.md` trước. Làm việc trong worktree `{đường dẫn}` trên nhánh `{nhánh}`, chỉ sửa trong phạm vi `{phạm vi}`. Khi xong, chạy kiểm tra, mở PR và ghi `STATUS: READY FOR REVIEW`, rồi chờ PR của bên kia để review theo checklist mục 6. Không merge, không kết thúc phiên khi đang chờ. Tuân thủ giới hạn vòng và điều kiện dừng ở mục 8. Khi cả hai bên LGTM thì báo tóm tắt cho tôi và dừng.

## 10. Báo cáo cuối cho chủ dự án

Khi kết thúc (LGTM hoặc BLOCKED), mỗi agent gửi báo cáo ngắn:

- PR đã làm, PR đã review, số vòng.
- File đã đổi và hành vi mới.
- Lệnh kiểm thử đã chạy và kết quả thật; phần chưa kiểm tra.
- Điểm còn bất đồng hoặc rủi ro.
- Việc chủ dự án cần quyết (merge, thứ tự merge, migration).
