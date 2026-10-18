import assert from "node:assert/strict";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import { test } from "node:test";
import { createRosterFixture } from "../../apps/api/test/integration/roster-fixture.js";

// Mẫu bảng điểm (ADR-0016, migration 202610190001): ràng buộc bảng, quyền runtime, hàm luu_mau_bang_diem /
// doi_trang_thai_mau_bang_diem, chặn sửa mẫu đã có phiếu tham chiếu. Dữ liệu hoàn toàn giả; chỉ chạy trên DB *_test.

type Failure = { code?: string; message?: string };
type Col = {
  index: number;
  role: string;
  group?: string | null;
  order?: number | null;
  pairedWith?: number | null;
  headerText?: string | null;
};

const failsWith = (code: string, text: string) => (error: Failure) =>
  error.code === code && String(error.message).includes(text);

const col = (index: number, role: string, extra: Partial<Col> = {}): Col => ({
  index,
  role,
  ...extra,
});

// STT | Họ tên | TX1 số | TX1 chữ | GK1 số | Ghi chú
const validColumns = (): Col[] => [
  col(0, "STT"),
  col(1, "HO_TEN"),
  col(2, "DIEM", { group: "TX", order: 1 }),
  col(3, "DIEM_CHU", { pairedWith: 2 }),
  col(4, "DIEM", { group: "GK", order: 1 }),
  col(5, "BO_QUA"),
];

const signature = (count = 6) => ({
  version: 1,
  columnWidths: Array.from({ length: count }, () => 1 / count),
  headerTexts: Array.from({ length: count }, () => ""),
  headerRows: 1,
  rowHeightMm: 8,
  tableWidthMm: 180,
});

async function setup() {
  const f = await createRosterFixture();
  const suffix = randomBytes(5).toString("hex");
  const makeAdmin = async () => {
    const id: number = (
      await f.owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','QUAN_TRI_VIEN') RETURNING ma_nguoi_dung",
        [`tmpl_admin_${suffix}`],
      )
    ).rows[0].ma_nguoi_dung;
    const session = createHash("sha256").update(randomBytes(32)).digest("hex");
    await f.owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [session, id, randomBytes(32).toString("hex")],
    );
    return { id, session };
  };
  const admin = await makeAdmin();

  const save = (
    mode: "TAO" | "SUA" | "PHIEN_BAN",
    options: {
      session?: string;
      templateId?: number | null;
      expectedVersion?: number | null;
      name?: string;
      description?: string | null;
      columns?: Col[];
      signatureCount?: number;
    } = {},
  ) =>
    f.serializable(async (query) => {
      const creating = mode === "TAO";
      return (
        await query(
          "SELECT public.luu_mau_bang_diem($1,$2,$3::integer,$4::integer,$5,$6,$7::jsonb,$8::jsonb,$9,$10) AS result",
          [
            options.session ?? admin.session,
            mode,
            options.templateId ?? null,
            options.expectedVersion ?? null,
            options.name ?? "Mẫu giả",
            options.description ?? null,
            JSON.stringify(options.columns ?? validColumns()),
            creating ? JSON.stringify(signature(options.signatureCount)) : null,
            creating ? `form-templates/${randomUUID()}.png` : null,
            creating ? randomBytes(32).toString("hex") : null,
          ],
        )
      ).rows[0].result as { templateId: number; storedObjectKey: string };
    });

  const create = (options: Parameters<typeof save>[1] = {}) =>
    save("TAO", options);

  const changeStatus = (
    id: number,
    version: number,
    status: string,
    session = admin.session,
  ) =>
    f.serializable(
      async (query) =>
        (
          await query(
            "SELECT public.doi_trang_thai_mau_bang_diem($1,$2,$3,$4) AS result",
            [session, id, version, status],
          )
        ).rows[0].result,
    );

  const row = async (id: number) =>
    (
      await f.owner.query(
        `SELECT ma_mau, trang_thai::text AS status, phien_ban, ma_mau_goc, version, ten_mau
         FROM mau_bang_diem WHERE ma_mau=$1`,
        [id],
      )
    ).rows[0];
  const columnCount = async (id: number) =>
    Number(
      (
        await f.owner.query("SELECT count(*) FROM cot_mau WHERE ma_mau=$1", [
          id,
        ])
      ).rows[0].count,
    );
  const templateTotal = async () =>
    Number(
      (await f.owner.query("SELECT count(*) FROM mau_bang_diem")).rows[0].count,
    );
  const useByTicket = async (templateId: number) => {
    const ticket = await f.createTicket(
      f.valid,
      `tmpl-${randomBytes(6).toString("hex")}`,
    );
    // P3 sẽ ghi cột này khi tạo phiếu theo mẫu; ở đây mô phỏng bằng chủ sở hữu bảng.
    await f.owner.query(
      "UPDATE phieu_nhan_dien SET ma_mau=$1 WHERE ma_phieu=$2",
      [templateId, ticket.ticketId],
    );
  };
  return {
    f,
    admin,
    makeAdmin,
    save,
    create,
    changeStatus,
    row,
    columnCount,
    templateTotal,
    useByTicket,
  };
}

