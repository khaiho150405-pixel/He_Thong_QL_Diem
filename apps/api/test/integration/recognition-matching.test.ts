import assert from "node:assert/strict";
import { test } from "node:test";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../src/generated/prisma/client.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../../src/modules/files/application/port.js";
import type {
  RecognitionModelClient,
  RecognitionResult,
  RecognitionRowResult,
} from "../../src/modules/recognition/application/port.js";
import { RecognitionJobProcessor } from "../../src/modules/recognition/application/worker.js";
import { PrismaRecognitionWorkerStore } from "../../src/modules/recognition/infrastructure/prisma-worker-store.js";
import { createRosterFixture } from "./roster-fixture.js";

// ADR-0015, bước BE-11: upload (snapshot) → worker (ghép STT + họ tên) → CHO_DOI_CHIEU; dữ liệu hoàn toàn giả.
const pixel =
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=";

const channel = (value: string) => ({
  rawOutput: value,
  value,
  confidence: "0.95",
  isBlank: false,
});
const blank = {
  rawOutput: null,
  value: null,
  confidence: null,
  isBlank: true,
};

function paperRow(
  rowIndex: number,
  stt: number | null,
  name: string,
  grade: string,
  overrides: Partial<RecognitionRowResult> = {},
): RecognitionRowResult {
  return {
    rowIndex,
    struck: false,
    stt:
      stt === null
        ? { raw: null, value: null, confidence: null, isBlank: true }
        : { raw: String(stt), value: stt, confidence: "0.97", isBlank: false },
    name: { raw: name, confidence: "0.90", isBlank: false },
    numeric: channel(grade),
    written: channel(grade),
    numericCropBase64: pixel,
    writtenCropBase64: pixel,
    nameCropBase64: pixel,
    comparison: "KHOP",
    reviewLevel: "XANH",
    suggestedSource: "SO",
    ...overrides,
  };
}

async function setup(
  rows: (names: string[]) => RecognitionRowResult[],
  sttCheck = false,
) {
  const f = await createRosterFixture();
  const database = new PrismaClient({
    adapter: new PrismaPg({
      connectionString: process.env.TEST_RUNTIME_URL!,
      options: "-c timezone=UTC",
    }),
  });
  const objects = new Map<string, StoredObject>();
  const storage: ObjectStorage = {
    put: async (object) => void objects.set(object.key, object),
    get: async () => new Uint8Array([1]),
    signedGetUrl: async (key) => `https://storage.test/${key}`,
    remove: async (key) => void objects.delete(key),
  };
  let recognized = 0;
  const model: RecognitionModelClient = {
    recognize: async (): Promise<RecognitionResult> => {
      recognized += 1;
      return {
        modelVersion: "fake-dev-v1",
        pageStartStt: 1,
        rows: rows(f.valid.map((entry) => entry.fullName)),
      };
    },
  };
  const receipt = await f.createTicket(f.valid, "matching");
  const worker = new RecognitionJobProcessor(
    new PrismaRecognitionWorkerStore(database),
    storage,
    model,
    { sttCheck },
  );
  const state = async () => {
    const ticket = (
      await f.owner.query(
        "SELECT trang_thai::text AS status,ma_loi,so_dong_nhan_dien,phien_ban_mo_hinh FROM phieu_nhan_dien WHERE ma_phieu=$1",
        [receipt.ticketId],
      )
    ).rows[0];
    const evidence = (
      await f.owner.query(
        "SELECT thu_tu_dong,ma_hoc_sinh,muc_phan_loai::text AS level,stt_giay,ho_ten_doc_duoc,do_tin_cay_ghep::text AS match_conf,duong_dan_anh_o_ten,ghi_chu_ghep FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
        [receipt.ticketId],
      )
    ).rows;
    const official = Number(
      (
        await f.owner.query(
          "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
          [f.book],
        )
      ).rows[0].count,
    );
    return { ticket, evidence, official };
  };
  return {
    f,
    worker,
    objects,
    receipt,
    state,
    recognized: () => recognized,
    close: async () => {
      await database.$disconnect();
      await f.close();
    },
  };
}

