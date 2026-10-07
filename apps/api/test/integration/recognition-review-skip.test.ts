import assert from "node:assert/strict";
import { test } from "node:test";
import { createRosterFixture } from "./roster-fixture.js";

// Duyệt phiếu: giá trị cuối null = KHÔNG ghi điểm cho dòng đó (ví dụ học sinh vắng), nhưng vẫn lưu người duyệt,
// thời điểm và lý do bắt buộc; ô điểm của học sinh đó không đổi (NULL khác 0.0, giá trị cũ giữ nguyên).
test("a row approved with no final value leaves the cell untouched and the other rows are written", async () => {
  const f = await createRosterFixture();
  const { owner, students: s, valid } = f;
  try {
    const receipt = await f.createTicket(valid, "skip-ok");
    const ticket = receipt.ticketId;
    const channel = (value: string) => ({
      rawOutput: value,
      value,
      confidence: "0.95",
      isBlank: false,
    });
    const row = (order: number, stt: number) => ({
      order,
      stt,
      sttOnPaper: null,
      nameRead: "Họ tên đọc được giả",
      matchConfidence: 0.97,
      matchNote: "Khớp họ tên",
      numeric: channel("8.0"),
      written: channel("8.0"),
      numericCropKey: `recognition/crops/${ticket}/${order}-numeric.png`,
      writtenCropKey: `recognition/crops/${ticket}/${order}-written.png`,
      nameCropKey: `recognition/crops/${ticket}/${order}-name.png`,
      comparison: "KHOP",
      reviewLevel: "XANH",
    });
    await f.serializable((query) =>
      query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
        ticket,
        "fake-test-v1",
        JSON.stringify([row(1, 1), row(2, 2), row(3, 3)]),
      ]),
    );
    // Học sinh STT 2 đã có điểm cũ: dòng bỏ qua không được đụng tới ô này.
    await owner.query(
      "UPDATE diem_thanh_phan SET gia_tri=5.5, trang_thai='DA_DUYET', nguon_nhap='NHAP_TAY' WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
      [f.book, s.bao],
    );
    const historyBefore = Number(
      (await owner.query("SELECT count(*) FROM lich_su_sua_diem")).rows[0]
        .count,
    );
    const evidence = (
      await owner.query(
        "SELECT ma_dong,ma_hoc_sinh FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
        [ticket],
      )
    ).rows;
    const versions = (
      await owner.query(
        "SELECT t.version AS ticket_version,b.version AS book_version FROM phieu_nhan_dien t JOIN bang_diem b USING(ma_bang_diem) WHERE t.ma_phieu=$1",
        [ticket],
      )
    ).rows[0];
    const decide = (key: string, skipReason: string) =>
      f.serializable((query) =>
        query(
          "SELECT public.duyet_phieu_nhan_dien($1,$2,$3,$4,$5,$6::jsonb,$7,$8) AS result",
          [
            f.session,
            f.book,
            ticket,
            versions.ticket_version,
            versions.book_version,
            JSON.stringify(
              evidence.map((r) => ({
                rowId: String(r.ma_dong),
                value: r.ma_hoc_sinh === s.bao ? null : "8.0",
                reason:
                  r.ma_hoc_sinh === s.bao ? skipReason : "Đối chiếu ảnh giả",
              })),
            ),
            key,
            "e".repeat(64),
          ],
        ),
      );
    const cell = async (student: number) =>
      (
        await owner.query(
          "SELECT gia_tri::text AS value,trang_thai::text AS status,nguon_nhap::text AS source FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_hoc_sinh=$2",
          [f.book, student],
        )
      ).rows[0];

    // Lý do bắt buộc: dòng bỏ qua không có lý do thì cả phiếu bị từ chối, không ghi gì.
    for (const bad of ["", "   ", "x".repeat(501)])
      await assert.rejects(
        decide("skip-bad", bad),
        (error: { code?: string }) => error.code === "23514",
      );
    assert.equal((await cell(s.an)).value, null);
    assert.equal((await cell(s.bao)).value, "5.5");
    assert.equal(
      (
        await owner.query(
          "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [ticket],
        )
      ).rows[0].status,
      "CHO_DOI_CHIEU",
    );

    const result = (await decide("skip-ok", "Học sinh vắng, không ghi điểm"))
      .rows[0].result;
    assert.equal(result.status, "DA_DUYET");
    assert.equal(result.reviewedRows, 3);
    // Dòng bỏ qua không được tính là máy đúng.
    assert.equal(result.machineMatchedRows, 2);

    assert.deepEqual(await cell(s.an), {
      value: "8.0",
      status: "DA_DUYET",
      source: "NHAN_DIEN",
    });
    assert.deepEqual(await cell(s.cuong), {
      value: "8.0",
      status: "DA_DUYET",
      source: "NHAN_DIEN",
    });
    // Ô của học sinh bị bỏ qua giữ nguyên: giá trị, trạng thái và nguồn không đổi.
    assert.deepEqual(await cell(s.bao), {
      value: "5.5",
      status: "DA_DUYET",
      source: "NHAP_TAY",
    });
    // Học sinh không có dòng nào vẫn là NULL, không bị ghi 0.
    assert.equal((await cell(s.dat)).value, null);
    assert.equal((await cell(s.dat)).status, "CHUA_CO");
    // Lịch sử chỉ có hai bản ghi mới (hai ô được ghi), không có bản ghi cho ô bị bỏ qua.
    assert.equal(
      Number(
        (await owner.query("SELECT count(*) FROM lich_su_sua_diem")).rows[0]
          .count,
      ),
      historyBefore + 2,
    );
    const saved = (
      await owner.query(
        "SELECT ma_hoc_sinh,ma_diem,gia_tri_chot::text AS final,nguoi_duyet,thoi_diem_duyet IS NOT NULL AS has_time,ly_do_duyet FROM ket_qua_dong WHERE ma_phieu=$1",
        [ticket],
      )
    ).rows;
    const skipped = saved.find((r) => r.ma_hoc_sinh === s.bao)!;
    assert.equal(skipped.ma_diem, null);
    assert.equal(skipped.final, null);
    assert.equal(skipped.nguoi_duyet, f.teacherId);
    assert.equal(skipped.has_time, true);
    assert.equal(skipped.ly_do_duyet, "Học sinh vắng, không ghi điểm");
    const written = saved.filter((r) => r.ma_hoc_sinh !== s.bao);
    assert.ok(written.every((r) => r.ma_diem !== null && r.final === "8.0"));

    // Gửi lại cùng khóa idempotency trả đúng kết quả cũ, không ghi thêm.
    const repeated = (await decide("skip-ok", "Học sinh vắng, không ghi điểm"))
      .rows[0].result;
    assert.deepEqual(repeated, result);
    assert.equal(
      Number(
        (await owner.query("SELECT count(*) FROM lich_su_sua_diem")).rows[0]
          .count,
      ),
      historyBefore + 2,
    );

    // Ràng buộc DB: đã duyệt mà không ghi điểm thì bắt buộc có lý do.
    await assert.rejects(
      owner.query(
        "UPDATE ket_qua_dong SET ly_do_duyet=NULL WHERE ma_phieu=$1 AND ma_hoc_sinh=$2",
        [ticket, s.bao],
      ),
      (error: { code?: string }) => error.code === "23514",
    );
  } finally {
    await f.close();
  }
});
