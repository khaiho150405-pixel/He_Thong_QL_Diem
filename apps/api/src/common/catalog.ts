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
}
export interface CatalogSpec {
  table: Table;
  id: string;
  fields: Record<string, Field>;
  validate(tx: Unit, data: Row, previous: Row | null): Promise<void>;
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
  private async output(tx: Unit, row: Row) {
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
    };
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
      return {
        items: await Promise.all(
          rows.slice(0, 50).map((row) => this.output(tx, row)),
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
  async remove(actor: Actor, id: number) {
    administrator(actor);
    await this.store.run(async (tx) => {
      await currentActor(tx, actor);
      if (!(await tx.find(this.spec.table, { [this.spec.id]: id })))
        throw new NotFoundException();
      // Foreign keys use RESTRICT, preserving every referenced business record.
      if (this.spec.table === "hoc_sinh") throw new ConflictException();
      if (this.spec.table === "thanh_phan_diem") {
        const row = await tx.find(this.spec.table, { [this.spec.id]: id });
        if (await tx.count("bang_diem", { ma_mon: row!.ma_mon }))
          throw new ConflictException();
      }
      await tx.remove(this.spec.table, { [this.spec.id]: id });
      await audit(tx, actor.id, "CATALOG_DELETE", `${this.spec.table}:${id}`);
    });
  }
}
