import { createHash, randomBytes, randomUUID } from "node:crypto";
import type { Pool } from "pg";
import { createRosterFixture } from "./roster-fixture.js";

// Dữ liệu hoàn toàn giả cho lô nhận dạng nhiều trang (ADR-0016 mục 3): mẫu, thành phần TX2, hàm tạo lô và dựng dòng kết quả.
export type BatchComponent = {
  templateColumnIndex: number;
  componentId: number;
};
export type BatchPage = { page: number; checksum: string; objectKey: string };
export type BatchReceipt = {
  batchId: string;
  jobId: string;
  status: string;
  storedObjectKeys: string[];
  tickets: Array<{
    ticketId: string;
    componentId: number;
    templateColumnIndex: number;
  }>;
};

type TemplateColumn = {
  index: number;
  role: string;
  group?: string | null;
  order?: number | null;
  pairedWith?: number | null;
  headerText?: string | null;
};

/** STT | Họ tên | TX1 số | TX1 chữ | TX2 số (một kênh) | Ghi chú. */
export const batchTemplateColumns = (): TemplateColumn[] => [
  { index: 0, role: "STT" },
  { index: 1, role: "HO_TEN" },
  { index: 2, role: "DIEM", group: "TX", order: 1 },
  { index: 3, role: "DIEM_CHU", pairedWith: 2 },
  { index: 4, role: "DIEM", group: "TX", order: 2 },
  { index: 5, role: "BO_QUA" },
];

export const batchSignature = () => ({
  version: 1,
  columnWidths: [0.1, 0.3, 0.15, 0.15, 0.15, 0.15],
  headerTexts: ["", "", "", "", "", ""],
  headerRows: 1,
  rowHeightMm: 8,
  tableWidthMm: 180,
});

export async function serializable<T>(
  pool: Pool,
  work: (query: Pool["query"]) => Promise<T>,
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN ISOLATION LEVEL SERIALIZABLE");
    try {
      const value = await work(client.query.bind(client) as Pool["query"]);
      await client.query("COMMIT");
      return value;
    } catch (error) {
      await client.query("ROLLBACK");
      throw error;
    }
  } finally {
    client.release();
  }
}

export async function makeSession(
  owner: Pool,
  role: "GIAO_VIEN" | "QUAN_TRI_VIEN" | "HOC_SINH",
  label: string,
) {
  const id: number = (
    await owner.query(
      "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only',$2::\"VaiTro\") RETURNING ma_nguoi_dung",
      [`${label}_${randomBytes(5).toString("hex")}`, role],
    )
  ).rows[0].ma_nguoi_dung;
  const session = createHash("sha256").update(randomBytes(32)).digest("hex");
  await owner.query(
    "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
    [session, id, randomBytes(32).toString("hex")],
  );
  if (role === "GIAO_VIEN")
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV lô giả')",
      [id],
    );
  return { id, session };
}

/** Tạo mẫu qua hàm SQL của runtime bằng phiên QTV; `activate` đưa mẫu sang DANG_DUNG. */
export async function createTemplate(
  owner: Pool,
  runtime: Pool,
  activate = true,
): Promise<number> {
  const admin = await makeSession(owner, "QUAN_TRI_VIEN", "batch_admin");
  const created = await serializable(
    runtime,
    async (query) =>
      (
        await query(
          "SELECT public.luu_mau_bang_diem($1,'TAO',NULL,NULL,$2,NULL,$3::jsonb,$4::jsonb,$5,$6) AS result",
          [
            admin.session,
            "Mẫu lô giả",
            JSON.stringify(batchTemplateColumns()),
            JSON.stringify(batchSignature()),
            `form-templates/${randomUUID()}.png`,
            randomBytes(32).toString("hex"),
          ],
        )
      ).rows[0].result as { templateId: number },
  );
  if (activate)
    await serializable(runtime, (query) =>
      query("SELECT public.doi_trang_thai_mau_bang_diem($1,$2,0,'DANG_DUNG')", [
        admin.session,
        created.templateId,
      ]),
    );
  return created.templateId;
}

export const fakePages = (count: number): BatchPage[] =>
  Array.from({ length: count }, (_, index) => ({
    page: index + 1,
    checksum: randomBytes(32).toString("hex"),
    objectKey: `recognition/original/${randomUUID()}.png`,
  }));

const channel = (value: string | null) => ({
  rawOutput: value,
  value,
  confidence: value === null ? null : "0.95",
  isBlank: value === null,
});

/** Dòng hai kênh (cột có cột chữ đi kèm); `order` = (trang-1)*1000 + vị trí dòng trên trang. */
export function twoChannelRow(
  ticket: string,
  page: number,
  position: number,
  stt: number,
  value: string | null,
  extra: Record<string, unknown> = {},
) {
  const order = (page - 1) * 1000 + position;
  return {
    page,
    order,
    stt,
    sttOnPaper: stt,
    nameRead: "Họ tên đọc được giả",
    matchConfidence: 0.97,
    matchNote: "Khớp STT và họ tên",
    matchLevel: "XANH",
    numeric: channel(value),
    written: channel(value),
    numericCropKey: `recognition/crops/${ticket}/${order}-numeric.png`,
    writtenCropKey: `recognition/crops/${ticket}/${order}-written.png`,
    nameCropKey: `recognition/crops/${ticket}/${order}-name.png`,
    comparison: value === null ? "KHONG_DOC_DUOC" : "KHOP",
    reviewLevel: value === null ? "DO" : "XANH",
    suggestedSource: value === null ? null : "SO",
    ...extra,
  };
}

