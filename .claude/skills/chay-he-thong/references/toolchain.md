# Toolchain

| Công cụ        | Phiên bản / nguồn                                                    |
| -------------- | -------------------------------------------------------------------- |
| Node           | 24.19.0, .node-version và engines                                    |
| pnpm           | 11.19.0, packageManager                                              |
| Nest           | 12.0.1                                                               |
| Prisma         | 7.10.0 stable, không dùng 8 RC                                       |
| PostgreSQL     | 18, Compose pin 18.0-bookworm                                        |
| Flutter / Dart | 3.35.7 / 3.9.2 đã có trên máy, cần PR kiểm chứng riêng khi nâng      |
| Generator      | OpenAPI Generator 7.17.0, wrapper 2.41.0                             |
| Java           | 17+, dùng Android Studio JBR 21 khi máy mặc định Java 8              |
| Redis / MinIO  | Pin tags trong compose.yaml; cần kiểm chứng pull/runtime bằng Docker |

Nguồn chính thức và đánh đổi tại ADR-0001. Không tự nâng SDK global. Nếu pnpm gọi Node cũ: sửa PATH terminal để thư mục Node 24 đứng trước các bản cũ rồi kiểm `node --version`. Nếu generator lỗi UnsupportedClassVersionError: kiểm `java -version`, đặt JAVA_HOME/PATH tới JDK phù hợp. Không tắt engine checks để vượt lỗi.

MinIO root credentials chỉ dành local development. Production phải cấp tài khoản storage tối thiểu và TLS, chưa có deployment production trong phase 0.
