# ADR-0011 — Build MinIO development/test từ source cố định

Ngày 2026-09-28, PR #9 CI không khởi động được storage vì image MinIO trên Quay trả unauthorized; Docker Hub cũng không cung cấp image đã dùng. Upstream Community chuyển sang source-only: https://github.com/minio/minio/blob/master/README.md.

Compose build hai target trong infrastructure/docker/minio.Dockerfile từ source chính thức, khóa commit:

- minio RELEASE.2025-09-07T16-13-09Z: 01ce918d8279a20e4706b96a64396146894adee4.
- mc RELEASE.2025-08-13T08-35-41Z: d6541ea280b73a834b64d4097e21f2be77676104.

Giữ MinIO/S3 contract, cổng, volume, credentials từ env và bucket private. Không dùng image bên thứ ba hoặc bỏ kiểm thử storage. Go chỉ nằm trong build stage; runtime có CA certificates/curl để healthcheck, kèm LICENSE upstream. Build đầu cần mạng và lâu hơn pull image; các lớp Docker được cache cho các lần sau.

Phạm vi là development/test, không xác nhận phiên bản này sẵn sàng production. Cập nhật phiên bản/security là thay đổi riêng cần review. Rollback Dockerfile/Compose chỉ khi có nguồn image đã được kiểm chứng; không xóa volume hoặc đổi credentials để xử lý lỗi registry.