test("create stores a draft with every column and an audit event", async () => {
  const t = await setup();
  try {
    const before = Number(
      (
        await t.f.owner.query(
          "SELECT count(*) FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong='FORM_TEMPLATE_CREATED'",
          [t.admin.id],
        )
      ).rows[0].count,
    );
    const created = await t.create({ name: "  Mẫu giả A  " });
    assert.match(
      created.storedObjectKey,
      /^form-templates\/[0-9a-f-]{36}\.png$/,
    );
    const stored = await t.row(created.templateId);
    assert.equal(stored.status, "NHAP");
    assert.equal(stored.phien_ban, 1);
    assert.equal(stored.ma_mau_goc, null);
    assert.equal(stored.version, 0);
    assert.equal(stored.ten_mau, "Mẫu giả A");
    assert.equal(await t.columnCount(created.templateId), 6);
    const pairs = (
      await t.f.owner.query(
        "SELECT chi_so_cot, vai_tro::text AS role, loai_he_so, thu_tu_trong_nhom, cot_diem_di_kem FROM cot_mau WHERE ma_mau=$1 ORDER BY chi_so_cot",
        [created.templateId],
      )
    ).rows;
    assert.deepEqual(
      pairs.map((r) => [
        r.chi_so_cot,
        r.role,
        r.loai_he_so,
        r.thu_tu_trong_nhom,
        r.cot_diem_di_kem,
      ]),
      [
        [0, "STT", null, null, null],
        [1, "HO_TEN", null, null, null],
        [2, "DIEM", "TX", 1, null],
        [3, "DIEM_CHU", null, null, 2],
        [4, "DIEM", "GK", 1, null],
        [5, "BO_QUA", null, null, null],
      ],
    );
    const after = Number(
      (
        await t.f.owner.query(
          "SELECT count(*) FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong='FORM_TEMPLATE_CREATED'",
          [t.admin.id],
        )
      ).rows[0].count,
    );
    assert.equal(after, before + 1);
  } finally {
    await t.f.close();
  }
});