/** Dòng cột một kênh: kênh chữ trống, không ảnh ô chữ, tối đa Vàng (D-01). */
export function oneChannelRow(
  ticket: string,
  page: number,
  position: number,
  stt: number,
  value: string | null,
  extra: Record<string, unknown> = {},
) {
  return twoChannelRow(ticket, page, position, stt, value, {
    written: channel(null),
    writtenCropKey: null,
    comparison: value === null ? "KHONG_DOC_DUOC" : "MOT_KENH",
    reviewLevel: value === null ? "DO" : "VANG",
    suggestedSource: value === null ? null : "SO",
    ...extra,
  });
}

/** Lớp 4 học sinh (STT 1–4) trên hai trang: STT 1–2 ở trang 1, STT 3–4 ở trang 2. */
export const PAGE_OF_STT = [1, 1, 2, 2] as const;
const POSITION_OF_STT = [1, 2, 1, 2] as const;

/** Giá trị KHÁC NHAU giữa hai cột của cùng học sinh để bắt nhầm cột (AC-4). */
export const TX1_VALUES = ["6.0", "7.0", "8.0", "9.0"] as const;
export const TX2_VALUES = ["1.0", "2.0", "3.0", "4.0"] as const;

export function fullResults(receipt: BatchReceipt) {
  const byColumn = new Map(
    receipt.tickets.map((ticket) => [ticket.templateColumnIndex, ticket]),
  );
  const tx1 = byColumn.get(2)!;
  const tx2 = byColumn.get(4)!;
  return [
    {
      ticketId: tx1.ticketId,
      rows: [0, 1, 2, 3].map((index) =>
        twoChannelRow(
          tx1.ticketId,
          PAGE_OF_STT[index]!,
          POSITION_OF_STT[index]!,
          index + 1,
          TX1_VALUES[index]!,
        ),
      ),
    },
    {
      ticketId: tx2.ticketId,
      rows: [0, 1, 2, 3].map((index) =>
        oneChannelRow(
          tx2.ticketId,
          PAGE_OF_STT[index]!,
          POSITION_OF_STT[index]!,
          index + 1,
          TX2_VALUES[index]!,
        ),
      ),
    },
  ];
}

