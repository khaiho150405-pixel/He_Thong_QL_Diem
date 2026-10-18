// Luật hợp lệ của mẫu bảng điểm và ánh xạ (nhóm, thứ tự) -> thành phần điểm (ADR-0016 mục 1). Thuần domain: không phụ thuộc
// framework, DB hay dịch vụ nhận dạng. Hàm SQL kiem_tra_dinh_nghia_mau lặp lại cùng các luật ở tầng DB.

export const COLUMN_ROLES = [
  "STT",
  "HO_TEN",
  "DIEM",
  "DIEM_CHU",
  "BO_QUA",
] as const;
export type ColumnRole = (typeof COLUMN_ROLES)[number];

export const GRADE_GROUPS = ["TX", "GK", "CK"] as const;
export type GradeGroup = (typeof GRADE_GROUPS)[number];

export const MAX_TEMPLATE_COLUMNS = 64;
export const MAX_ORDER_IN_GROUP = 20;

/** Một cột dữ liệu của tờ, theo thứ tự trái -> phải (`index` từ 0). */
export interface TemplateColumn {
  index: number;
  role: ColumnRole;
  /** Chỉ cột DIEM. */
  group: GradeGroup | null;
  /** Chỉ cột DIEM: thứ tự trong nhóm, từ 1. */
  order: number | null;
  /** Chỉ cột DIEM_CHU: `index` của cột DIEM đi kèm. */
  pairedWith: number | null;
  headerText: string | null;
}

export interface TemplateDefinition {
  name: string;
  description: string | null;
  columns: TemplateColumn[];
}

/** Lý do ổn định (không chứa dữ liệu người dùng) khi định nghĩa mẫu không hợp lệ. */
export type DefinitionIssue =
  | "SHAPE"
  | "NAME"
  | "COLUMN_COUNT"
  | "COLUMN_INDEX"
  | "HO_TEN"
  | "STT"
  | "NO_DIEM"
  | "GROUP_ORDER_DUPLICATE"
  | "DIEM_FIELDS"
  | "DIEM_CHU_FIELDS"
  | "EXTRA_FIELDS"
  | "PAIRING";

const MESSAGES: Record<DefinitionIssue, string> = {
  SHAPE: "Định nghĩa mẫu sai cấu trúc.",
  NAME: "Tên mẫu phải có từ 1 đến 100 ký tự; mô tả tối đa 500 ký tự.",
  COLUMN_COUNT: "Định nghĩa phải liệt kê đủ mọi cột của tờ mẫu.",
  COLUMN_INDEX: "Chỉ số cột phải là 0..n-1, mỗi số đúng một lần.",
  HO_TEN: "Mẫu phải có đúng một cột Họ tên.",
  STT: "Mẫu có tối đa một cột STT.",
  NO_DIEM: "Mẫu phải có ít nhất một cột điểm.",
  GROUP_ORDER_DUPLICATE:
    "Cặp (nhóm hệ số, thứ tự trong nhóm) không được trùng giữa các cột điểm.",
  DIEM_FIELDS: "Cột điểm cần nhóm TX/GK/CK và thứ tự trong nhóm từ 1 đến 20.",
  DIEM_CHU_FIELDS: "Cột điểm chữ cần chỉ rõ cột điểm số đi kèm.",
  EXTRA_FIELDS:
    "Chỉ cột điểm mới có nhóm và thứ tự; chỉ cột điểm chữ mới có cột đi kèm.",
  PAIRING:
    "Cột điểm chữ phải đi kèm một cột điểm có thật; mỗi cột điểm có tối đa một cột chữ.",
};

export class InvalidTemplateDefinition extends Error {
  constructor(readonly issue: DefinitionIssue) {
    super(MESSAGES[issue]);
  }
}

function fail(issue: DefinitionIssue): never {
  throw new InvalidTemplateDefinition(issue);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function optionalText(value: unknown, max: number): string | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "string" || value.length > max) return fail("SHAPE");
  const text = value.trim();
  return text ? text : null;
}