test("luu_mau_bang_diem rejects every invalid definition and rolls back", async () => {
  const t = await setup();
  try {
    const base = validColumns();
    const cases: Array<[string, Col[], string?, number?]> = [
      [
        "no HO_TEN",
        base.map((c) => (c.role === "HO_TEN" ? col(1, "BO_QUA") : c)),
        "HO_TEN",
      ],
      [
        "two HO_TEN",
        base.map((c) => (c.index === 5 ? col(5, "HO_TEN") : c)),
        "HO_TEN",
      ],
      ["two STT", base.map((c) => (c.index === 5 ? col(5, "STT") : c)), "STT"],
      [
        "no DIEM",
        [col(0, "STT"), col(1, "HO_TEN"), col(2, "BO_QUA")],
        "KHONG_CO_DIEM",
        3,
      ],
      [
        "duplicate (group, order)",
        base.map((c) =>
          c.index === 4 ? col(4, "DIEM", { group: "TX", order: 1 }) : c,
        ),
        "NHOM_THU_TU_TRUNG",
      ],
      [
        "DIEM_CHU pointing at a non-DIEM column",
        base.map((c) =>
          c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 1 }) : c,
        ),
        "DIEM_CHU_DI_KEM",
      ],
      [
        "DIEM_CHU pointing at a missing column",
        base.map((c) =>
          c.index === 3 ? col(3, "DIEM_CHU", { pairedWith: 30 }) : c,
        ),
        "DIEM_CHU_DI_KEM",
      ],
      [
        "two DIEM_CHU for one DIEM",
        base.map((c) =>
          c.index === 5 ? col(5, "DIEM_CHU", { pairedWith: 2 }) : c,
        ),
        "DIEM_CHU_DI_KEM",
      ],
      [
        "DIEM without group",
        base.map((c) => (c.index === 4 ? col(4, "DIEM", { order: 1 }) : c)),
        "DIEM",
      ],
      [
        "DIEM_CHU without pairing",
        base.map((c) => (c.index === 3 ? col(3, "DIEM_CHU") : c)),
        "DIEM_CHU",
      ],
      [
        "BO_QUA carrying a group",
        base.map((c) =>
          c.index === 5 ? col(5, "BO_QUA", { group: "TX" }) : c,
        ),
        "THUA_TRUONG",
      ],
      [
        "duplicate column index",
        base.map((c) => (c.index === 5 ? col(4, "BO_QUA") : c)),
        "CHI_SO_TRUNG",
      ],
      ["column list shorter than the signature", base.slice(0, 5), "SO_COT"],
    ];
    const before = await t.templateTotal();
    for (const [label, columns, reason, count] of cases)
      await assert.rejects(
        t.create({ columns, signatureCount: count }),
        failsWith("23514", `INVALID_TEMPLATE_DEFINITION: ${reason ?? ""}`),
        label,
      );
    // Mỗi lời gọi lỗi rollback toàn bộ: không có mẫu hay cột nào còn lại.
    assert.equal(await t.templateTotal(), before);
  } finally {
    await t.f.close();
  }
});

test("only a live administrator session in a serializable transaction may write", async () => {
  const t = await setup();
  try {
    // Phiên giáo viên (fixture) và phiên không tồn tại đều bị từ chối.
    await assert.rejects(
      t.create({ session: t.f.session }),
      failsWith("42501", "FORBIDDEN"),
    );
    await assert.rejects(
      t.create({ session: "f".repeat(64) }),
      failsWith("42501", "FORBIDDEN"),
    );
    // Phiên QTV đã hết hạn.
    const expired = createHash("sha256").update(randomBytes(32)).digest("hex");
    await t.f.owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()-interval '1 minute',now())",
      [expired, t.admin.id, randomBytes(32).toString("hex")],
    );
    await assert.rejects(
      t.create({ session: expired }),
      failsWith("42501", "FORBIDDEN"),
    );
    // Ngoài giao dịch SERIALIZABLE.
    await assert.rejects(
      t.f.runtime.query(
        "SELECT public.luu_mau_bang_diem($1,'TAO',NULL,NULL,'x',NULL,'[]'::jsonb,'{}'::jsonb,'a','b')",
        [t.admin.session],
      ),
      failsWith("25001", "SERIALIZABLE_REQUIRED"),
    );
    const created = await t.create();
    await assert.rejects(
      t.changeStatus(created.templateId, 0, "DANG_DUNG", t.f.session),
      failsWith("42501", "FORBIDDEN"),
    );
  } finally {
    await t.f.close();
  }
});

