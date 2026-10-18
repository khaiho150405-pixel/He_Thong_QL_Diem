import assert from "node:assert/strict";
import { test } from "node:test";
import {
  InvalidTemplateDefinition,
  gradeKey,
  mapColumnsToComponents,
  parseDefinition,
  readsBothChannels,
  recognitionColumns,
  validateColumns,
  type DefinitionIssue,
  type TemplateColumn,
} from "../src/modules/form-templates/domain/definition.js";

// Luật hợp lệ của mẫu và ánh xạ (nhóm, thứ tự) -> thành phần (ADR-0016 mục 1). Dữ liệu hoàn toàn giả.

const col = (
  index: number,
  role: TemplateColumn["role"],
  extra: Partial<TemplateColumn> = {},
): TemplateColumn => ({
  index,
  role,
  group: null,
  order: null,
  pairedWith: null,
  headerText: null,
  ...extra,
});

// STT | Họ tên | TX1 số | TX1 chữ | GK1 số | Ghi chú
const valid = (): TemplateColumn[] => [
  col(0, "STT"),
  col(1, "HO_TEN"),
  col(2, "DIEM", { group: "TX", order: 1 }),
  col(3, "DIEM_CHU", { pairedWith: 2 }),
  col(4, "DIEM", { group: "GK", order: 1 }),
  col(5, "BO_QUA"),
];

function issueOf(columns: TemplateColumn[], count = columns.length) {
  try {
    validateColumns(columns, count);
  } catch (error) {
    assert.ok(error instanceof InvalidTemplateDefinition);
    return error.issue;
  }
  return null;
}

test("a well-formed template passes", () => {
  assert.equal(issueOf(valid()), null);
});

test("template with only a score column and no STT column is allowed", () => {
  assert.equal(
    issueOf([col(0, "HO_TEN"), col(1, "DIEM", { group: "CK", order: 1 })]),
    null,
  );
});

test("each invalid definition is rejected with a stable reason", () => {
  const cases: Array<[string, TemplateColumn[], DefinitionIssue]> = [
    [
      "missing HO_TEN",
      valid().map((c) => (c.role === "HO_TEN" ? col(c.index, "BO_QUA") : c)),
      "HO_TEN",
    ],
    [
      "two HO_TEN",
      valid().map((c) => (c.index === 5 ? col(5, "HO_TEN") : c)),
      "HO_TEN",
    ],
    ["two STT", valid().map((c) => (c.index === 5 ? col(5, "STT") : c)), "STT"],
    ["no DIEM", [col(0, "STT"), col(1, "HO_TEN"), col(2, "BO_QUA")], "NO_DIEM"],
    [
      "duplicate (group, order)",
      valid().map((c) =>
        c.index === 4 ? col(4, "DIEM", { group: "TX", order: 1 }) : c,
      ),
      "GROUP_ORDER_DUPLICATE",
    ],
    [
      "DIEM without group",
      valid().map((c) => (c.index === 4 ? col(4, "DIEM", { order: 1 }) : c)),
      "DIEM_FIELDS",
    ],
    [
      "DIEM order 0",
      valid().map((c) =>
        c.index === 4 ? col(4, "DIEM", { group: "GK", order: 0 }) : c,
      ),
      "DIEM_FIELDS",
    ],
    [
      "DIEM_CHU without pairing",
      valid().map((c) => (c.index === 3 ? col(3, "DIEM_CHU") : c)),
      "DIEM_CHU_FIELDS",
    ],
    [
      "DIEM_CHU pointing at a non-DIEM column",
      valid().map((c) =>
        c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 1 }) : c,
      ),
      "PAIRING",
    ],
    [
      "DIEM_CHU pointing at a missing column",
      valid().map((c) =>
        c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 40 }) : c,
      ),
      "PAIRING",
    ],
    [
      "DIEM_CHU pointing at itself",
      valid().map((c) =>
        c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 3 }) : c,
      ),
      "PAIRING",
    ],
    [
      "two DIEM_CHU for one DIEM",
      valid().map((c) =>
        c.index === 5 ? col(5, "DIEM_CHU", { pairedWith: 2 }) : c,
      ),
      "PAIRING",
    ],
    [
      "BO_QUA carrying a group",
      valid().map((c) =>
        c.index === 5 ? col(5, "BO_QUA", { group: "TX" }) : c,
      ),
      "EXTRA_FIELDS",
    ],
    [
      "DIEM carrying a pairing",
      valid().map((c) =>
        c.index === 4
          ? col(4, "DIEM", { group: "GK", order: 1, pairedWith: 2 })
          : c,
      ),
      "EXTRA_FIELDS",
    ],
    [
      "duplicate column index",
      valid().map((c) => (c.index === 5 ? col(4, "BO_QUA") : c)),
      "COLUMN_INDEX",
    ],
    [
      "index out of range",
      valid().map((c) => (c.index === 5 ? col(9, "BO_QUA") : c)),
      "COLUMN_INDEX",
    ],
  ];
  for (const [label, columns, expected] of cases)
    assert.equal(issueOf(columns), expected, label);
});