function optionalInt(value: unknown): number | null {
  if (value === undefined || value === null) return null;
  if (typeof value !== "number" || !Number.isSafeInteger(value))
    return fail("SHAPE");
  return value;
}

/** Phân tích JSON thô của `definition` thành `TemplateDefinition`; chưa kiểm luật nhiều cột. */
export function parseDefinition(raw: unknown): TemplateDefinition {
  if (!isRecord(raw)) return fail("SHAPE");
  const allowed = new Set(["name", "description", "columns"]);
  if (Object.keys(raw).some((key) => !allowed.has(key))) return fail("SHAPE");
  if (typeof raw.name !== "string") return fail("NAME");
  const name = raw.name.trim();
  if (name.length < 1 || name.length > 100) return fail("NAME");
  if (
    raw.description !== undefined &&
    raw.description !== null &&
    (typeof raw.description !== "string" || raw.description.length > 500)
  )
    return fail("NAME");
  if (
    !Array.isArray(raw.columns) ||
    raw.columns.length < 2 ||
    raw.columns.length > MAX_TEMPLATE_COLUMNS
  )
    return fail("COLUMN_COUNT");
  const columnKeys = new Set([
    "index",
    "role",
    "group",
    "order",
    "pairedWith",
    "headerText",
  ]);
  const columns = raw.columns.map((item): TemplateColumn => {
    if (!isRecord(item)) return fail("SHAPE");
    if (Object.keys(item).some((key) => !columnKeys.has(key)))
      return fail("SHAPE");
    const index = optionalInt(item.index);
    if (index === null || index < 0 || index >= MAX_TEMPLATE_COLUMNS)
      return fail("COLUMN_INDEX");
    if (
      typeof item.role !== "string" ||
      !(COLUMN_ROLES as readonly string[]).includes(item.role)
    )
      return fail("SHAPE");
    const group = item.group ?? null;
    if (
      group !== null &&
      (typeof group !== "string" ||
        !(GRADE_GROUPS as readonly string[]).includes(group))
    )
      return fail("SHAPE");
    return {
      index,
      role: item.role as ColumnRole,
      group: group as GradeGroup | null,
      order: optionalInt(item.order),
      pairedWith: optionalInt(item.pairedWith),
      headerText: optionalText(item.headerText, 100),
    };
  });
  return {
    name,
    description: optionalText(raw.description, 500),
    columns,
  };
}

/**
 * Kiểm luật hợp lệ của danh sách cột với số cột của tờ mẫu (ADR-0016 mục 1). Ném `InvalidTemplateDefinition`.
 * Phải liệt kê đủ mọi cột 0..n-1 (cột không đọc dùng BO_QUA).
 */
export function validateColumns(
  columns: readonly TemplateColumn[],
  columnCount: number,
): void {
  if (columns.length !== columnCount) return fail("COLUMN_COUNT");
  const indexes = new Set(columns.map((column) => column.index));
  if (
    indexes.size !== columnCount ||
    columns.some((column) => column.index < 0 || column.index >= columnCount)
  )
    return fail("COLUMN_INDEX");

  for (const column of columns) {
    if (column.role === "DIEM") {
      if (
        column.group === null ||
        column.order === null ||
        column.order < 1 ||
        column.order > MAX_ORDER_IN_GROUP
      )
        return fail("DIEM_FIELDS");
      if (column.pairedWith !== null) return fail("EXTRA_FIELDS");
    } else if (column.role === "DIEM_CHU") {
      if (column.pairedWith === null) return fail("DIEM_CHU_FIELDS");
      if (column.group !== null || column.order !== null)
        return fail("EXTRA_FIELDS");
    } else if (
      column.group !== null ||
      column.order !== null ||
      column.pairedWith !== null
    )
      return fail("EXTRA_FIELDS");
  }

  if (columns.filter((column) => column.role === "HO_TEN").length !== 1)
    return fail("HO_TEN");
  if (columns.filter((column) => column.role === "STT").length > 1)
    return fail("STT");
  const grades = columns.filter((column) => column.role === "DIEM");
  if (!grades.length) return fail("NO_DIEM");
  const keys = grades.map((column) => `${column.group}:${column.order}`);
  if (new Set(keys).size !== keys.length) return fail("GROUP_ORDER_DUPLICATE");

  const gradeIndexes = new Set(grades.map((column) => column.index));
  const paired = columns
    .filter((column) => column.role === "DIEM_CHU")
    .map((column) => column.pairedWith!);
  if (
    paired.some((target) => !gradeIndexes.has(target)) ||
    new Set(paired).size !== paired.length
  )
    return fail("PAIRING");
}