test("update in place bumps the version and replaces the columns", async () => {
  const t = await setup();
  try {
    const { templateId } = await t.create();
    const edited = validColumns().map((c) =>
      c.index === 4 ? col(4, "DIEM", { group: "CK", order: 1 }) : c,
    );
    await t.save("SUA", {
      templateId,
      expectedVersion: 0,
      name: "Mẫu đổi tên",
      columns: edited,
    });
    const stored = await t.row(templateId);
    assert.equal(stored.version, 1);
    assert.equal(stored.ten_mau, "Mẫu đổi tên");
    const group = (
      await t.f.owner.query(
        "SELECT loai_he_so FROM cot_mau WHERE ma_mau=$1 AND chi_so_cot=4",
        [templateId],
      )
    ).rows[0].loai_he_so;
    assert.equal(group, "CK");
    // Phiên bản cũ của người dùng: xung đột.
    await assert.rejects(
      t.save("SUA", { templateId, expectedVersion: 0 }),
      failsWith("23514", "VERSION_CONFLICT"),
    );
    // Số cột phải khớp chữ ký đã lưu.
    await assert.rejects(
      t.save("SUA", {
        templateId,
        expectedVersion: 1,
        columns: validColumns().slice(0, 5),
      }),
      failsWith("23514", "INVALID_TEMPLATE_DEFINITION: SO_COT"),
    );
    await assert.rejects(
      t.save("SUA", { templateId: 2_000_000_000, expectedVersion: 0 }),
      failsWith("P0002", "TEMPLATE_NOT_FOUND"),
    );
  } finally {
    await t.f.close();
  }
});

test("a template referenced by a ticket cannot be edited in place", async () => {
  const t = await setup();
  try {
    const { templateId } = await t.create();
    await t.useByTicket(templateId);
    await assert.rejects(
      t.save("SUA", { templateId, expectedVersion: 0, name: "Đổi" }),
      failsWith("23514", "TEMPLATE_IN_USE"),
    );
    assert.equal((await t.row(templateId)).ten_mau, "Mẫu giả");
    assert.equal(await t.columnCount(templateId), 6);
    // Trigger chặn cả ghi trực tiếp vào cot_mau của mẫu đã dùng, kể cả chủ sở hữu bảng.
    await assert.rejects(
      t.f.owner.query("DELETE FROM cot_mau WHERE ma_mau=$1 AND chi_so_cot=5", [
        templateId,
      ]),
      failsWith("23514", "TEMPLATE_IN_USE"),
    );
    await assert.rejects(
      t.f.owner.query(
        "UPDATE cot_mau SET nhan_tieu_de='x' WHERE ma_mau=$1 AND chi_so_cot=5",
        [templateId],
      ),
      failsWith("23514", "TEMPLATE_IN_USE"),
    );
    assert.equal(await t.columnCount(templateId), 6);
    // "Sửa" lúc này là tạo phiên bản mới.
    const next = await t.save("PHIEN_BAN", {
      templateId,
      expectedVersion: 0,
      name: "Mẫu giả v2",
    });
    assert.notEqual(next.templateId, templateId);
  } finally {
    await t.f.close();
  }
});

