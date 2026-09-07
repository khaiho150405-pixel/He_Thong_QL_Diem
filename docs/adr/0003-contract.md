# ADR-0003 — OpenAPI và Dart client

Nguồn là NestJS DTO/controller. pnpm api:export xuất snapshot không kết nối DB, pnpm client:generate chạy OpenAPI Generator 7.17.0 dart-dio/json_serializable và build_runner. Commit serializers và lockfiles. Không sửa generated code bằng tay; custom adapters ở Flutter core/data.

Success DTO trực tiếp; errors code/message/details/requestId. Phase 0 chỉ status health; khi thêm điểm/ID dùng decimal string và bigint string, thêm contract serialization tests trước expose endpoint. Không dùng JavaScript number cho bigint/Decimal.

pnpm contracts:check so snapshot trước/sau regeneration, kể cả chưa có commit Git. Pin generator Java; yêu cầu Java 17+ (Java 8 mặc định không đủ). Không yêu cầu production secrets cho export. Update API/client cùng PR; breaking change phải có kế hoạch tương thích.
