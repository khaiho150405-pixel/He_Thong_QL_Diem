import assert from "node:assert/strict";
import { test } from "node:test";
import { createRosterFixture } from "./roster-fixture.js";

// ADR-0015: luu_ket_qua_nhan_dien tra học sinh theo danh_sach_phieu (STT), không theo ma_hoc_sinh.
test("recognition results map rows by roster STT and approval writes the right students", async () => {
  const f = await createRosterFixture();
  const { owner, students: s, valid } = f;
  try {
    const receipt = await f.createTicket(valid, "results-ok");
    const ticket = receipt.ticketId;
    const channel = (value: string) => ({
      rawOutput: value,
      value,
      confidence: "0.95",
      isBlank: false,
    });
    const row = (order: number, stt: number, extra: object = {}) => ({
      order,
      stt,
      sttOnPaper: stt,
      nameRead: "Họ tên đọc được giả",
      matchConfidence: 0.97,
      matchNote: "Khớp STT và họ tên",
      numeric: channel("8.0"),
      written: channel("8.0"),
      numericCropKey: `recognition/crops/${ticket}/${order}-numeric.png`,
      writtenCropKey: `recognition/crops/${ticket}/${order}-written.png`,
      nameCropKey: `recognition/crops/${ticket}/${order}-name.png`,
      comparison: "KHOP",
      reviewLevel: "XANH",
      suggestedSource: "SO",
      ...extra,
    });
    const save = (rows: unknown[]) =>
      f.serializable((query) =>
        query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
          ticket,
          "fake-test-v1",
          JSON.stringify(rows),
        ]),
      );
    const evidenceCount = async () =>
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM ket_qua_dong WHERE ma_phieu=$1",
            [ticket],
          )
        ).rows[0].count,
      );
    const status = async () =>
      (
        await owner.query(
          "SELECT trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [ticket],
        )
      ).rows[0].status as string;
    const malformed = (error: { code?: string }) => error.code === "23514";

    // Lớp đổi sau khi tạo phiếu (thêm học sinh): cách gán cũ theo ma_hoc_sinh sẽ lệch, snapshot thì không.
    await f.makeStudent(f.cls, "Mới Vào Lớp");

    const bad: Array<[string, unknown[]]> = [
      ["không có dòng nào", []],
      ["nhiều dòng hơn sĩ số snapshot", [1, 2, 3, 4, 5].map((n) => row(n, n))],
      ["STT ngoài snapshot", [row(1, 5)]],
      ["STT bằng 0", [row(1, 0)]],
      ["trùng STT giữa hai dòng", [row(1, 2), row(2, 2)]],
      ["trùng vị trí trên ảnh", [row(1, 1), row(1, 2)]],
      ["thiếu stt", [{ ...row(1, 1), stt: undefined }]],
      ["độ tin cậy ghép ngoài 0..1", [row(1, 1, { matchConfidence: 1.5 })]],
      ["STT trên giấy không hợp lệ", [row(1, 1, { sttOnPaper: 0 })]],
      [
        "khóa ảnh họ tên của phiếu khác",
        [row(1, 1, { nameCropKey: "recognition/crops/1/1-name.png" })],
      ],
      ["kênh gợi ý không hợp lệ", [row(1, 1, { suggestedSource: "BOTH" })]],
      ["họ tên đọc quá dài", [row(1, 1, { nameRead: "x".repeat(151) })]],
      ["ghi chú ghép quá dài", [row(1, 1, { matchNote: "x".repeat(201) })]],
    ];
    for (const [label, rows] of bad) {
      await assert.rejects(save(rows), malformed, label);
      assert.equal(await evidenceCount(), 0, label);
      assert.equal(await status(), "DANG_XU_LY", label);
    }

    // Vị trí trên ảnh ≠ STT; STT 2 (một dòng gạch) không có trong kết quả.
    await save([
      row(1, 3, { nameRead: "Lê Văn Cường", matchNote: "Khớp tên" }),
      row(2, 1),
      row(3, 4, {
        nameCropKey: null,
        sttOnPaper: null,
        matchConfidence: null,
        reviewLevel: "DO",
        suggestedSource: null,
      }),
    ]);
    assert.equal(await status(), "CHO_DOI_CHIEU");
    const saved = await owner.query(
      "SELECT ma_dong,thu_tu_dong,ma_hoc_sinh,stt_giay,ho_ten_doc_duoc,do_tin_cay_ghep,duong_dan_anh_o_ten,ghi_chu_ghep,kenh_goi_y FROM ket_qua_dong WHERE ma_phieu=$1 ORDER BY thu_tu_dong",
      [ticket],
    );
    assert.deepEqual(
      saved.rows.map((r) => [r.thu_tu_dong, r.ma_hoc_sinh]),
      [
        [1, s.cuong],
        [2, s.an],
        [3, s.dat],
      ],
    );
    assert.deepEqual(
      [
        saved.rows[0].stt_giay,
        saved.rows[0].ho_ten_doc_duoc,
        saved.rows[0].do_tin_cay_ghep,
        saved.rows[0].duong_dan_anh_o_ten,
        saved.rows[0].ghi_chu_ghep,
      ],
      [
        3,
        "Lê Văn Cường",
        "0.9700",
        `recognition/crops/${ticket}/1-name.png`,
        "Khớp tên",
      ],
    );
    // Kênh gợi ý được lưu theo dòng; dòng Đỏ không có gợi ý.
    assert.deepEqual(
      saved.rows.map((r) => r.kenh_goi_y),
      ["SO", "SO", null],
    );
    assert.deepEqual(
      [
        saved.rows[2].stt_giay,
        saved.rows[2].do_tin_cay_ghep,
        saved.rows[2].duong_dan_anh_o_ten,
      ],
      [null, null, null],
    );
    assert.equal(
      (
        await owner.query(
          "SELECT so_dong_nhan_dien FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [ticket],
        )
      ).rows[0].so_dong_nhan_dien,
      3,
    );
    // Máy chỉ đề xuất: chưa có điểm chính thức.
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
            [f.book],
          )
        ).rows[0].count,
      ),
      0,
    );
    // Gọi lại là idempotent: không thêm dòng.
    await save([row(1, 3), row(2, 1), row(3, 4)]);
    assert.equal(await evidenceCount(), 3);

    // Duyệt: điểm vào đúng học sinh theo snapshot.
    const versions = (
      await owner.query(
        "SELECT t.version AS ticket_version,b.version AS book_version FROM phieu_nhan_dien t JOIN bang_diem b USING(ma_bang_diem) WHERE t.ma_phieu=$1",
        [ticket],
      )
    ).rows[0];
    const grade: Record<number, string> = {
      [s.cuong]: "7.5",
      [s.an]: "9.0",
      [s.dat]: "6.0",
    };
    const decisions = saved.rows.map((r) => ({
      rowId: String(r.ma_dong),
      value: grade[r.ma_hoc_sinh],
      reason: "Đối chiếu ảnh giả",
    }));
    await f.serializable((query) =>
      query(
        "SELECT public.duyet_phieu_nhan_dien($1,$2,$3,$4,$5,$6::jsonb,$7,$8)",
        [
          f.session,
          f.book,
          ticket,
          versions.ticket_version,
          versions.book_version,
          JSON.stringify(decisions),
          "approve-ok",
          "d".repeat(64),
        ],
      ),
    );
    const official = await owner.query(
      "SELECT ma_hoc_sinh,gia_tri::text AS value,trang_thai::text AS status FROM diem_thanh_phan WHERE ma_bang_diem=$1 ORDER BY ma_hoc_sinh",
      [f.book],
    );
    const byStudent = new Map(
      official.rows.map((r) => [r.ma_hoc_sinh as number, r]),
    );
    assert.equal(byStudent.get(s.cuong)?.value, "7.5");
    assert.equal(byStudent.get(s.an)?.value, "9.0");
    assert.equal(byStudent.get(s.dat)?.value, "6.0");
    // Học sinh không có dòng (STT 2) giữ NULL, không bị ghi 0.
    assert.equal(byStudent.get(s.bao)?.value, null);
    assert.equal(byStudent.get(s.bao)?.status, "CHUA_CO");
    assert.equal(await status(), "DA_DUYET");
  } finally {
    await f.close();
  }
});