test("a new version retires the old row and keeps one chain", async () => {
  const t = await setup();
  try {
    const first = (await t.create()).templateId;
    await t.changeStatus(first, 0, "DANG_DUNG");
    const second = (
      await t.save("PHIEN_BAN", {
        templateId: first,
        expectedVersion: 1,
        name: "Mẫu giả v2",
      })
    ).templateId;
    const old = await t.row(first);
    const fresh = await t.row(second);
    assert.equal(old.status, "NGUNG");
    assert.equal(old.version, 2);
    assert.equal(fresh.status, "NHAP");
    assert.equal(fresh.phien_ban, 2);
    assert.equal(fresh.ma_mau_goc, first);
    assert.equal(await t.columnCount(second), 6);

    // Chỉ tạo phiên bản từ bản mới nhất của chuỗi.
    await assert.rejects(
      t.save("PHIEN_BAN", { templateId: first, expectedVersion: 2 }),
      failsWith("23514", "VERSION_CONFLICT"),
    );
    const third = (
      await t.save("PHIEN_BAN", {
        templateId: second,
        expectedVersion: 0,
        name: "Mẫu giả v3",
      })
    ).templateId;
    const latest = await t.row(third);
    assert.equal(latest.phien_ban, 3);
    // Bản gốc của chuỗi là bản đầu, không phải bản liền trước.
    assert.equal(latest.ma_mau_goc, first);
    assert.equal((await t.row(second)).status, "NGUNG");
    // Bản cũ đã NGUNG không bật lại được và không sửa tại chỗ được.
    await assert.rejects(
      t.changeStatus(first, 2, "DANG_DUNG"),
      failsWith("23514", "TEMPLATE_INACTIVE"),
    );
    await assert.rejects(
      t.save("SUA", { templateId: first, expectedVersion: 2 }),
      failsWith("23514", "TEMPLATE_INACTIVE"),
    );
    // Bản không mới nhất của chuỗi cũng không kích hoạt được.
    await assert.rejects(
      t.changeStatus(second, 1, "DANG_DUNG"),
      failsWith("23514", "TEMPLATE_INACTIVE"),
    );
  } finally {
    await t.f.close();
  }
});

test("status changes follow NHAP -> DANG_DUNG -> NGUNG with optimistic version", async () => {
  const t = await setup();
  try {
    const { templateId } = await t.create();
    await assert.rejects(
      t.changeStatus(templateId, 5, "DANG_DUNG"),
      failsWith("23514", "VERSION_CONFLICT"),
    );
    await t.changeStatus(templateId, 0, "DANG_DUNG");
    assert.deepEqual(
      [(await t.row(templateId)).status, (await t.row(templateId)).version],
      ["DANG_DUNG", 1],
    );
    await assert.rejects(
      t.changeStatus(templateId, 1, "DANG_DUNG"),
      failsWith("23514", "TEMPLATE_INACTIVE"),
    );
    await t.changeStatus(templateId, 1, "NGUNG");
    assert.equal((await t.row(templateId)).status, "NGUNG");
    await assert.rejects(
      t.changeStatus(templateId, 2, "NGUNG"),
      failsWith("23514", "TEMPLATE_INACTIVE"),
    );
    await assert.rejects(
      t.changeStatus(templateId, 2, "NHAP"),
      failsWith("23514", "INVALID_TEMPLATE_DEFINITION"),
    );
    const audits = (
      await t.f.owner.query(
        "SELECT hanh_dong FROM nhat_ky_bao_mat WHERE doi_tuong=$1 ORDER BY ma_su_kien",
        [`mau_bang_diem:${templateId}`],
      )
    ).rows.map((r) => r.hanh_dong);
    assert.deepEqual(audits, [
      "FORM_TEMPLATE_CREATED",
      "FORM_TEMPLATE_ACTIVATED",
      "FORM_TEMPLATE_RETIRED",
    ]);
  } finally {
    await t.f.close();
  }
});

