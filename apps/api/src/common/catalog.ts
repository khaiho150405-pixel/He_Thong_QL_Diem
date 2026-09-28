import {
  BadRequestException,
  ConflictException,
  NotFoundException,
} from "@nestjs/common";
import type { Row, Store, Table, Unit } from "./store.js";
import {
  administrator,
  currentActor,
  type Actor,
} from "../modules/authorization/application/policy.js";
import { catalogScope } from "../modules/authorization/application/catalog-policy.js";
import { audit } from "../modules/audit/application/write.js";

export interface Field {
  kind: "text" | "int" | "date" | "boolean" | "decimal";
  max?: number;
  nullable?: boolean;
  optional?: boolean;
}
export interface CatalogSpec {
  table: Table;
  id: string;
  fields: Record<string, Field>;
  validate(tx: Unit, data: Row, previous: Row | null): Promise<void>;
}

export interface StudentOrderNumbers {
  school: Map<number, number>;
  byClass: Map<number, number>;
}

const viCollator = new Intl.Collator("vi", { sensitivity: "variant" });

function compareStudentRows(first: Row, second: Row): number {
  const firstName = String(first.ho_ten ?? "").trim();
  const secondName = String(second.ho_ten ?? "").trim();
  const firstGivenName = firstName.split(/\s+/).at(-1) ?? "";
  const secondGivenName = secondName.split(/\s+/).at(-1) ?? "";
  return (
    viCollator.compare(firstGivenName, secondGivenName) ||
    viCollator.compare(firstName, secondName) ||
    Number(first.ma_hoc_sinh) - Number(second.ma_hoc_sinh)
  );
}

export function buildStudentOrderNumbers(students: Row[]): StudentOrderNumbers {
  const school = new Map<number, number>();
  const byClass = new Map<number, number>();
  const sorted = [...students].sort(compareStudentRows);
  sorted.forEach((row, index) =>
    school.set(Number(row.ma_hoc_sinh), index + 1),
  );
  const groups = new Map<number, Row[]>();
  for (const row of students) {
    const classId = Number(row.ma_lop);
    const group = groups.get(classId) ?? [];
    group.push(row);
    groups.set(classId, group);
  }
  for (const group of groups.values()) {
    group
      .sort(compareStudentRows)
      .forEach((row, index) => byClass.set(Number(row.ma_hoc_sinh), index + 1));
  }
  return { school, byClass };
}
export function validateInput(
  input: unknown,
  fields: Record<string, Field>,
): Row {
  if (!input || typeof input !== "object" || Array.isArray(input))
    throw new BadRequestException();
  const raw = input as Row;
  if (Object.keys(raw).some((key) => !(key in fields)))
    throw new BadRequestException();
  const data: Row = {};
  for (const [key, field] of Object.entries(fields)) {
    const value = raw[key];
    if (value === undefined && field.optional) continue;
    if (value == null && field.nullable) {
      data[key] = null;
      continue;
    }
    switch (field.kind) {
      case "text":
        if (
          typeof value !== "string" ||
          !value.trim() ||
          value.length > (field.max ?? 100)
        )
          throw new BadRequestException();
        data[key] = value.trim();
        break;
      case "int":
        if (
          typeof value !== "number" ||
          !Number.isSafeInteger(value) ||
          value < 1 ||
          value > (field.max ?? 2147483647)
        )
          throw new BadRequestException();
        data[key] = value;
        break;
      case "boolean":
        if (typeof value !== "boolean") throw new BadRequestException();
        data[key] = value;
        break;
      case "decimal":
        if (
          typeof value !== "string" ||
          !/^(?:[0-9])\.[0-9]{2}$/.test(value) ||
          Number(value) <= 0
        )
          throw new BadRequestException();
        data[key] = value;
        break;
      case "date":
        if (
          typeof value !== "string" ||
          !/^\d{4}-\d{2}-\d{2}$/.test(value) ||
          !Number.isFinite(+new Date(value)) ||
          new Date(value).toISOString().slice(0, 10) !== value
        )
          throw new BadRequestException();
        data[key] = new Date(value);
        break;
    }
  }
  return data;
}
export class CatalogService {
  constructor(
    private readonly store: Store,
    private readonly spec: CatalogSpec,
  ) {}
  private async output(
    tx: Unit,
    row: Row,
    studentOrders?: StudentOrderNumbers,
  ) {
    const data = Object.fromEntries(
      [this.spec.id, ...Object.keys(this.spec.fields)].map((key) => [
        key,
        row[key] instanceof Date
          ? row[key].toISOString().slice(0, 10)
          : this.spec.fields[key]?.kind === "decimal"
            ? Number(row[key]).toFixed(2)
            : row[key],
      ]),
    );
    const name = String(
      row.ho_ten ??
        row.ten_lop ??
        row.ten_mon ??
        row.ten_thanh_phan ??
        row.ten ??
        "Phân công",
    );
    const parts: string[] = [];
    for (const [key, table, id, label] of [
      ["ma_nam_hoc", "nam_hoc", "ma_nam_hoc", "ten"],
      ["ma_lop", "lop", "ma_lop", "ten_lop"],
      ["ma_mon", "mon_hoc", "ma_mon", "ten_mon"],
      ["ma_hoc_ky", "hoc_ky", "ma_hoc_ky", "ten"],
      ["ma_gv_chu_nhiem", "giao_vien", "ma_giao_vien", "ho_ten"],
    ] as const) {
      if (row[key] && key !== this.spec.id) {
        const related = await tx.find(table, { [id]: row[key] });
        if (related) parts.push(String(related[label]));
      }
    }
    return {
      ...data,
      label: parts.length ? `${name} · ${parts.join(" · ")}` : name,
      ...(this.spec.table === "hoc_sinh"
        ? {
            stt_toan_truong:
              studentOrders?.school.get(Number(row.ma_hoc_sinh)) ?? null,
            stt_lop:
              studentOrders?.byClass.get(Number(row.ma_hoc_sinh)) ?? null,
          }
        : {}),
    };
  }