test("upload → worker maps each row to the right student by STT and drops struck rows", async () => {
  // Thứ tự tên: An(1), Bảo(2), Cường(3), Đạt(4); mã học sinh khác thứ tự này. Dòng 2 trên ảnh bị gạch.
  const t = await setup((names) => [
    paperRow(1, 1, names[0]!, "9.0"),
    paperRow(2, 2, names[1]!, "5.0", {
      struck: true,
      numeric: blank,
      written: blank,
      comparison: "KHONG_DOC_DUOC",
      reviewLevel: "DO",
      suggestedSource: null,
    }),
    paperRow(3, 3, names[2]!, "7.5"),
    paperRow(4, 4, names[3]!, "6.0"),
  ]);
  try {
    const { students: s } = t.f;
    await t.worker.process(t.receipt.ticketId);
    const { ticket, evidence, official } = await t.state();
    assert.equal(ticket.status, "CHO_DOI_CHIEU");
    assert.equal(ticket.ma_loi, null);
    assert.equal(ticket.so_dong_nhan_dien, 3);
    assert.equal(ticket.phien_ban_mo_hinh, "fake-dev-v1");
    assert.deepEqual(
      evidence.map((r) => [r.thu_tu_dong, r.ma_hoc_sinh, r.stt_giay]),
      [
        [1, s.an, 1],
        [3, s.cuong, 3],
        [4, s.dat, 4],
      ],
    );
    assert.ok(evidence.every((r) => r.level === "XANH"));
    assert.deepEqual(
      evidence.map((r) => r.duong_dan_anh_o_ten),
      [1, 3, 4].map(
        (n) => `recognition/crops/${t.receipt.ticketId}/${n}-name.png`,
      ),
    );
    assert.ok(
      t.objects.has(`recognition/crops/${t.receipt.ticketId}/1-name.png`),
    );
    assert.equal(
      t.objects.has(`recognition/crops/${t.receipt.ticketId}/2-numeric.png`),
      false,
    );
    // Máy chỉ đề xuất: chưa có điểm chính thức nào.
    assert.equal(official, 0);
    // Chạy lại job là idempotent: không gọi lại mô hình, không thêm dòng.
    const calls = t.recognized();
    await t.worker.process(t.receipt.ticketId);
    assert.equal(t.recognized(), calls);
    assert.equal((await t.state()).evidence.length, 3);
  } finally {
    await t.close();
  }
});

test("final level combines the grade level with the match level and keeps both traces", async () => {
  const t = await setup(
    (names) => [
      paperRow(1, 1, names[0]!, "9.0", {
        comparison: "LECH",
        reviewLevel: "VANG",
      }),
      // Tên khớp mạnh nhưng STT in trên giấy mâu thuẫn học sinh được ghép → hạ xuống Vàng (cờ xác nhận STT bật).
      paperRow(2, 9, names[1]!, "5.0"),
      paperRow(3, 3, names[2]!, "7.5"),
      paperRow(4, 4, names[3]!, "6.0"),
    ],
    true,
  );
  try {
    await t.worker.process(t.receipt.ticketId);
    const { ticket, evidence } = await t.state();
    assert.equal(ticket.status, "CHO_DOI_CHIEU");
    assert.deepEqual(
      evidence.map((r) => r.level),
      ["VANG", "VANG", "XANH", "XANH"],
    );
    assert.equal(
      evidence[1]!.ghi_chu_ghep,
      "STT trên giấy 9 khác STT dự kiến 2.",
    );
    assert.equal(Number(evidence[1]!.match_conf) >= 0, true);
    assert.equal(evidence[1]!.stt_giay, 9);
  } finally {
    await t.close();
  }
});

test("rows from the wrong class mark the ticket ROW_MATCH_FAILED and write nothing", async () => {
  // FAKE_START_STT sai lớp: tên/STT thuộc học sinh khác hoàn toàn.
  const t = await setup(() =>
    [1, 2, 3, 4].map((n) =>
      paperRow(n, 38 + n, `Trương Ghi ${n}${n}${n}`, `${n}.0`),
    ),
  );
  try {
    await t.worker.process(t.receipt.ticketId);
    const { ticket, evidence, official } = await t.state();
    assert.equal(ticket.status, "LOI");
    assert.equal(ticket.ma_loi, "ROW_MATCH_FAILED");
    assert.equal(evidence.length, 0);
    assert.equal(official, 0);
    // Phiếu LOI không được xử lý lại.
    const calls = t.recognized();
    await t.worker.process(t.receipt.ticketId);
    assert.equal(t.recognized(), calls);
    assert.equal(
      [...t.objects.keys()].some((key) => key.includes("/crops/")),
      false,
    );
  } finally {
    await t.close();
  }
});

test("more graded rows than the class size fail instead of guessing", async () => {
  const t = await setup((names) => [
    ...names.map((name, index) => paperRow(index + 1, index + 1, name, "8.0")),
    paperRow(5, 5, "Lê Thừa Dòng", "8.0"),
  ]);
  try {
    await t.worker.process(t.receipt.ticketId);
    const { ticket, evidence } = await t.state();
    assert.equal(ticket.status, "LOI");
    assert.equal(ticket.ma_loi, "ROW_MATCH_FAILED");
    assert.equal(evidence.length, 0);
  } finally {
    await t.close();
  }
});

test("without any STT reading the rows are still matched to the right students by name", async () => {
  // STT is not recognised (project decision): the service sends stt.value = null, confidence 0.
  const t = await setup((names) =>
    [3, 1, 0, 2].map((nameIndex, i) =>
      // paper order differs from the name order only by the real class order: An, Bảo, Cường, Đạt
      paperRow(i + 1, null, names[[0, 1, 2, 3][i]!]!, `${6 + i}.0`),
    ),
  );
  try {
    const { students: s } = t.f;
    await t.worker.process(t.receipt.ticketId);
    const { ticket, evidence, official } = await t.state();
    assert.equal(ticket.status, "CHO_DOI_CHIEU");
    assert.deepEqual(
      evidence.map((r) => [r.thu_tu_dong, r.ma_hoc_sinh, r.stt_giay]),
      [
        [1, s.an, null],
        [2, s.bao, null],
        [3, s.cuong, null],
        [4, s.dat, null],
      ],
    );
    assert.ok(evidence.every((r) => r.level === "XANH"));
    assert.equal(official, 0);
  } finally {
    await t.close();
  }
});
