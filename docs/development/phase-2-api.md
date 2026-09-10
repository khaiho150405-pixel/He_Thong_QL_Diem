# Review API bảng điểm — Phase 2 phần 2

Chạy theo README, áp dụng migration `202609100003_gradebook_write` bằng `pnpm db:migrate` và sinh Prisma bằng `pnpm db:generate`. Không sửa migration đã chạy. Local Swagger: http://localhost:3000/api/docs. Các URL bên dưới có prefix `/api/v1`.

| Method/path                                        | Vai trò và dữ liệu                                                       |
| -------------------------------------------------- | ------------------------------------------------------------------------ |
| GET /gradebooks?cursor=0                           | QTV xem mọi bảng; GV chỉ bảng được phân công; 50 bảng/trang              |
| POST /gradebooks                                   | GV đúng phân công; body classId/subjectId/termId; gọi lại trả bảng cũ    |
| GET /gradebooks/:id/cells?cursor=0                 | QTV hoặc GV đúng phân công; book/version và 50 ô/trang, nextCursor chuỗi |
| PUT /gradebooks/:id/grades                         | GV; expectedVersion và changes; x-idempotency-key bắt buộc               |
| POST /gradebooks/:id/sync-roster                   | GV; expectedVersion, x-idempotency-key; thêm ô học sinh mới              |
| POST /gradebooks/:id/lock                          | GV; expectedVersion, x-idempotency-key; chốt bảng                        |
| GET /gradebooks/:id/cells/:cellId/history?cursor=0 | QTV hoặc GV đúng phân công; chỉ ô thuộc bảng này                         |

Ví dụ body nhập tay (ID minh họa phải thay bằng ID trả từ GET cells):

```json
{
  "expectedVersion": 0,
  "changes": [
    { "cellId": "123", "value": "0.0", "reason": "Nhập điểm bài kiểm tra" },
    { "cellId": "124", "value": null, "reason": "Hủy giá trị nhập nhầm" }
  ]
}
```

Response có items (id/value/status/source), bookId và version mới. Dùng version mới cho thao tác tiếp theo. Retry sau lỗi mạng giữ nguyên body và key; khi người dùng sửa nội dung phải dùng key mới. 409 do version: tải lại lưới, cho người dùng đối chiếu trước khi gửi; không tự gán version mới rồi ghi đè. 400 là body sai định dạng, 401 hết phiên, 403 sai quyền, 404 ô/bảng không thuộc phạm vi URL. Mọi lỗi có requestId.

Web dùng cookie HttpOnly cùng origin và x-csrf-token do session trả, native dùng bearer. QTV không có quyền nhập/chốt; HS chưa có API tra cứu điểm cá nhân (UC18). Không đưa session token vào URL hoặc commit file request chứa token.

Chốt bị từ chối nếu thiếu điểm bắt buộc của học sinh đang học, thiếu dòng học sinh mới hoặc còn ô/phiếu chờ đối chiếu. Sync sĩ số trước khi nhập cho học sinh mới; không có API mở lại bảng đã chốt. Khi ngừng học, hàng cũ vẫn có trong dữ liệu và active=false. Quy tắc chốt này là mặc định development để nhóm xác nhận trước production theo ADR-0007.

Review bắt buộc: nhập NULL/0.0; sửa nhiều ô; gửi lại cùng key; dùng key người khác; trộn cellId của bảng khác; phiên bị thu hồi; hai lần sửa/chốt cùng version; cố ý gây lỗi audit; chốt khi thiếu điểm; đồng bộ học sinh mới. Test tự động nằm ở `apps/api/test/integration/gradebook-write.test.ts` và `gradebooks.test.ts`. Giao diện người dùng cho các API này sẽ được làm ở phần 3.