  private async studentOrderNumbers(
    tx: Unit,
  ): Promise<StudentOrderNumbers | undefined> {
    if (this.spec.table !== "hoc_sinh") return undefined;
    const students = await tx.list(
      "hoc_sinh",
      { dang_theo_hoc: true },
      "ma_hoc_sinh",
      100000,
    );
    return buildStudentOrderNumbers(students);
  }
  async list(actor: Actor, cursor?: string, q?: string) {
    if (q && q.length > 100) throw new BadRequestException();
    if (
      cursor &&
      (!/^[1-9]\d{0,9}$/.test(cursor) || Number(cursor) > 2147483647)
    )
      throw new BadRequestException();
    return this.store.run(async (tx) => {
      const scope = await catalogScope(tx, actor, this.spec.table);
      const rows = await tx.list(
        this.spec.table,
        {
          AND: [
            scope,
            { [this.spec.id]: { gt: Number(cursor ?? 0) } },
            ...(q
              ? [
                  {
                    OR: Object.entries(this.spec.fields)
                      .filter(([, f]) => f.kind === "text")
                      .map(([key]) => ({
                        [key]: { contains: q, mode: "insensitive" },
                      })),
                  },
                ]
              : []),
          ],
        },
        this.spec.id,
      );
      const studentOrders = await this.studentOrderNumbers(tx);
      return {
        items: await Promise.all(
          rows.slice(0, 50).map((row) => this.output(tx, row, studentOrders)),
        ),
        nextCursor: rows.length > 50 ? String(rows[49]![this.spec.id]) : null,
      };
    });
  }
  async save(actor: Actor, input: unknown, id?: number) {
    administrator(actor);
    const data = validateInput(input, this.spec.fields);
    return this.store.run(async (tx) => {
      const previous = id
        ? await tx.find(this.spec.table, { [this.spec.id]: id })
        : null;
      await currentActor(tx, actor);
      if (id && !previous) throw new NotFoundException();
      await this.spec.validate(tx, data, previous);
      const row = id
        ? await tx.update(this.spec.table, { [this.spec.id]: id }, data)
        : await tx.create(this.spec.table, data);
      await audit(
        tx,
        actor.id,
        id ? "CATALOG_UPDATE" : "CATALOG_CREATE",
        `${this.spec.table}:${row[this.spec.id]}`,
      );
      return this.output(tx, row);
    });
  }
  async saveMany(actor: Actor, inputs: unknown[]) {
    administrator(actor);
    if (!Array.isArray(inputs) || inputs.length < 1 || inputs.length > 500)
      throw new BadRequestException("Tệp nhập phải có từ 1 đến 500 dòng.");
    const rows = inputs.map((input) => validateInput(input, this.spec.fields));
    return this.store.run(async (tx) => {
      await currentActor(tx, actor);
      const created: Row[] = [];
      for (const data of rows) {
        await this.spec.validate(tx, data, null);
        const row = await tx.create(this.spec.table, data);
        await audit(
          tx,
          actor.id,
          "CATALOG_IMPORT",
          `${this.spec.table}:${row[this.spec.id]}`,
        );
        created.push(row);
      }
      return {
        imported: created.length,
        items: await Promise.all(created.map((row) => this.output(tx, row))),
      };
    });
  }
  async remove(actor: Actor, id: number) {
    administrator(actor);
    await this.store.run(async (tx) => {
      await currentActor(tx, actor);
      if (!(await tx.find(this.spec.table, { [this.spec.id]: id })))
        throw new NotFoundException();
      const row = await tx.find(this.spec.table, { [this.spec.id]: id });
      const used = await this.isUsed(tx, row!);
      if (used)
        throw new ConflictException(
          "Không thể xóa vì dữ liệu này đang được sử dụng ở nơi khác.",
        );
      await tx.remove(this.spec.table, { [this.spec.id]: id });
      await audit(tx, actor.id, "CATALOG_DELETE", `${this.spec.table}:${id}`);
    });
  }