/** Định danh ổn định của cột điểm trong layout gửi dịch vụ nhận dạng, ví dụ `TX1`, `GK1`, `CK1`. */
export function gradeKey(group: GradeGroup, order: number): string {
  return `${group}${order}`;
}

/** Cột nào đọc hai kênh (có cột điểm chữ đi kèm). Suy ra từ định nghĩa, không lưu riêng (ADR-0016). */
export function readsBothChannels(
  columns: readonly TemplateColumn[],
  gradeIndex: number,
): boolean {
  return columns.some(
    (column) => column.role === "DIEM_CHU" && column.pairedWith === gradeIndex,
  );
}

/** Các cột gửi tới `/v2/recognize`: STT (nếu có), HO_TEN, mọi DIEM (kèm `key`, `writtenIndex`) và DIEM_CHU đi kèm. */
export function recognitionColumns(columns: readonly TemplateColumn[]): Array<{
  index: number;
  role: "STT" | "HO_TEN" | "DIEM" | "DIEM_CHU";
  key?: string;
  writtenIndex?: number | null;
}> {
  const result: ReturnType<typeof recognitionColumns> = [];
  for (const column of [...columns].sort((a, b) => a.index - b.index)) {
    if (column.role === "BO_QUA") continue;
    if (column.role === "DIEM") {
      const written = columns.find(
        (other) =>
          other.role === "DIEM_CHU" && other.pairedWith === column.index,
      );
      result.push({
        index: column.index,
        role: "DIEM",
        key: gradeKey(column.group!, column.order!),
        writtenIndex: written ? written.index : null,
      });
    } else result.push({ index: column.index, role: column.role });
  }
  return result;
}

/** Thành phần điểm của một môn, đủ thông tin để ánh xạ. */
export interface MappableComponent {
  id: number;
  group: string;
  displayOrder: number;
}

export interface ColumnMapping {
  templateColumnIndex: number;
  key: string;
  group: GradeGroup;
  order: number;
  readMode: "SO_VA_CHU" | "CHI_SO";
  /** null khi môn không có thành phần thứ `order` của nhóm `group`. */
  componentId: number | null;
}

/**
 * Ánh xạ (nhóm, thứ tự) của cột DIEM tới thành phần của môn: `(TX, 2)` là thành phần `loai_he_so = 'TX'` đứng thứ 2 theo
 * `thu_tu_hien_thi, ma_thanh_phan` (ADR-0016 mục 1). Mẫu không gắn với môn nên cột không có thành phần tương ứng thì
 * `componentId = null` (giáo viên không chọn được).
 */
export function mapColumnsToComponents(
  columns: readonly TemplateColumn[],
  components: readonly MappableComponent[],
): ColumnMapping[] {
  const ordered = [...components].sort(
    (a, b) => a.displayOrder - b.displayOrder || a.id - b.id,
  );
  return columns
    .filter((column) => column.role === "DIEM")
    .sort((a, b) => a.index - b.index)
    .map((column) => {
      const sameGroup = ordered.filter((item) => item.group === column.group);
      return {
        templateColumnIndex: column.index,
        key: gradeKey(column.group!, column.order!),
        group: column.group!,
        order: column.order!,
        readMode: readsBothChannels(columns, column.index)
          ? "SO_VA_CHU"
          : "CHI_SO",
        componentId: sameGroup[column.order! - 1]?.id ?? null,
      };
    });
}
