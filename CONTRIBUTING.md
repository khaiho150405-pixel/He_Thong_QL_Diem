# Làm việc chung

Đọc AGENTS.md và README trước khi thay đổi. Mỗi issue ghi UC/bất biến, phạm vi, acceptance criteria và người phụ trách. Nhánh từ main: feat/<issue>-<slug>, fix/..., docs/... hoặc chore/.... Mở draft PR sớm khi đổi schema/contract.

Trước PR: pnpm check, pnpm test:db với DB test riêng, pnpm contracts:check và kiểm tra Flutter tương ứng. Ghi kết quả thật; không đánh dấu test chưa chạy. Reviewer khác tác giả xem quyền, transaction, SQL, contract, lỗi và rollback. Squash merge sau khi CI pass trên bản mới nhất.

Migration đã áp dụng ở môi trường chung không được sửa. Nhánh đổi schema sau phải cập nhật main, tạo migration tiếp theo và test toàn bộ chuỗi. Không dùng db push. Lockfile/DTO sinh bị conflict phải tái sinh từ nguồn đã merge. Không sửa tay packages/api_client_dart hoặc import repository module khác.

Commit nhỏ, không format file không liên quan. Không force-push nhánh chung khi chưa phối hợp. Không commit .env, dữ liệu học sinh thật, ảnh hoặc dump DB. Thêm dependency phải giải thích lý do. Thay stack/quy tắc cần ADR và cập nhật truy vết.

Maintainer phải bật PR required, review độc lập, giải quyết conversations, required-checks, chặn force-push/xóa main. CODEOWNERS hiện yêu cầu @trongv2310 và @caohaidang157 cho các vùng code chung; GitHub chỉ gửi review request sau khi hai tài khoản đã nhận lời mời collaborator. File workflow không tự bật branch protection. Repository đã có tại [khaiho150405-pixel/He_Thong_QL_Diem](https://github.com/khaiho150405-pixel/He_Thong_QL_Diem); license chưa được chủ dự án chọn.