test("the definition must list every column of the sheet", () => {
  assert.equal(issueOf(valid().slice(0, 5), 6), "COLUMN_COUNT");
  assert.equal(issueOf(valid(), 7), "COLUMN_COUNT");
});

test("parseDefinition trims, nulls empty text and rejects stray keys", () => {
  const parsed = parseDefinition({
    name: "  Mẫu thử  ",
    description: "   ",
    columns: [
      { index: 0, role: "HO_TEN", headerText: " Họ và tên " },
      { index: 1, role: "DIEM", group: "TX", order: 1 },
    ],
  });
  assert.equal(parsed.name, "Mẫu thử");
  assert.equal(parsed.description, null);
  assert.equal(parsed.columns[0]!.headerText, "Họ và tên");
  assert.equal(parsed.columns[1]!.pairedWith, null);

  const bad = (raw: unknown) =>
    assert.throws(() => parseDefinition(raw), InvalidTemplateDefinition);
  bad(null);
  bad([]);
  bad({ name: "", columns: [] });
  bad({ name: "x".repeat(101), columns: valid() });
  bad({ name: "ok", columns: valid(), extra: true });
  bad({ name: "ok", columns: [{ index: 0, role: "HO_TEN" }] });
  bad({
    name: "ok",
    columns: [
      { index: 0, role: "HO_TEN", hacker: 1 },
      { index: 1, role: "DIEM", group: "TX", order: 1 },
    ],
  });
  bad({
    name: "ok",
    columns: [
      { index: 0, role: "KHAC" },
      { index: 1, role: "DIEM", group: "TX", order: 1 },
    ],
  });
  bad({
    name: "ok",
    columns: [
      { index: 0, role: "HO_TEN" },
      { index: 1, role: "DIEM", group: "ZZ", order: 1 },
    ],
  });
  bad({
    name: "ok",
    columns: [
      { index: 0, role: "HO_TEN" },
      { index: 1.5, role: "DIEM", group: "TX", order: 1 },
    ],
  });
});

test("reading mode is derived from the paired written column", () => {
  const columns = valid();
  assert.equal(readsBothChannels(columns, 2), true);
  assert.equal(readsBothChannels(columns, 4), false);
});

test("recognition columns carry stable keys and written pairing", () => {
  assert.deepEqual(recognitionColumns(valid()), [
    { index: 0, role: "STT" },
    { index: 1, role: "HO_TEN" },
    { index: 2, role: "DIEM", key: "TX1", writtenIndex: 3 },
    { index: 3, role: "DIEM_CHU" },
    { index: 4, role: "DIEM", key: "GK1", writtenIndex: null },
  ]);
  assert.equal(gradeKey("CK", 2), "CK2");
});

test("(group, order) maps to the n-th component of the group by display order", () => {
  const columns: TemplateColumn[] = [
    col(0, "HO_TEN"),
    col(1, "DIEM", { group: "TX", order: 1 }),
    col(2, "DIEM", { group: "TX", order: 2 }),
    col(3, "DIEM", { group: "TX", order: 3 }),
    col(4, "DIEM_CHU", { pairedWith: 2 }),
    col(5, "DIEM", { group: "GK", order: 1 }),
    col(6, "DIEM", { group: "CK", order: 1 }),
  ];
  // Id không theo thứ tự hiển thị: thứ tự phải theo displayOrder rồi id.
  const components = [
    { id: 30, group: "CK", displayOrder: 6 },
    { id: 12, group: "TX", displayOrder: 2 },
    { id: 11, group: "TX", displayOrder: 1 },
    { id: 20, group: "GK", displayOrder: 5 },
    { id: 13, group: "TX", displayOrder: 2 },
  ];
  assert.deepEqual(
    mapColumnsToComponents(columns, components).map((item) => [
      item.templateColumnIndex,
      item.key,
      item.readMode,
      item.componentId,
    ]),
    [
      [1, "TX1", "CHI_SO", 11],
      [2, "TX2", "SO_VA_CHU", 12],
      // Hai thành phần cùng displayOrder 2 xếp theo id: 12 rồi 13.
      [3, "TX3", "CHI_SO", 13],
      [5, "GK1", "CHI_SO", 20],
      [6, "CK1", "CHI_SO", 30],
    ],
  );
  // Môn thiếu thành phần tương ứng: không ánh xạ được (null), không đoán sang thành phần khác.
  const missing = mapColumnsToComponents(columns, [
    { id: 11, group: "TX", displayOrder: 1 },
  ]);
  assert.deepEqual(
    missing.map((item) => item.componentId),
    [11, null, null, null, null],
  );
});
