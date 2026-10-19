import assert from "node:assert/strict";
import { test } from "node:test";
import {
  BadRequestException,
  ForbiddenException,
  UnauthorizedException,
} from "@nestjs/common";
import type { Actor } from "../src/modules/authorization/application/policy.js";
import { FormTemplateMappingService } from "../src/modules/form-templates/application/mapping-service.js";
import type {
  FormTemplateMappingStore,
  MappingContext,
} from "../src/modules/form-templates/application/port.js";
import { TemplateException } from "../src/modules/form-templates/application/errors.js";
import type { TemplateColumn } from "../src/modules/form-templates/public.js";

// GET gradebooks/:id/form-templates/:templateId/mapping (ADR-0016 mục 4): gợi ý ánh xạ cột -> thành phần, dữ liệu giả.
const teacher: Actor = {
  id: 7,
  username: "giaovien_gia",
  role: "GIAO_VIEN",
  sessionHash: "a".repeat(64),
};

const column = (
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

// STT | Họ tên | TX1 số | TX1 chữ | TX2 số (một kênh) | GK1 số (môn không có thành phần GK)
const columns: TemplateColumn[] = [
  column(0, "STT"),
  column(1, "HO_TEN"),
  column(2, "DIEM", { group: "TX", order: 1 }),
  column(3, "DIEM_CHU", { pairedWith: 2 }),
  column(4, "DIEM", { group: "TX", order: 2 }),
  column(5, "DIEM", { group: "GK", order: 1 }),
];

function context(overrides: Partial<MappingContext> = {}): MappingContext {
  return {
    gradebookId: 9,
    templateId: 3,
    templateStatus: "DANG_DUNG",
    columns,
    components: [
      // Thứ tự khai báo ngược với thứ tự hiển thị: ánh xạ phải theo thu_tu_hien_thi, rồi mã thành phần.
      {
        id: 22,
        name: "Thường xuyên 2",
        group: "TX",
        displayOrder: 2,
        locked: true,
        pending: false,
      },
      {
        id: 21,
        name: "Thường xuyên 1",
        group: "TX",
        displayOrder: 1,
        locked: false,
        pending: true,
      },
    ],
    ...overrides,
  };
}

function service(value: MappingContext | null) {
  const calls: Array<[number, number]> = [];
  const store: FormTemplateMappingStore = {
    mappingContext: async (_actor, gradebookId, templateId) => {
      calls.push([gradebookId, templateId]);
      return value;
    },
  };
  return { service: new FormTemplateMappingService(store), calls };
}

test("each grade column maps to the component at its (group, order) with lock, pending and channel flags", async () => {
  const { service: mapping, calls } = service(context());
  const result = await mapping.mapping(teacher, "9", "3");
  assert.deepEqual(calls, [[9, 3]]);
  assert.equal(result.gradebookId, 9);
  assert.equal(result.templateId, 3);
  assert.deepEqual(result.items, [
    {
      templateColumnIndex: 2,
      key: "TX1",
      group: "TX",
      order: 1,
      channels: "SO_CHU",
      componentId: 21,
      componentName: "Thường xuyên 1",
      locked: false,
      pending: true,
    },
    {
      templateColumnIndex: 4,
      key: "TX2",
      group: "TX",
      order: 2,
      channels: "SO",
      componentId: 22,
      componentName: "Thường xuyên 2",
      locked: true,
      pending: false,
    },
    {
      // Môn không có thành phần GK: không ánh xạ được, giáo viên không chọn.
      templateColumnIndex: 5,
      key: "GK1",
      group: "GK",
      order: 1,
      channels: "SO",
      componentId: null,
      componentName: null,
      locked: false,
      pending: false,
    },
  ]);
});

test("students, anonymous callers and malformed ids are rejected before any data is read", async () => {
  const { service: mapping, calls } = service(context());
  await assert.rejects(
    mapping.mapping({ ...teacher, role: "HOC_SINH" }, "9", "3"),
    ForbiddenException,
  );
  await assert.rejects(
    mapping.mapping(undefined, "9", "3"),
    UnauthorizedException,
  );
  for (const [gradebook, template] of [
    ["0", "3"],
    ["9", "x"],
    ["9", "-1"],
    ["9", "99999999999"],
    [undefined, "3"],
  ])
    await assert.rejects(
      mapping.mapping(teacher, gradebook, template),
      BadRequestException,
      `${gradebook}/${template}`,
    );
  assert.equal(calls.length, 0);
});

test("an unknown template is TEMPLATE_NOT_FOUND and a template that is not in use is TEMPLATE_INACTIVE", async () => {
  await assert.rejects(
    service(null).service.mapping(teacher, "9", "3"),
    (error: unknown) =>
      error instanceof TemplateException &&
      error.code === "TEMPLATE_NOT_FOUND" &&
      error.getStatus() === 404,
  );
  for (const templateStatus of ["NHAP", "NGUNG"] as const)
    await assert.rejects(
      service(context({ templateStatus })).service.mapping(teacher, "9", "3"),
      (error: unknown) =>
        error instanceof TemplateException &&
        error.code === "TEMPLATE_INACTIVE" &&
        error.getStatus() === 409,
      templateStatus,
    );
});
