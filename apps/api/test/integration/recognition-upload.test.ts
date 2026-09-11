import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import { Pool } from "pg";
import { createApp } from "../../src/app.js";
import type {
  ObjectStorage,
  StoredObject,
} from "../../src/modules/files/application/port.js";
import type { Actor } from "../../src/modules/authorization/application/policy.js";
import { GradebooksService } from "../../src/modules/gradebooks/application/service.js";
import { RecognitionService } from "../../src/modules/recognition/application/service.js";
import { RecognitionDispatcher } from "../../src/modules/recognition/application/outbox.js";
import { PrismaRecognitionOutbox } from "../../src/modules/recognition/infrastructure/prisma-outbox.js";
import type { PrismaClient } from "../../src/generated/prisma/client.js";

function png(seed: Uint8Array): Uint8Array {
  const bytes = new Uint8Array(24 + seed.byteLength);
  bytes.set([137, 80, 78, 71, 13, 10, 26, 10]);
  bytes.set([73, 72, 68, 82], 12);
  new DataView(bytes.buffer).setUint32(16, 100);
  new DataView(bytes.buffer).setUint32(20, 100);
  bytes.set(seed, 24);
  return bytes;
}

test("UC11 creates upload ticket, audit and outbox atomically with scope and replay protection", async () => {
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
  const objects = new Map<string, StoredObject>();
  const storage: ObjectStorage = {
    put: async (object) => void objects.set(object.key, object),
    remove: async (key) => void objects.delete(key),
  };
  const app = await createApp(
    {
      environment: "development",
      origins: ["http://localhost:8080"],
      databaseUrl: runtimeUrl,
    },
    { check: async () => true, close: async () => {} },
    { objectStorage: storage },
  );
  await app.listen(0, "127.0.0.1");
  const baseUrl = await app.getUrl();
  const gradebooks = app.get(GradebooksService);
  const recognition = app.get(RecognitionService);
  const suffix = randomBytes(5).toString("hex");
  const makeActor = async (): Promise<Actor & { token: string }> => {
    const row = (
      await owner.query(
        "INSERT INTO nguoi_dung(ten_dang_nhap,mat_khau_ma_hoa,vai_tro) VALUES($1,'test-only','GIAO_VIEN') RETURNING ma_nguoi_dung",
        ["recognition_" + randomBytes(5).toString("hex")],
      )
    ).rows[0];
    const token = randomBytes(32).toString("hex");
    const sessionHash = createHash("sha256").update(token).digest("hex");
    await owner.query(
      "INSERT INTO phien_lam_viec VALUES($1,$2,$3,now()+interval '1 hour',now())",
      [sessionHash, row.ma_nguoi_dung, randomBytes(32).toString("hex")],
    );
    await owner.query(
      "INSERT INTO giao_vien(ma_giao_vien,ho_ten) VALUES($1,'GV nhận dạng giả')",
      [row.ma_nguoi_dung],
    );
    return {
      id: row.ma_nguoi_dung,
      username: "recognition_" + suffix,
      role: "GIAO_VIEN",
      sessionHash,
      token,
    };
  };
  try {
    const teacher = await makeActor();
    const intruder = await makeActor();
    const year = (
      await owner.query(
        "INSERT INTO nam_hoc(ten,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'2026-09-01','2027-06-01') RETURNING ma_nam_hoc",
        ["R-" + suffix],
      )
    ).rows[0].ma_nam_hoc;
    const term = (
      await owner.query(
        "INSERT INTO hoc_ky(ma_nam_hoc,ten,thu_tu,ngay_bat_dau,ngay_ket_thuc) VALUES($1,'Kỳ OCR',1,'2026-09-01','2027-01-01') RETURNING ma_hoc_ky",
        [year],
      )
    ).rows[0].ma_hoc_ky;
    const cls = (
      await owner.query(
        "INSERT INTO lop(ma_nam_hoc,ma_gv_chu_nhiem,ten_lop,khoi) VALUES($1,$2,$3,10) RETURNING ma_lop",
        [year, teacher.id, "R-" + suffix],
      )
    ).rows[0].ma_lop;
    await owner.query(
      "INSERT INTO hoc_sinh(ma_lop,ho_ten,ngay_sinh) VALUES($1,'HS OCR 1','2010-01-01'),($1,'HS OCR 2','2010-01-01')",
      [cls],
    );
    const subject = (
      await owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        ["OCR-" + suffix],
      )
    ).rows[0].ma_mon;
    const component = (
      await owner.query(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Ảnh kiểm tra',1,1) RETURNING ma_thanh_phan",
        [subject],
      )
    ).rows[0].ma_thanh_phan;
    await owner.query(
      "INSERT INTO phan_cong_giang_day(ma_giao_vien,ma_lop,ma_mon,ma_hoc_ky,ngay_phan_cong) VALUES($1,$2,$3,$4,CURRENT_DATE)",
      [teacher.id, cls, subject, term],
    );
    const book = await gradebooks.create(teacher, {
      classId: cls,
      subjectId: subject,
      termId: term,
    });
    const input = {
      bytes: png(randomBytes(8)),
      claimedType: "image/png",
      componentId: String(component),
      declaredRows: "2",
    };
    const form = new FormData();
    form.set("componentId", String(component));
    form.set("declaredRows", "2");
    const imageBytes = input.bytes;
    form.set(
      "image",
      new Blob([imageBytes.buffer as ArrayBuffer], { type: "image/png" }),
      "grades.png",
    );
    const response = await fetch(
      `${baseUrl}/api/v1/gradebooks/${book.id}/recognition-tickets`,
      {
        method: "POST",
        headers: {
          authorization: `Bearer ${teacher.token}`,
          "x-idempotency-key": "upload-one",
        },
        body: form,
      },
    );
    assert.equal(response.status, 202);
    const receipt = (await response.json()) as {
      ticketId: string;
      jobId: string;
      status: string;
    };
    assert.equal(receipt.status, "DANG_XU_LY");
    assert.equal(receipt.jobId, "recognition-" + receipt.ticketId);
    assert.equal(objects.size, 1);
    assert.deepEqual(
      await recognition.upload(teacher, book.id, "upload-one", input),
      receipt,
    );
    assert.equal(objects.size, 1);
    await assert.rejects(
      recognition.upload(teacher, book.id, "upload-one", {
        ...input,
        bytes: png(randomBytes(8)),
      }),
      (error: { getStatus?: () => number }) => error.getStatus?.() === 409,
    );
    assert.equal(objects.size, 1);
    await assert.rejects(
      recognition.upload(teacher, book.id, "another-key", input),
      (error: { getStatus?: () => number }) => error.getStatus?.() === 409,
    );
    assert.equal(objects.size, 1);
    await assert.rejects(
      recognition.upload(teacher, book.id, "wrong-rows", {
        ...input,
        bytes: png(randomBytes(8)),
        declaredRows: "3",
      }),
      (error: { getStatus?: () => number }) => error.getStatus?.() === 409,
    );
    assert.equal(objects.size, 1);
    await assert.rejects(
      recognition.upload(intruder, book.id, "intruder", {
        ...input,
        bytes: png(randomBytes(8)),
      }),
      (error: { getStatus?: () => number }) => error.getStatus?.() === 403,
    );
    assert.equal(objects.size, 1);
    const rows = await owner.query(
      "SELECT (SELECT count(*) FROM phieu_nhan_dien WHERE ma_phieu=$1) tickets,(SELECT count(*) FROM recognition_outbox WHERE ma_phieu=$1) events,(SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong='RECOGNITION_UPLOADED' AND doi_tuong=$2) audits",
      [receipt.ticketId, "phieu_nhan_dien:" + receipt.ticketId],
    );
    assert.deepEqual(rows.rows[0], { tickets: "1", events: "1", audits: "1" });

    const database = app.get<PrismaClient>("DATABASE");
    const queued: string[] = [];
    const dispatcher = new RecognitionDispatcher(
      new PrismaRecognitionOutbox(database),
      {
        enqueue: async (event) => void queued.push(event.jobId),
        close: async () => {},
      },
    );
    assert.equal(await dispatcher.dispatchOnce(), 1);
    assert.deepEqual(queued, [receipt.jobId]);
    assert.equal(await dispatcher.dispatchOnce(), 0);
  } finally {
    await app.close();
    await owner.end();
  }
});