test("table constraints reject malformed rows even for the table owner", async () => {
  const t = await setup();
  try {
    const { templateId } = await t.create();
    // Mẫu khác chỉ để thử chèn cột sai (mẫu chưa có phiếu tham chiếu nên trigger "đang dùng" không chặn trước).
    const other = (await t.create()).templateId;
    const insertOther = (
      index: number,
      role: string,
      group: string | null,
      order: number | null,
      pair: number | null,
    ) =>
      t.f.owner.query(
        'INSERT INTO cot_mau(ma_mau,chi_so_cot,vai_tro,loai_he_so,thu_tu_trong_nhom,cot_diem_di_kem) VALUES($1,$2,$3::"VaiTroCot",$4,$5,$6)',
        [other, index, role, group, order, pair],
      );
    const checks = (message: string) => failsWith("23514", message);
    await assert.rejects(
      insertOther(10, "DIEM", null, 1, null),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(11, "DIEM", "XX", 1, null),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(12, "DIEM", "TX", 0, null),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(13, "DIEM_CHU", null, null, null),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(14, "DIEM_CHU", null, null, 14),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(15, "BO_QUA", "TX", null, null),
      checks("cot_mau_theo_vai_tro"),
    );
    await assert.rejects(
      insertOther(64, "BO_QUA", null, null, null),
      checks("cot_mau_chi_so_hop_le"),
    );
    // (loai_he_so, thu_tu_trong_nhom) trùng và một cột chữ thứ hai cho cùng cột điểm.
    await assert.rejects(
      insertOther(20, "DIEM", "TX", 1, null),
      failsWith("23505", "cot_mau_nhom_thu_tu_key"),
    );
    await assert.rejects(
      insertOther(21, "DIEM_CHU", null, null, 2),
      failsWith("23505", "cot_mau_di_kem_key"),
    );
    // Khóa ngoại hoãn: cột chữ trỏ tới chỉ số không tồn tại bị bắt khi COMMIT.
    const client = await t.f.owner.connect();
    try {
      await client.query("BEGIN");
      await client.query(
        "INSERT INTO cot_mau(ma_mau,chi_so_cot,vai_tro,cot_diem_di_kem) VALUES($1,40,'DIEM_CHU',41)",
        [other],
      );
      await assert.rejects(
        client.query("COMMIT"),
        failsWith("23503", "cot_mau_di_kem_fkey"),
      );
    } finally {
      await client.query("ROLLBACK").catch(() => {});
      client.release();
    }
    const insertTemplate = (
      path: string,
      revision: number,
      root: number | null,
      sig: object,
    ) =>
      t.f.owner.query(
        "INSERT INTO mau_bang_diem(ten_mau,phien_ban,ma_mau_goc,chu_ky_luoi,duong_dan_anh_mau,ma_bam_anh_mau,nguoi_tao) VALUES('x',$1,$2,$3::jsonb,$4,$5,$6)",
        [revision, root, JSON.stringify(sig), path, "a".repeat(64), t.admin.id],
      );
    const goodPath = `form-templates/${randomUUID()}.png`;
    await assert.rejects(
      insertTemplate("../etc/passwd", 1, null, signature()),
      checks("mau_duong_dan_anh"),
    );
    await assert.rejects(
      insertTemplate(goodPath, 2, null, signature()),
      checks("mau_goc_hop_le"),
    );
    await assert.rejects(
      insertTemplate(goodPath, 1, templateId, signature()),
      checks("mau_goc_hop_le"),
    );
    await assert.rejects(
      insertTemplate(goodPath, 1, null, {}),
      checks("mau_chu_ky_hop_le"),
    );
    await assert.rejects(
      insertTemplate(goodPath, 1, null, { version: 1, columnWidths: "x" }),
      checks("mau_chu_ky_hop_le"),
    );
    await assert.rejects(
      insertTemplate(goodPath, 1, null, { version: 1, columnWidths: [1] }),
      checks("mau_chu_ky_hop_le"),
    );
    // Cùng chuỗi không có hai phiên bản trùng số.
    await assert.rejects(
      insertTemplate(goodPath, 2, other, signature()).then(() =>
        insertTemplate(goodPath, 2, other, signature()),
      ),
      failsWith("23505", "mau_bang_diem_chuoi_phien_ban_key"),
    );
    // Không hard-delete mẫu.
    await assert.rejects(
      t.f.owner.query("DELETE FROM mau_bang_diem WHERE ma_mau=$1", [
        templateId,
      ]),
      failsWith("23514", "TEMPLATE_DELETE_FORBIDDEN"),
    );
  } finally {
    await t.f.close();
  }
});

