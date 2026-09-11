import { Inject, Injectable } from "@nestjs/common";
import type { PrismaClient, Prisma } from "../generated/prisma/client.js";
import { transaction } from "./transaction.js";

export type Row = Record<string, unknown>;
export type Table =
  | "nguoi_dung"
  | "phien_lam_viec"
  | "nhat_ky_bao_mat"
  | "gioi_han_dang_nhap"
  | "nam_hoc"
  | "hoc_ky"
  | "lop"
  | "hoc_sinh"
  | "mon_hoc"
  | "thanh_phan_diem"
  | "giao_vien"
  | "phan_cong_giang_day"
  | "bang_diem"
  | "diem_thanh_phan"
  | "khoa_idempotency";
export interface Unit {
  find(table: Table, where: Row): Promise<Row | null>;
  list(table: Table, where: Row, order: string, limit?: number): Promise<Row[]>;
  count(table: Table, where: Row): Promise<number>;
  create(table: Table, data: Row): Promise<Row>;
  update(table: Table, where: Row, data: Row): Promise<Row>;
  remove(table: Table, where: Row): Promise<void>;
}
export interface Store {
  run<T>(work: (unit: Unit) => Promise<T>): Promise<T>;
}
export const STORE = Symbol("STORE");
interface Delegate {
  findFirst(args: Row): Promise<Row | null>;
  findMany(args: Row): Promise<Row[]>;
  count(args: Row): Promise<number>;
  create(args: Row): Promise<Row>;
  update(args: Row): Promise<Row>;
  deleteMany(args: Row): Promise<unknown>;
}
export function unit(tx: Prisma.TransactionClient): Unit {
  const delegate = (table: Table) => tx[table] as unknown as Delegate;
  return {
    find: (table, where) => delegate(table).findFirst({ where }),
    list: (table, where, order, limit = 51) =>
      delegate(table).findMany({
        where,
        orderBy: { [order]: "asc" },
        take: limit,
      }),
    count: (table, where) => delegate(table).count({ where }),
    create: (table, data) => delegate(table).create({ data }),
    update: (table, where, data) => delegate(table).update({ where, data }),
    remove: async (table, where) => {
      await delegate(table).deleteMany({ where });
    },
  };
}
@Injectable()
export class PrismaStore implements Store {
  constructor(@Inject("DATABASE") private readonly db: PrismaClient) {}
  run<T>(work: (unit: Unit) => Promise<T>): Promise<T> {
    return transaction(this.db, (tx) => work(unit(tx)));
  }
}
