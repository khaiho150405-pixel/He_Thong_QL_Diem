// Điểm vào công khai của module form-templates cho các module khác (ranh giới: scripts/check-boundaries.mjs).
// Lộ các hàm thuần của miền mẫu bảng điểm mà lô nhận dạng (module recognition) cần: dựng layout từ cột mẫu và ánh xạ
// (nhóm, thứ tự) -> thành phần điểm. Không lộ service, store hay controller.
export {
  gradeKey,
  mapColumnsToComponents,
  readsBothChannels,
  recognitionColumns,
  recognitionColumnsFor,
} from "./domain/definition.js";
export type {
  ColumnMapping,
  ColumnRole,
  GradeGroup,
  MappableComponent,
  TemplateColumn,
} from "./domain/definition.js";
