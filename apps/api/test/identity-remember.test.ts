import { test } from "node:test";
import assert from "node:assert/strict";
import { BadRequestException, UnauthorizedException } from "@nestjs/common";
import type { Row, Store, Table, Unit } from "../src/common/store.js";
import { IdentityService } from "../src/modules/identity/application/service.js";
import type { Actor } from "../src/modules/authorization/application/policy.js";

class MemoryStore implements Store {
  tables = new Map<Table, Row[]>();
  private nextUser = 1;
  rows(table: Table): Row[] {
    if (!this.tables.has(table)) this.tables.set(table, []);
    return this.tables.get(table)!;
  }
  private match(row: Row, where: Row) {
    return Object.entries(where).every(([k, v]) => {
      if (v && typeof v === "object" && !(v instanceof Date)) {
        const range = v as Row;
        if ("lt" in range) return +(row[k] as Date) < +(range.lt as Date);
        return true;
      }
      return row[k] === v;
    });
  }
  async run<T>(work: (unit: Unit) => Promise<T>): Promise<T> {
    const unit: Unit = {
      find: async (table, where) =>
        this.rows(table).find((r) => this.match(r, where)) ?? null,
      list: async (table, where) =>
        this.rows(table).filter((r) => this.match(r, where)),
      count: async (table, where) =>
        this.rows(table).filter((r) => this.match(r, where)).length,
      create: async (table, data) => {
        const row: Row = { ...data };
        if (table === "nguoi_dung") {
          row.ma_nguoi_dung = this.nextUser++;
          row.trang_thai ??= true;
          row.so_lan_dang_nhap_sai ??= 0;
          row.khoa_den ??= null;
        }
        this.rows(table).push(row);
        return row;
      },
      update: async (table, where, data) => {
        const row = this.rows(table).find((r) => this.match(r, where))!;
        Object.assign(row, data);
        return row;
      },
      updateMany: async (table, where, data) => {
        const found = this.rows(table).filter((r) => this.match(r, where));
        found.forEach((r) => Object.assign(r, data));
        return found.length;
      },
      remove: async (table, where) => {
        this.tables.set(
          table,
          this.rows(table).filter((r) => !this.match(r, where)),
        );
      },
    };
    return work(unit);
  }
}

const password = "correct-horse-battery";

async function setup() {
  const store = new MemoryStore();
  const service = new IdentityService(store);
  await store.run(async (tx) => {
    await tx.create("nguoi_dung", {
      ten_dang_nhap: "admin",
      mat_khau_ma_hoa: "x",
      vai_tro: "QUAN_TRI_VIEN",
    });
  });
  const now = new Date();
  store.rows("phien_lam_viec").push({
    ma_bam: "admin-session",
    ma_nguoi_dung: 1,
    csrf: "c",
    het_han: new Date(+now + 3600000),
    hoat_dong_cuoi: now,
  });
  const admin: Actor = {
    id: 1,
    username: "admin",
    role: "QUAN_TRI_VIEN",
    sessionHash: "admin-session",
  };
  const teacher = await service.createAccount(admin, {
    username: "0900000001",
    password,
    role: "GIAO_VIEN",
  });
  return { store, service, admin, teacher };
}

test("chỉ có một quản trị viên duy nhất: không cấp vai trò quản trị cho tài khoản nào", async () => {
  const { service, admin, teacher } = await setup();
  await assert.rejects(
    service.createAccount(admin, {
      username: "admin2",
      password,
      role: "QUAN_TRI_VIEN",
    }),
    BadRequestException,
  );
  await assert.rejects(
    service.importAccounts(admin, [
      { username: "admin3", password, role: "QUAN_TRI_VIEN" },
    ]),
    BadRequestException,
  );
  await assert.rejects(
    service.updateAccount(admin, teacher.id, {
      role: "QUAN_TRI_VIEN",
      active: true,
    }),
    BadRequestException,
  );
});

test("app di động: mã ghi nhớ đổi được phiên mới, dùng một lần và mất khi đăng xuất", async () => {
  const { service, teacher } = await setup();
  const web = await service.login("0900000001", password, "1.1.1.1");
  assert.equal(web.remember, null);

  const first = await service.login("0900000001", password, "1.1.1.1", true);
  assert.match(first.remember!, /^[a-f0-9]{64}$/);

  const resumed = await service.resume(first.remember!);
  assert.notEqual(resumed.token, first.token);
  assert.notEqual(resumed.remember, first.remember);
  assert.equal(resumed.id, teacher.id);

  // Mã cũ đã dùng một lần: không đổi lại được nữa.
  await assert.rejects(service.resume(first.remember!), UnauthorizedException);
  await assert.rejects(service.resume("không-hợp-lệ"), UnauthorizedException);

  // Đăng xuất xóa mọi mã ghi nhớ của tài khoản.
  await service.logout({
    id: teacher.id,
    username: teacher.username,
    role: "GIAO_VIEN",
    sessionHash: "bất-kỳ",
  });
  await assert.rejects(
    service.resume(resumed.remember!),
    UnauthorizedException,
  );
});

test("mã ghi nhớ hết hạn hoặc tài khoản bị khóa thì không đổi được phiên", async () => {
  const { store, service, admin, teacher } = await setup();
  const login = await service.login("0900000001", password, "2.2.2.2", true);
  store.rows("phien_ghi_nho")[0]!.het_han = new Date(Date.now() - 1000);
  await assert.rejects(service.resume(login.remember!), UnauthorizedException);

  const again = await service.login("0900000001", password, "2.2.2.2", true);
  await service.updateAccount(admin, teacher.id, {
    role: "GIAO_VIEN",
    active: false,
  });
  await assert.rejects(service.resume(again.remember!), UnauthorizedException);
});