test("the runtime role can read templates but never write them directly", async () => {
  const t = await setup();
  try {
    const { templateId } = await t.create();
    assert.equal(
      (
        await t.f.runtime.query(
          "SELECT ten_mau FROM mau_bang_diem WHERE ma_mau=$1",
          [templateId],
        )
      ).rowCount,
      1,
    );
    assert.equal(
      (
        await t.f.runtime.query("SELECT 1 FROM cot_mau WHERE ma_mau=$1", [
          templateId,
        ])
      ).rowCount,
      6,
    );
    const denied = failsWith("42501", "permission denied");
    await assert.rejects(
      t.f.runtime.query("DELETE FROM mau_bang_diem WHERE ma_mau=$1", [
        templateId,
      ]),
      denied,
    );
    await assert.rejects(
      t.f.runtime.query(
        "UPDATE mau_bang_diem SET ten_mau='x' WHERE ma_mau=$1",
        [templateId],
      ),
      denied,
    );
    await assert.rejects(
      t.f.runtime.query("DELETE FROM cot_mau WHERE ma_mau=$1", [templateId]),
      denied,
    );
    await assert.rejects(
      t.f.runtime.query(
        "INSERT INTO cot_mau(ma_mau,chi_so_cot,vai_tro) VALUES($1,30,'BO_QUA')",
        [templateId],
      ),
      denied,
    );
    await assert.rejects(
      t.f.runtime.query(
        "INSERT INTO mau_bang_diem(ten_mau,chu_ky_luoi,duong_dan_anh_mau,ma_bam_anh_mau,nguoi_tao) VALUES('x','{}','p','h',1)",
      ),
      denied,
    );
    assert.equal(await t.columnCount(templateId), 6);
  } finally {
    await t.f.close();
  }
});

test("trying a template needs no table write: only the rate-limit counter accepts the new operations", async () => {
  const t = await setup();
  try {
    const consume = (session: string, operation: string) =>
      t.f.serializable(
        async (query) =>
          (
            await query(
              "SELECT public.tieu_thu_han_muc_tac_vu($1,$2,2,60) AS allowed",
              [session, operation],
            )
          ).rows[0].allowed as boolean,
      );
    // QTV dùng được thao tác của mẫu; hết hạn mức thì false.
    assert.equal(await consume(t.admin.session, "FORM_TEMPLATE_TRY"), true);
    assert.equal(await consume(t.admin.session, "FORM_TEMPLATE_TRY"), true);
    assert.equal(await consume(t.admin.session, "FORM_TEMPLATE_TRY"), false);
    assert.equal(await consume(t.admin.session, "FORM_TEMPLATE_ANALYZE"), true);
    // Giáo viên không dùng được thao tác của QTV và QTV không dùng thao tác upload của giáo viên.
    await assert.rejects(
      consume(t.f.session, "FORM_TEMPLATE_TRY"),
      failsWith("42501", "FORBIDDEN"),
    );
    await assert.rejects(
      consume(t.admin.session, "RECOGNITION_UPLOAD"),
      failsWith("42501", "FORBIDDEN"),
    );
    assert.equal(await consume(t.f.session, "RECOGNITION_UPLOAD"), true);
    await assert.rejects(
      consume(t.admin.session, "SOMETHING_ELSE"),
      failsWith("23514", "INVALID_OPERATION_RATE_LIMIT"),
    );
    // "Thử" không tạo phiếu, kết quả dòng hay mẫu: số bản ghi không đổi.
    const ticketsBefore = await t.f.countTickets();
    const templatesBefore = await t.templateTotal();
    await consume(t.admin.session, "FORM_TEMPLATE_TRY");
    assert.equal(await t.f.countTickets(), ticketsBefore);
    assert.equal(await t.templateTotal(), templatesBefore);
  } finally {
    await t.f.close();
  }
});