  private async isUsed(tx: Unit, row: Row): Promise<boolean> {
    const any = async (checks: Array<[Table, Record<string, unknown>]>) => {
      for (const [table, where] of checks) {
        if (await tx.count(table, where)) return true;
      }
      return false;
    };
    switch (this.spec.table) {
      case "nam_hoc":
        return any([
          ["hoc_ky", { ma_nam_hoc: row.ma_nam_hoc }],
          ["lop", { ma_nam_hoc: row.ma_nam_hoc }],
        ]);
      case "hoc_ky":
        return any([
          ["phan_cong_giang_day", { ma_hoc_ky: row.ma_hoc_ky }],
          ["bang_diem", { ma_hoc_ky: row.ma_hoc_ky }],
          ["ket_qua_tong_ket", { ma_hoc_ky: row.ma_hoc_ky }],
          ["thoi_khoa_bieu", { ma_hoc_ky: row.ma_hoc_ky }],
        ]);
      case "lop":
        return any([
          ["hoc_sinh", { ma_lop: row.ma_lop }],
          ["phan_cong_giang_day", { ma_lop: row.ma_lop }],
          ["bang_diem", { ma_lop: row.ma_lop }],
          ["thoi_khoa_bieu", { ma_lop: row.ma_lop }],
        ]);
      case "mon_hoc":
        return any([
          ["thanh_phan_diem", { ma_mon: row.ma_mon }],
          ["phan_cong_giang_day", { ma_mon: row.ma_mon }],
          ["bang_diem", { ma_mon: row.ma_mon }],
          ["ket_qua_tong_ket", { ma_mon: row.ma_mon }],
          ["thoi_khoa_bieu", { ma_mon: row.ma_mon }],
        ]);
      case "giao_vien":
        return any([
          ["lop", { ma_gv_chu_nhiem: row.ma_giao_vien }],
          ["phan_cong_giang_day", { ma_giao_vien: row.ma_giao_vien }],
          ["thoi_khoa_bieu", { ma_giao_vien: row.ma_giao_vien }],
        ]);
      case "hoc_sinh":
        return any([
          ["diem_thanh_phan", { ma_hoc_sinh: row.ma_hoc_sinh }],
          ["ket_qua_tong_ket", { ma_hoc_sinh: row.ma_hoc_sinh }],
          ["ket_qua_dong", { ma_hoc_sinh: row.ma_hoc_sinh }],
        ]);
      case "thanh_phan_diem":
        return any([
          ["diem_thanh_phan", { ma_thanh_phan: row.ma_thanh_phan }],
          ["phieu_nhan_dien", { ma_thanh_phan: row.ma_thanh_phan }],
        ]);
      case "phan_cong_giang_day":
        return any([
          [
            "bang_diem",
            {
              ma_lop: row.ma_lop,
              ma_mon: row.ma_mon,
              ma_hoc_ky: row.ma_hoc_ky,
            },
          ],
          [
            "thoi_khoa_bieu",
            {
              ma_lop: row.ma_lop,
              ma_mon: row.ma_mon,
              ma_hoc_ky: row.ma_hoc_ky,
            },
          ],
        ]);
      default:
        return false;
    }
  }
}