export async function createBatchFixture() {
  const f = await createRosterFixture();
  const subject: number = (
    await f.owner.query("SELECT ma_mon FROM bang_diem WHERE ma_bang_diem=$1", [
      f.book,
    ])
  ).rows[0].ma_mon;
  // Thành phần TX thứ 2 của môn: (TX, 2) ánh xạ tới thành phần này; có ô điểm cho học sinh đang học để duyệt được.
  const component2: number = (
    await f.owner.query(
      "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Ảnh roster 2',1,2) RETURNING ma_thanh_phan",
      [subject],
    )
  ).rows[0].ma_thanh_phan;
  await f.owner.query(
    "INSERT INTO diem_thanh_phan(ma_bang_diem,ma_hoc_sinh,ma_thanh_phan) SELECT $1,ma_hoc_sinh,$2 FROM hoc_sinh WHERE ma_lop=$3 AND dang_theo_hoc",
    [f.book, component2, f.cls],
  );
  const template = await createTemplate(f.owner, f.runtime);
  const components: BatchComponent[] = [
    { templateColumnIndex: 2, componentId: f.component },
    { templateColumnIndex: 4, componentId: component2 },
  ];

  const createBatch = (
    options: {
      session?: string;
      book?: number;
      templateId?: number;
      components?: unknown;
      pages?: unknown;
      roster?: unknown;
      key?: string;
      hash?: string;
    } = {},
  ) =>
    serializable(f.runtime, async (query) => {
      const { rows } = await query(
        "SELECT public.tao_lo_nhan_dien($1,$2,$3,$4::jsonb,$5::jsonb,$6::jsonb,$7,$8) AS result",
        [
          options.session ?? f.session,
          options.book ?? f.book,
          options.templateId ?? template,
          JSON.stringify(options.components ?? components),
          JSON.stringify(options.pages ?? fakePages(2)),
          JSON.stringify(options.roster ?? f.valid),
          options.key ?? `batch-${randomBytes(6).toString("hex")}`,
          options.hash ?? randomBytes(32).toString("hex"),
        ],
      );
      return rows[0].result as BatchReceipt;
    });

  const saveResults = (
    batchId: string,
    tickets: unknown,
    version = "fake-v2",
  ) =>
    serializable(f.runtime, (query) =>
      query("SELECT public.luu_ket_qua_lo($1,$2,$3::jsonb)", [
        batchId,
        version,
        JSON.stringify(tickets),
      ]),
    );

  const failBatch = (batchId: string, code: string, page: number | null) =>
    serializable(f.runtime, (query) =>
      query("SELECT public.danh_dau_lo_nhan_dien_loi($1,$2,$3)", [
        batchId,
        code,
        page,
      ]),
    );

  const cancelBatch = (
    batchId: string,
    options: {
      session?: string;
      book?: number;
      reason?: string;
      key?: string;
      hash?: string;
    } = {},
  ) =>
    serializable(
      f.runtime,
      async (query) =>
        (
          await query(
            "SELECT public.huy_lo_nhan_dien($1,$2,$3,$4,$5,$6) AS result",
            [
              options.session ?? f.session,
              options.book ?? f.book,
              batchId,
              options.reason ?? "Chụp nhầm bảng",
              options.key ?? `cancel-${randomBytes(6).toString("hex")}`,
              options.hash ?? "c".repeat(64),
            ],
          )
        ).rows[0].result as {
          batchId: string;
          batchVersion: number;
          gradebookId: number;
          status: string;
          cancelledTickets: number;
        },
    );

  const approve = (ticketId: string, decisions: unknown, key: string) =>
    f.serializable(async (query) => {
      const versions = (
        await query(
          "SELECT t.version AS ticket_version,b.version AS book_version FROM phieu_nhan_dien t JOIN bang_diem b USING(ma_bang_diem) WHERE t.ma_phieu=$1",
          [ticketId],
        )
      ).rows[0];
      return query(
        "SELECT public.duyet_phieu_nhan_dien($1,$2,$3,$4,$5,$6::jsonb,$7,$8)",
        [
          f.session,
          f.book,
          ticketId,
          versions.ticket_version,
          versions.book_version,
          JSON.stringify(decisions),
          key,
          "d".repeat(64),
        ],
      );
    });

  const count = async (sql: string, params: unknown[] = []) =>
    Number((await f.owner.query(sql, params)).rows[0].count);
  // Số bản ghi theo bảng điểm / giáo viên của fixture (các file test có thể chạy song song trên cùng DB).
  const totals = async () => ({
    batches: await count(
      "SELECT count(*) FROM lo_nhan_dien WHERE ma_bang_diem=$1",
      [f.book],
    ),
    pages: await count(
      "SELECT count(*) FROM trang_lo_nhan_dien WHERE ma_lo IN (SELECT ma_lo FROM lo_nhan_dien WHERE ma_bang_diem=$1)",
      [f.book],
    ),
    tickets: await count(
      "SELECT count(*) FROM phieu_nhan_dien WHERE ma_bang_diem=$1",
      [f.book],
    ),
    rosters: await count(
      "SELECT count(*) FROM danh_sach_phieu WHERE ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_bang_diem=$1)",
      [f.book],
    ),
    outbox: await count(
      "SELECT count(*) FROM recognition_outbox WHERE ma_lo IN (SELECT ma_lo FROM lo_nhan_dien WHERE ma_bang_diem=$1)",
      [f.book],
    ),
    audits: await count(
      "SELECT count(*) FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1",
      [f.teacherId],
    ),
    idempotency: await count(
      "SELECT count(*) FROM khoa_idempotency WHERE ma_nguoi_dung=$1",
      [f.teacherId],
    ),
  });
  const evidence = async (ticketId: string) =>
    (
      await f.owner.query(
        "SELECT ma_dong, thu_tu_dong, so_trang, ma_hoc_sinh, gia_tri_kenh_a::text AS a, gia_tri_kenh_b::text AS b, duong_dan_anh_o_chu, muc_phan_loai::text AS level, kenh_goi_y FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
        [ticketId],
      )
    ).rows;
  const ticketStatus = async (ticketId: string) =>
    (
      await f.owner.query(
        "SELECT trang_thai::text AS status, ma_loi FROM phieu_nhan_dien WHERE ma_phieu=$1",
        [ticketId],
      )
    ).rows[0] as { status: string; ma_loi: string | null };
  const batchRow = async (batchId: string) =>
    (
      await f.owner.query(
        "SELECT trang_thai::text AS status, ma_loi, trang_loi, so_trang, version FROM lo_nhan_dien WHERE ma_lo=$1",
        [batchId],
      )
    ).rows[0] as {
      status: string;
      ma_loi: string | null;
      trang_loi: number | null;
      so_trang: number;
      version: number;
    };

  return {
    f,
    subject,
    component1: f.component,
    component2,
    template,
    components,
    createBatch,
    saveResults,
    failBatch,
    cancelBatch,
    approve,
    totals,
    evidence,
    ticketStatus,
    batchRow,
    close: async () => {
      // Không để lại sự kiện outbox chưa gửi: dispatcher của test khác lấy theo lô sự kiện cũ nhất.
      await f.owner.query(
        "UPDATE recognition_outbox SET da_gui_luc=now() WHERE da_gui_luc IS NULL AND ma_lo IN (SELECT ma_lo FROM lo_nhan_dien WHERE ma_bang_diem=$1)",
        [f.book],
      );
      await f.close();
    },
  };
}
