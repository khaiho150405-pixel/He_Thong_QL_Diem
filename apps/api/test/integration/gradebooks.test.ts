import { test } from "node:test";
import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { Pool } from "pg";
import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  UnauthorizedException,
} from "@nestjs/common";
import { createApp } from "../../src/app.js";
import type {
  Actor,
  Role,
} from "../../src/modules/authorization/application/policy.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import {
  GRADEBOOK_STORE,
  type GradebookStore,
} from "../../src/modules/gradebooks/application/port.js";

test("UC09 part 1: PostgreSQL grid, scope, idempotency, pagination, rollback and least privilege", async () => {
  const ownerUrl = process.env.TEST_MIGRATION_URL;
  const runtimeUrl = process.env.TEST_RUNTIME_URL;
  if (
    !ownerUrl ||
    !runtimeUrl ||
    !new URL(ownerUrl).pathname.endsWith("_test") ||
    !new URL(runtimeUrl).pathname.endsWith("_test")
  )
    throw new Error("Explicit isolated test URLs required");
  const owner = new Pool({ connectionString: ownerUrl });
  const runtime = new Pool({ connectionString: runtimeUrl });
  const app = await createApp(
    { environment: "development", origins: [], databaseUrl: runtimeUrl },
    { check: async () => true, close: async () => {} },
  );
  await app.init();
  const service = app.get(GradebooksService);
  const store = app.get<GradebookStore>(GRADEBOOK_STORE);
  const suffix = randomBytes(5).toString("hex");
  const makeActor = async (role: Role): Promise<Actor> => {
    const username = `grid_${role}_${suffix}`;
    const { rows } = await owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only-no-login',$2) RETURNING ma_nguoi_dung",
      [username, role],
    );
    const id: number = rows[0].ma_nguoi_dung;
    const sessionHash = randomBytes(32).toString("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, id, randomBytes(32).toString("hex")],
    );
    return { id, username, role, sessionHash };
  };
  try {
    const teacher = await makeActor("GIAO_VIEN");
    const admin = await makeActor("QUAN_TRI_VIEN");
    const student = await makeActor("HOC_SINH");
    const other = { ...teacher, id: teacher.id + 1000000 };
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Giáo viên giả')",
      [teacher.id],
    );
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        [`G-${suffix}`],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ giả',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,'Lớp giả',10) RETURNING ma_lop",
        [year, teacher.id],
      )
    ).rows[0].ma_lop;
    // 26 students x 2 components exercises a 50-cell cursor boundary. Inactive excluded at creation.
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh,dang_theo_hoc) SELECT $1,'Học sinh giả ' || n,'2010-01-01',n<=26 FROM generate_series(1,27) n",
      [cls],
    );
    const makeSubject = async (
      tag: string,
      components = true,
      termId = term,
    ) => {
      const subjectId: number = (
        await owner.query(
          "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,3) RETURNING ma_mon",
          [`Môn giả ${tag} ${suffix}`],
        )
      ).rows[0].ma_mon;
      if (components)
        await owner.query(
          "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Thường xuyên',1.00,1),($1,'Cuối kỳ',2.00,2)",
          [subjectId],
        );
      await owner.query(
        "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
        [teacher.id, cls, subjectId, termId],
      );
      return { classId: cls as number, subjectId, termId: termId as number };
    };
    const scope = await makeSubject("main");
    await assert.rejects(service.create(admin, scope), ForbiddenException);
    await assert.rejects(service.create(student, scope), ForbiddenException);
    await assert.rejects(service.create(other, scope), UnauthorizedException);
    for (const input of [
      { ...scope, value: 0 },
      { ...scope, classId: 0 },
      { ...scope, subjectId: "1" },
    ])
      assert.throws(() => service.create(teacher, input), BadRequestException);

    const created = await service.create(teacher, scope);
    assert.equal(created.status, "DANG_NHAP_LIEU");
    assert.equal(created.version, 0);
    assert.deepEqual(await service.create(teacher, scope), created);
    const first = await service.cells(teacher, created.id);
    assert.equal(first.items.length, 50);
    assert.ok(first.nextCursor);
    const second = await service.cells(
      teacher,
      created.id,
      String(first.nextCursor),
    );
    assert.equal(second.items.length, 2);
    assert.equal(second.nextCursor, null);
    const cells = [...first.items, ...second.items];
    assert.equal(new Set(cells.map((c) => c.id)).size, 52);
    assert.ok(
      cells.every(
        (c) =>
          c.value === null &&
          c.status === "CHUA_CO" &&
          c.source === "NHAP_TAY" &&
          c.active,
      ),
    );
    assert.ok(cells.every((c) => ["1.00", "2.00"].includes(c.coefficient)));
    assert.doesNotThrow(() => JSON.stringify(first));
    assert.equal((await service.cells(admin, created.id)).items.length, 50);
    await assert.rejects(
      service.cells(student, created.id),
      ForbiddenException,
    );
    assert.throws(
      () => service.cells(teacher, created.id, "9223372036854775808"),
      BadRequestException,
    );
    assert.throws(() => service.list(teacher, -1), BadRequestException);
    assert.ok(
      (await service.list(teacher)).items.some((b) => b.id === created.id),
    );
    const auditCount = async (bookId: number) =>
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong='GRADEBOOK_CREATED' AND doi_tuong=$1",
            [`bang_diem:${bookId}`],
          )
        ).rows[0].count,
      );
    assert.equal(await auditCount(created.id), 1);
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM lich_su_sua_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1",
            [created.id],
          )
        ).rows[0].count,
      ),
      0,
    );

    // The owner simulates future writes; this phase exposes no runtime grade update capability.
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=0.0,trang_thai='DA_DUYET' WHERE ma_diem=$1",
      [cells[0]!.id],
    );
    await owner.query(
      "UPDATE hoc_sinh SET dang_theo_hoc=false WHERE ma_hoc_sinh=$1",
      [cells[0]!.studentId],
    );
    await owner.query(
      "UPDATE bang_diem SET trang_thai='DA_CHOT',version=1 WHERE ma_bang_diem=$1",
      [created.id],
    );
    assert.equal((await service.create(teacher, scope)).status, "DA_CHOT");
    const retained = (await service.cells(teacher, created.id)).items[0]!;
    assert.equal(retained.value, "0.0");
    assert.equal(retained.active, false);
    assert.equal(await auditCount(created.id), 1);

    const rolledBack = await makeSubject("rollback");
    let rolledId = 0;
    await assert.rejects(
      store.run(async (tx) => {
        rolledId = (await tx.createBlankGrid(teacher.sessionHash, rolledBack))
          .id;
        throw new Error("deliberate rollback");
      }),
      /deliberate rollback/,
    );
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM bang_diem WHERE ma_bang_diem=$1",
            [rolledId],
          )
        ).rows[0].count,
      ),
      0,
    );
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1",
            [rolledId],
          )
        ).rows[0].count,
      ),
      0,
    );
    assert.equal(await auditCount(rolledId), 0);
    const empty = await makeSubject("no-components", false);
    await assert.rejects(service.create(teacher, empty), ConflictException);
    assert.equal(
      Number(
        (
          await owner.query("SELECT count(*) FROM bang_diem WHERE ma_mon=$1", [
            empty.subjectId,
          ])
        ).rows[0].count,
      ),
      0,
    );

    // A second valid teacher with no assignment cannot use a homeroom relationship to gain access.
    const intruderId = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only-no-login','GIAO_VIEN') RETURNING ma_nguoi_dung",
        [`intruder_${suffix}`],
      )
    ).rows[0].ma_nguoi_dung;
    const intruder: Actor = {
      ...teacher,
      id: intruderId,
      sessionHash: randomBytes(32).toString("hex"),
    };
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [intruder.sessionHash, intruder.id, randomBytes(32).toString("hex")],
    );
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'Chủ nhiệm giả')",
      [intruder.id],
    );
    await owner.query("UPDATE lop SET ma_gv_chu_nhiem=$1 WHERE ma_lop=$2", [
      intruder.id,
      cls,
    ]);
    assert.equal((await service.list(intruder)).items.length, 0);
    await assert.rejects(
      service.cells(intruder, created.id),
      ForbiddenException,
    );
    await assert.rejects(service.create(intruder, scope), ForbiddenException);
    await assert.rejects(
      store.run((tx) => tx.createBlankGrid(intruder.sessionHash, scope)),
      ForbiddenException,
    );
    await assert.rejects(
      store.run((tx) => tx.createBlankGrid(admin.sessionHash, scope)),
      ForbiddenException,
    );

    const secondYear = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2027-09-01','2028-06-01') RETURNING ma_nam_hoc",
        [`Y2-${suffix}`],
      )
    ).rows[0].ma_nam_hoc;
    const wrongTerm = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ khác năm',1,'2027-09-01','2028-01-01') RETURNING ma_hoc_ky",
        [secondYear],
      )
    ).rows[0].ma_hoc_ky;
    const inconsistent = await makeSubject("wrong-year", true, wrongTerm);
    await assert.rejects(
      service.create(teacher, inconsistent),
      ConflictException,
    );
    const emptyClass = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,'Lớp rỗng',10) RETURNING ma_lop",
        [year, teacher.id],
      )
    ).rows[0].ma_lop;
    const noRoster = await makeSubject("no-roster");
    await owner.query(
      "UPDATE phan_cong_giang_day SET ma_lop=$1 WHERE ma_mon=$2",
      [emptyClass, noRoster.subjectId],
    );
    await assert.rejects(
      service.create(teacher, { ...noRoster, classId: emptyClass }),
      ConflictException,
    );

    const concurrent = await makeSubject("concurrent");
    const attempts = await Promise.allSettled([
      service.create(teacher, concurrent),
      service.create(teacher, concurrent),
    ]);
    assert.ok(attempts.some((r) => r.status === "fulfilled"));
    for (const r of attempts)
      if (r.status === "rejected")
        assert.ok(r.reason instanceof ConflictException);
    const converged = await service.create(teacher, concurrent);
    assert.equal(await auditCount(converged.id), 1);
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1",
            [converged.id],
          )
        ).rows[0].count,
      ),
      50,
    );

    const denied = (sql: string) =>
      assert.rejects(
        runtime.query(sql),
        (e: { code?: string }) => e.code === "42501",
      );
    await denied(
      "INSERT INTO bang_diem(ma_lop,ma_mon,ma_hoc_ky) VALUES(1,1,1)",
    );
    await denied(
      "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) VALUES(1,1,1)",
    );
    await denied("UPDATE diem_thanh_phan SET gia_tri=8.55");
    await denied("DELETE FROM diem_thanh_phan");
    await denied("UPDATE bang_diem SET trang_thai='DANG_NHAP_LIEU'");
    for (const sql of [
      "UPDATE lich_su_sua_diem SET ly_do=ly_do",
      "DELETE FROM lich_su_sua_diem",
      "TRUNCATE lich_su_sua_diem",
    ])
      await denied(sql);
    await assert.rejects(
      runtime.query("SELECT * FROM tao_luoi_diem_trong($1,$2,$3,$4)", [
        teacher.sessionHash,
        cls,
        scope.subjectId,
        term,
      ]),
      (e: { code?: string }) => e.code === "25001",
    );
    const functionSecurity = (
      await owner.query(
        `SELECT p.prosecdef, p.proconfig,
        EXISTS(SELECT 1 FROM aclexplode(p.proacl) a WHERE a.grantee=0 AND a.privilege_type='EXECUTE') AS public_execute
      FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
      WHERE n.nspname='public' AND p.proname='tao_luoi_diem_trong'`,
      )
    ).rows[0];
    assert.equal(functionSecurity.prosecdef, true);
    assert.equal(functionSecurity.public_execute, false);
    assert.deepEqual(functionSecurity.proconfig, ["search_path=pg_catalog"]);
    await owner.query(
      "UPDATE phien_lam_viec SET hoat_dong_cuoi=now()-interval '31 minutes' WHERE ma_bam=$1",
      [teacher.sessionHash],
    );
    await assert.rejects(service.create(teacher, scope), UnauthorizedException);
    await assert.rejects(
      store.run((tx) => tx.createBlankGrid(teacher.sessionHash, scope)),
      ForbiddenException,
    );
    await owner.query(
      "UPDATE phien_lam_viec SET hoat_dong_cuoi=now() WHERE ma_bam=$1",
      [teacher.sessionHash],
    );
    await owner.query(
      "UPDATE nguoi_dung SET trang_thai=false WHERE ma_nguoi_dung=$1",
      [teacher.id],
    );
    await assert.rejects(service.list(teacher), UnauthorizedException);
    await assert.rejects(
      store.run((tx) => tx.createBlankGrid(teacher.sessionHash, scope)),
      ForbiddenException,
    );
    await owner.query(
      "UPDATE nguoi_dung SET trang_thai=true WHERE ma_nguoi_dung=$1",
      [teacher.id],
    );
    await owner.query("DELETE FROM phan_cong_giang_day WHERE ma_giao_vien=$1", [
      teacher.id,
    ]);
    await assert.rejects(
      service.cells(teacher, created.id),
      ForbiddenException,
    );
    await assert.rejects(service.create(teacher, scope), ForbiddenException);
    await owner.query("DELETE FROM phien_lam_viec WHERE ma_bam=$1", [
      teacher.sessionHash,
    ]);
    await assert.rejects(service.list(teacher), UnauthorizedException);
  } finally {
    await app.close();
    await owner.end();
    await runtime.end();
  }
});
