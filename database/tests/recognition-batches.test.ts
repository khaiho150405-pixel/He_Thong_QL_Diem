import assert from "node:assert/strict";
import { createHash, randomBytes } from "node:crypto";
import { test } from "node:test";
import {
  TX1_VALUES,
  TX2_VALUES,
  createBatchFixture,
  createTemplate,
  fakePages,
  fullResults,
  makeSession,
  oneChannelRow,
  twoChannelRow,
} from "../../apps/api/test/integration/batch-fixture.js";

// Lô nhận dạng nhiều trang (ADR-0016 mục 3, migration 202610200001): tao_lo_nhan_dien, luu_ket_qua_lo,
// danh_dau_lo_nhan_dien_loi, huy_lo_nhan_dien, ràng buộc bảng và quyền runtime. Dữ liệu hoàn toàn giả; chỉ chạy trên DB *_test.
type Failure = { code?: string; message?: string };
const failsWith = (code: string, text: string) => (error: Failure) =>
  error.code === code && String(error.message).includes(text);

test("a batch creates one ticket per component, the pages, the roster copies and ONE outbox event in one transaction", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const pages = fakePages(2);
    const receipt = await t.createBatch({ pages });
    assert.match(receipt.batchId, /^[1-9][0-9]*$/);
    assert.equal(receipt.jobId, `recognition-batch-${receipt.batchId}`);
    assert.equal(receipt.status, "DANG_XU_LY");
    assert.deepEqual(
      receipt.storedObjectKeys,
      pages.map((p) => p.objectKey),
    );
    assert.deepEqual(
      receipt.tickets
        .map((ticket) => [ticket.templateColumnIndex, ticket.componentId])
        .sort(),
      [
        [2, t.component1],
        [4, t.component2],
      ],
    );

    const batch = (
      await f.owner.query(
        "SELECT ma_bang_diem, ma_mau, nguoi_tai, so_trang, trang_thai::text AS status, version FROM lo_nhan_dien WHERE ma_lo=$1",
        [receipt.batchId],
      )
    ).rows[0];
    assert.deepEqual(batch, {
      ma_bang_diem: f.book,
      ma_mau: t.template,
      nguoi_tai: f.teacherId,
      so_trang: 2,
      status: "DANG_XU_LY",
      version: 0,
    });
    const stored = (
      await f.owner.query(
        "SELECT so_trang, ma_bam_tep, duong_dan_anh FROM trang_lo_nhan_dien WHERE ma_lo=$1 ORDER BY so_trang",
        [receipt.batchId],
      )
    ).rows;
    assert.deepEqual(
      stored.map((row) => [row.so_trang, row.ma_bam_tep, row.duong_dan_anh]),
      pages.map((p) => [p.page, p.checksum, p.objectKey]),
    );

    const tickets = (
      await f.owner.query(
        "SELECT ma_phieu, ma_thanh_phan, ma_mau, chi_so_cot_mau, ma_bam_tep, duong_dan_anh_goc, so_dong_khai_bao, trang_thai::text AS status FROM phieu_nhan_dien WHERE ma_lo=$1 ORDER BY chi_so_cot_mau",
        [receipt.batchId],
      )
    ).rows;
    assert.equal(tickets.length, 2);
    const pageHashes = pages.map((p) => p.checksum).join(",");
    for (const ticket of tickets) {
      assert.equal(ticket.ma_mau, t.template);
      assert.equal(ticket.duong_dan_anh_goc, pages[0]!.objectKey);
      assert.equal(ticket.so_dong_khai_bao, 4);
      assert.equal(ticket.status, "DANG_XU_LY");
      // ma_bam_tep của phiếu thuộc lô = SHA-256(checksum các trang theo thứ tự ':' mã thành phần).
      assert.equal(
        ticket.ma_bam_tep,
        createHash("sha256")
          .update(`${pageHashes}:${ticket.ma_thanh_phan}`)
          .digest("hex"),
      );
      const roster = (
        await f.owner.query(
          "SELECT stt, ma_hoc_sinh, ho_ten FROM danh_sach_phieu WHERE ma_phieu=$1 ORDER BY stt",
          [ticket.ma_phieu],
        )
      ).rows;
      assert.deepEqual(
        roster.map((row) => [row.stt, row.ma_hoc_sinh, row.ho_ten]),
        f.valid.map((entry) => [entry.stt, entry.studentId, entry.fullName]),
      );
    }
    assert.notEqual(tickets[0]!.ma_bam_tep, tickets[1]!.ma_bam_tep);

    // MỘT sự kiện cho cả lô, không có sự kiện theo phiếu.
    const events = (
      await f.owner.query(
        "SELECT loai_su_kien, ma_phieu, ma_lo::text AS batch, du_lieu FROM recognition_outbox WHERE ma_lo=$1 OR ma_phieu IN (SELECT ma_phieu FROM phieu_nhan_dien WHERE ma_lo=$1)",
        [receipt.batchId],
      )
    ).rows;
    assert.equal(events.length, 1);
    assert.equal(events[0].loai_su_kien, "RECOGNITION_BATCH_REQUESTED");
    assert.equal(events[0].ma_phieu, null);
    assert.equal(events[0].batch, receipt.batchId);
    assert.equal(events[0].du_lieu.batchId, receipt.batchId);
    assert.equal(events[0].du_lieu.jobId, receipt.jobId);

    const audits = (
      await f.owner.query(
        "SELECT hanh_dong, count(*)::int AS n FROM nhat_ky_bao_mat WHERE ma_tac_nhan=$1 AND hanh_dong IN ('RECOGNITION_UPLOADED','RECOGNITION_BATCH_UPLOADED') GROUP BY hanh_dong ORDER BY hanh_dong",
        [f.teacherId],
      )
    ).rows;
    assert.deepEqual(audits, [
      { hanh_dong: "RECOGNITION_BATCH_UPLOADED", n: 1 },
      { hanh_dong: "RECOGNITION_UPLOADED", n: 2 },
    ]);
    // Máy chỉ đề xuất: tạo lô không đụng tới điểm chính thức.
    assert.equal(
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
            [f.book],
          )
        ).rows[0].count,
      ),
      0,
    );
  } finally {
    await t.close();
  }
});

test("replaying the same key returns the same receipt without writing; the same key with another request is a mismatch", async () => {
  const t = await createBatchFixture();
  try {
    const pages = fakePages(2);
    const hash = randomBytes(32).toString("hex");
    const first = await t.createBatch({ pages, key: "batch-replay", hash });
    const before = await t.totals();
    const replay = await t.createBatch({
      pages: fakePages(2),
      key: "batch-replay",
      hash,
    });
    assert.deepEqual(replay, first);
    assert.deepEqual(await t.totals(), before);
    await assert.rejects(
      t.createBatch({
        pages,
        key: "batch-replay",
        hash: randomBytes(32).toString("hex"),
      }),
      failsWith("23505", "IDEMPOTENCY_MISMATCH"),
    );
    assert.deepEqual(await t.totals(), before);
  } finally {
    await t.close();
  }
});

test("a failure on the second component rolls the whole batch back", async () => {
  const t = await createBatchFixture();
  try {
    // Thành phần TX2 đang chờ (lô một thành phần) nên lô hai thành phần tạo xong phiếu TX1 rồi mới gặp lỗi ở TX2.
    await t.createBatch({
      components: [t.components[1]],
      pages: fakePages(1),
    });
    const before = await t.totals();
    assert.equal(before.batches, 1);
    assert.equal(before.tickets, 1);
    await assert.rejects(
      t.createBatch({ pages: fakePages(2) }),
      failsWith("23514", "RECOGNITION_ALREADY_PENDING"),
    );
    // Không còn lô, trang, phiếu, danh sách lớp, sự kiện outbox, audit hay khóa idempotency nào của lần thử lỗi.
    assert.deepEqual(await t.totals(), before);
  } finally {
    await t.close();
  }
});

test("invalid requests are rejected with stable codes and write nothing", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const before = await t.totals();
    const column = (index: number, component: number) => ({
      templateColumnIndex: index,
      componentId: component,
    });
    const inactive = await createTemplate(f.owner, f.runtime, false);
    const unassigned = await makeSession(f.owner, "GIAO_VIEN", "batch_other");
    const student = await makeSession(f.owner, "HOC_SINH", "batch_student");
    const otherSubject: number = (
      await f.owner.query(
        "INSERT INTO mon_hoc(ten_mon,so_tiet_tuan) VALUES($1,2) RETURNING ma_mon",
        [`BATCH-${randomBytes(4).toString("hex")}`],
      )
    ).rows[0].ma_mon;
    const foreignComponent: number = (
      await f.owner.query(
        "INSERT INTO thanh_phan_diem(ma_mon,ten_thanh_phan,he_so,thu_tu_hien_thi) VALUES($1,'Khác môn',1,1) RETURNING ma_thanh_phan",
        [otherSubject],
      )
    ).rows[0].ma_thanh_phan;

    const cases: Array<
      [string, Parameters<typeof t.createBatch>[0], string, string]
    > = [
      ["five pages", { pages: fakePages(5) }, "23514", "TOO_MANY_PAGES"],
      ["no page", { pages: [] }, "23514", "INVALID_RECOGNITION_REQUEST"],
      [
        "no component",
        { components: [] },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "page numbers not 1..n",
        {
          pages: fakePages(2).map((p) => ({ ...p, page: p.page + 1 })),
        },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "bad object key",
        {
          pages: fakePages(2).map((p) => ({
            ...p,
            objectKey: "../../etc/passwd",
          })),
        },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "the same image on two pages",
        {
          pages: (() => {
            const [one, two] = fakePages(2);
            return [one!, { ...two!, checksum: one!.checksum }];
          })(),
        },
        "23505",
        "DUPLICATE_FILE",
      ],
      [
        "the same component twice",
        {
          components: [column(2, t.component1), column(4, t.component1)],
        },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "a column that is not a grade column",
        { components: [column(3, t.component1)] },
        "23514",
        "COMPONENT_NOT_MAPPABLE",
      ],
      [
        "an unknown column",
        { components: [column(40, t.component1)] },
        "23514",
        "COMPONENT_NOT_MAPPABLE",
      ],
      [
        "swapped components (TX1 column with the TX2 component)",
        {
          components: [column(2, t.component2), column(4, t.component1)],
        },
        "23514",
        "COMPONENT_NOT_MAPPABLE",
      ],
      [
        "a component of another subject",
        { components: [column(2, foreignComponent)] },
        "23514",
        "COMPONENT_NOT_MAPPABLE",
      ],
      [
        "a component that does not exist",
        { components: [column(2, 2_000_000_000)] },
        "23514",
        "COMPONENT_NOT_MAPPABLE",
      ],
      [
        "a template that is not in use",
        { templateId: inactive },
        "23514",
        "TEMPLATE_INACTIVE",
      ],
      [
        "an unknown template",
        { templateId: 2_000_000_000 },
        "P0002",
        "TEMPLATE_NOT_FOUND",
      ],
      ["an unknown gradebook", { book: 2_000_000_000 }, "P0002", "NOT_FOUND"],
      [
        "a roster that is not the class",
        { roster: f.valid.slice(0, 3) },
        "23514",
        "INVALID_ROSTER_SNAPSHOT",
      ],
      [
        "a bad idempotency key",
        { key: "bad key!" },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "a bad request hash",
        { hash: "not-a-hash" },
        "23514",
        "INVALID_RECOGNITION_REQUEST",
      ],
      [
        "a teacher without an assignment",
        { session: unassigned.session },
        "42501",
        "FORBIDDEN",
      ],
      ["a student session", { session: student.session }, "42501", "FORBIDDEN"],
      ["an unknown session", { session: "f".repeat(64) }, "42501", "FORBIDDEN"],
    ];
    for (const [label, options, code, text] of cases)
      await assert.rejects(
        t.createBatch(options),
        failsWith(code, text),
        label,
      );
    // Ngoài giao dịch SERIALIZABLE.
    await assert.rejects(
      f.runtime.query(
        "SELECT public.tao_lo_nhan_dien($1,$2,$3,'[]'::jsonb,'[]'::jsonb,'[]'::jsonb,'k','h')",
        [f.session, f.book, t.template],
      ),
      failsWith("25001", "SERIALIZABLE_REQUIRED"),
    );
    assert.deepEqual(await t.totals(), before);
  } finally {
    await t.close();
  }
});

test("pending components and re-uploads are refused; cancelling frees them (partial unique checksum)", async () => {
  const t = await createBatchFixture();
  try {
    const pages = fakePages(2);
    const first = await t.createBatch({ pages });
    // Cùng ảnh, cùng thành phần: tải trùng.
    await assert.rejects(
      t.createBatch({ pages }),
      failsWith("23505", "DUPLICATE_FILE"),
    );
    // Ảnh khác nhưng thành phần đang chờ.
    await assert.rejects(
      t.createBatch({ pages: fakePages(2) }),
      failsWith("23514", "RECOGNITION_ALREADY_PENDING"),
    );
    await t.cancelBatch(first.batchId);
    // Hủy xong tải lại đúng ảnh được.
    const again = await t.createBatch({ pages });
    assert.notEqual(again.batchId, first.batchId);
  } finally {
    await t.close();
  }
});

test("results are written for every ticket of the batch at once, with the page of every row and only the ticket's own column", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    await t.saveResults(receipt.batchId, fullResults(receipt));

    assert.deepEqual(await t.batchRow(receipt.batchId), {
      status: "XONG",
      ma_loi: null,
      trang_loi: null,
      so_trang: 2,
      version: 1,
    });
    const tx1 = receipt.tickets.find((x) => x.templateColumnIndex === 2)!;
    const tx2 = receipt.tickets.find((x) => x.templateColumnIndex === 4)!;
    for (const ticket of [tx1, tx2])
      assert.equal(
        (await t.ticketStatus(ticket.ticketId)).status,
        "CHO_DOI_CHIEU",
      );

    const one = await t.evidence(tx1.ticketId);
    const two = await t.evidence(tx2.ticketId);
    const studentOfStt = f.valid.map((entry) => entry.studentId);
    // thu_tu_dong = (trang-1)*1000 + vị trí; so_trang đúng; học sinh theo STT của danh sách chốt.
    assert.deepEqual(
      one.map((row) => [row.thu_tu_dong, row.so_trang, row.ma_hoc_sinh]),
      [
        [1, 1, studentOfStt[0]],
        [2, 1, studentOfStt[1]],
        [1001, 2, studentOfStt[2]],
        [1002, 2, studentOfStt[3]],
      ],
    );
    assert.deepEqual(
      one.map((row) => row.so_trang),
      two.map((row) => row.so_trang),
    );
    // AC-4: mỗi phiếu chỉ chứa giá trị của đúng cột của nó (hai cột có giá trị khác nhau).
    assert.deepEqual(
      one.map((row) => row.a),
      [...TX1_VALUES],
    );
    assert.deepEqual(
      two.map((row) => row.a),
      [...TX2_VALUES],
    );
    // AC-5: cột một kênh không Xanh, không có kênh chữ, ảnh ô chữ trống; cột hai kênh có kênh chữ.
    assert.equal(
      two.some((row) => row.level === "XANH"),
      false,
    );
    assert.deepEqual(
      two.map((row) => [row.b, row.duong_dan_anh_o_chu]),
      two.map(() => [null, null]),
    );
    assert.equal(
      one.every((row) => row.level === "XANH"),
      true,
    );
    assert.equal(
      one.every((row) => row.duong_dan_anh_o_chu !== null),
      true,
    );
    // Máy chỉ đề xuất: chưa có điểm chính thức.
    assert.equal(
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND gia_tri IS NOT NULL",
            [f.book],
          )
        ).rows[0].count,
      ),
      0,
    );

    // Ghi lại là bỏ qua: lô đã XONG.
    await t.saveResults(receipt.batchId, fullResults(receipt));
    assert.equal((await t.evidence(tx1.ticketId)).length, 4);
    assert.equal((await t.batchRow(receipt.batchId)).version, 1);
  } finally {
    await t.close();
  }
});

test("a red row never keeps a suggestion and a blank cell is read as unreadable, not as a value", async () => {
  const t = await createBatchFixture();
  try {
    const receipt = await t.createBatch();
    const results = fullResults(receipt);
    const tx1 = results[0]!;
    // Ô trống: không đọc được, Đỏ, không gợi ý. Dòng khác bị hạ Đỏ do ghép học sinh vẫn không lưu gợi ý.
    tx1.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, null);
    tx1.rows[1] = twoChannelRow(tx1.ticketId, 1, 2, 2, "7.0", {
      reviewLevel: "DO",
      matchLevel: "DO",
    });
    await t.saveResults(receipt.batchId, results);
    const rows = await t.evidence(tx1.ticketId);
    assert.deepEqual(
      rows.slice(0, 2).map((row) => [row.level, row.a, row.kenh_goi_y]),
      [
        ["DO", null, null],
        ["DO", "7.0", null],
      ],
    );
  } finally {
    await t.close();
  }
});

test("malformed results are rejected whole: nothing is written for any ticket of the batch", async () => {
  const t = await createBatchFixture();
  try {
    const receipt = await t.createBatch();
    const tx1 = receipt.tickets.find((x) => x.templateColumnIndex === 2)!;
    const tx2 = receipt.tickets.find((x) => x.templateColumnIndex === 4)!;

    const mutate = (
      change: (results: ReturnType<typeof fullResults>) => void,
    ) => {
      const results = fullResults(receipt);
      change(results);
      return results;
    };
    const cases: Array<[string, unknown]> = [
      [
        "one-channel column marked green",
        mutate((r) => {
          r[1]!.rows[0] = oneChannelRow(tx2.ticketId, 1, 1, 1, "1.0", {
            reviewLevel: "XANH",
          });
        }),
      ],
      [
        "one-channel column agreeing with itself",
        mutate((r) => {
          r[1]!.rows[0] = oneChannelRow(tx2.ticketId, 1, 1, 1, "1.0", {
            comparison: "KHOP",
          });
        }),
      ],
      [
        "one-channel column suggesting the written channel",
        mutate((r) => {
          r[1]!.rows[0] = oneChannelRow(tx2.ticketId, 1, 1, 1, "1.0", {
            suggestedSource: "CHU",
          });
        }),
      ],
      [
        "one-channel column with a written crop",
        mutate((r) => {
          r[1]!.rows[0] = oneChannelRow(tx2.ticketId, 1, 1, 1, "1.0", {
            writtenCropKey: `recognition/crops/${tx2.ticketId}/1-written.png`,
          });
        }),
      ],
      [
        "one-channel column with a written value",
        mutate((r) => {
          r[1]!.rows[0] = oneChannelRow(tx2.ticketId, 1, 1, 1, "1.0", {
            written: {
              rawOutput: "một",
              value: "1.0",
              confidence: "0.9",
              isBlank: false,
            },
          });
        }),
      ],
      [
        "two-channel column without a written crop",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, "6.0", {
            writtenCropKey: null,
          });
        }),
      ],
      [
        "unreadable cell that is not red",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, null, {
            reviewLevel: "VANG",
          });
        }),
      ],
      [
        "unreadable cell with a suggestion",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, null, {
            suggestedSource: "SO",
          });
        }),
      ],
      [
        "green row that is not in agreement",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, "6.0", {
            comparison: "LECH",
          });
        }),
      ],
      [
        "the same student twice on two pages",
        mutate((r) => {
          r[0]!.rows[2] = twoChannelRow(tx1.ticketId, 2, 1, 1, "8.0");
        }),
      ],
      [
        "a page beyond the batch",
        mutate((r) => {
          r[0]!.rows[3] = twoChannelRow(tx1.ticketId, 3, 2, 4, "9.0");
        }),
      ],
      [
        "an order outside the row's page",
        mutate((r) => {
          r[0]!.rows[3] = twoChannelRow(tx1.ticketId, 2, 2, 4, "9.0", {
            order: 2,
            numericCropKey: `recognition/crops/${tx1.ticketId}/2-numeric.png`,
            writtenCropKey: `recognition/crops/${tx1.ticketId}/2-written.png`,
            nameCropKey: `recognition/crops/${tx1.ticketId}/2-name.png`,
          });
        }),
      ],
      [
        "a crop key of another ticket",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 1, "6.0", {
            numericCropKey: `recognition/crops/${tx2.ticketId}/1-numeric.png`,
          });
        }),
      ],
      [
        "an STT outside the roster",
        mutate((r) => {
          r[0]!.rows[0] = twoChannelRow(tx1.ticketId, 1, 1, 9, "6.0");
        }),
      ],
      [
        "a ticket twice",
        mutate((r) => {
          r.push(r[0]!);
        }),
      ],
      [
        "a ticket that is not in the batch",
        mutate((r) => {
          r[1]!.ticketId = "9000000000000000000";
        }),
      ],
      [
        "one ticket of the batch missing",
        mutate((r) => {
          r.pop();
        }),
      ],
    ];
    for (const [label, results] of cases) {
      await assert.rejects(
        t.saveResults(receipt.batchId, results),
        failsWith("23514", "MALFORMED_RECOGNITION_RESULT"),
        label,
      );
      assert.equal((await t.evidence(tx1.ticketId)).length, 0, label);
      assert.equal((await t.evidence(tx2.ticketId)).length, 0, label);
      assert.equal(
        (await t.batchRow(receipt.batchId)).status,
        "DANG_XU_LY",
        label,
      );
      assert.equal(
        (await t.ticketStatus(tx1.ticketId)).status,
        "DANG_XU_LY",
        label,
      );
    }
    // Phiếu không có dòng nào: số dòng không hợp lệ, cũng không ghi gì.
    await assert.rejects(
      t.saveResults(
        receipt.batchId,
        mutate((r) => {
          r[0]!.rows = [];
        }),
      ),
      failsWith("23514", "GRID_ROW_COUNT_MISMATCH"),
    );
    assert.equal((await t.evidence(tx2.ticketId)).length, 0);
    // Phiếu của lô không ghi được qua hàm một ảnh, và dòng của phiếu thường không được mang số trang.
    await assert.rejects(
      t.f.serializable((query) =>
        query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
          tx1.ticketId,
          "fake-v1",
          JSON.stringify([
            {
              order: 1,
              stt: 1,
              sttOnPaper: 1,
              nameRead: "x",
              matchConfidence: 0.9,
              matchNote: null,
              numeric: {
                rawOutput: "6.0",
                value: "6.0",
                confidence: "0.9",
                isBlank: false,
              },
              written: {
                rawOutput: "sáu",
                value: "6.0",
                confidence: "0.9",
                isBlank: false,
              },
              numericCropKey: `recognition/crops/${tx1.ticketId}/1-numeric.png`,
              writtenCropKey: `recognition/crops/${tx1.ticketId}/1-written.png`,
              nameCropKey: null,
              comparison: "KHOP",
              reviewLevel: "XANH",
              suggestedSource: "SO",
            },
          ]),
        ]),
      ),
      failsWith("23514", "BATCH_ROW_PAGE_MISMATCH"),
    );
    assert.equal((await t.evidence(tx1.ticketId)).length, 0);
    assert.equal((await t.ticketStatus(tx1.ticketId)).status, "DANG_XU_LY");
  } finally {
    await t.close();
  }
});

test("a rejected page fails the whole batch with the same code on every ticket and no row", async () => {
  const t = await createBatchFixture();
  try {
    const receipt = await t.createBatch();
    await assert.rejects(
      t.failBatch(receipt.batchId, "bad code", 1),
      failsWith("23514", "INVALID_ERROR_CODE"),
    );
    await assert.rejects(
      t.failBatch(receipt.batchId, "TEMPLATE_MISMATCH", 3),
      failsWith("23514", "INVALID_ERROR_CODE"),
    );
    await assert.rejects(
      t.failBatch("2000000000", "TEMPLATE_MISMATCH", 1),
      failsWith("P0002", "BATCH_NOT_FOUND"),
    );
    await t.failBatch(receipt.batchId, "TEMPLATE_MISMATCH", 2);
    assert.deepEqual(await t.batchRow(receipt.batchId), {
      status: "LOI",
      ma_loi: "TEMPLATE_MISMATCH",
      trang_loi: 2,
      so_trang: 2,
      version: 1,
    });
    for (const ticket of receipt.tickets) {
      assert.deepEqual(await t.ticketStatus(ticket.ticketId), {
        status: "LOI",
        ma_loi: "TEMPLATE_MISMATCH",
      });
      assert.equal((await t.evidence(ticket.ticketId)).length, 0);
    }
    // Lỗi thì không ghi kết quả được nữa, và đánh dấu lại là bỏ qua.
    await assert.rejects(
      t.saveResults(receipt.batchId, fullResults(receipt)),
      failsWith("23514", "BATCH_NOT_PROCESSING"),
    );
    await t.failBatch(receipt.batchId, "GRID_NOT_FOUND", 1);
    assert.equal(
      (await t.batchRow(receipt.batchId)).ma_loi,
      "TEMPLATE_MISMATCH",
    );
    // Lỗi không gắn với trang (ghép học sinh).
    const second = await t.createBatch();
    await t.failBatch(second.batchId, "ROW_MATCH_FAILED", null);
    const failed = await t.batchRow(second.batchId);
    assert.equal(failed.ma_loi, "ROW_MATCH_FAILED");
    assert.equal(failed.trang_loi, null);
    // Thành phần của lô LOI không còn bị coi là đang chờ.
    await t.createBatch();
  } finally {
    await t.close();
  }
});

test("each ticket of a batch is approved on its own with the existing function and writes only its own component", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    await t.saveResults(receipt.batchId, fullResults(receipt));
    const tx1 = receipt.tickets.find((x) => x.templateColumnIndex === 2)!;
    const tx2 = receipt.tickets.find((x) => x.templateColumnIndex === 4)!;
    const decisions = async (ticketId: string, values: readonly string[]) =>
      (await t.evidence(ticketId)).map((row, index) => ({
        rowId: String(row.ma_dong),
        value: values[index],
        reason: "Đối chiếu ảnh giả",
      }));
    const cells = async (component: number) =>
      new Map(
        (
          await f.owner.query(
            "SELECT ma_hoc_sinh, gia_tri::text AS value, trang_thai::text AS status FROM diem_thanh_phan WHERE ma_bang_diem=$1 AND ma_thanh_phan=$2",
            [f.book, component],
          )
        ).rows.map((r) => [r.ma_hoc_sinh as number, r]),
      );

    await t.approve(
      tx1.ticketId,
      await decisions(tx1.ticketId, TX1_VALUES),
      "batch-approve-1",
    );
    assert.equal((await t.ticketStatus(tx1.ticketId)).status, "DA_DUYET");
    // Phiếu kia và thành phần kia chưa bị đụng tới.
    assert.equal((await t.ticketStatus(tx2.ticketId)).status, "CHO_DOI_CHIEU");
    const first = await cells(t.component1);
    f.valid.forEach((entry, index) => {
      assert.equal(first.get(entry.studentId)?.value, TX1_VALUES[index]);
      assert.equal(first.get(entry.studentId)?.status, "DA_DUYET");
    });
    for (const cell of (await cells(t.component2)).values()) {
      assert.equal(cell.value, null);
      assert.equal(cell.status, "CHUA_CO");
    }

    await t.approve(
      tx2.ticketId,
      await decisions(tx2.ticketId, TX2_VALUES),
      "batch-approve-2",
    );
    const second = await cells(t.component2);
    f.valid.forEach((entry, index) => {
      assert.equal(second.get(entry.studentId)?.value, TX2_VALUES[index]);
    });
    // Điểm cột TX1 không đổi sau khi duyệt phiếu thứ hai.
    const firstAgain = await cells(t.component1);
    f.valid.forEach((entry, index) => {
      assert.equal(firstAgain.get(entry.studentId)?.value, TX1_VALUES[index]);
    });
    assert.equal(
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM lich_su_sua_diem h JOIN diem_thanh_phan d USING(ma_diem) WHERE d.ma_bang_diem=$1",
            [f.book],
          )
        ).rows[0].count,
      ),
      8,
    );
    // Lô đã duyệt hết thì không còn gì để hủy.
    await assert.rejects(
      t.cancelBatch(receipt.batchId),
      failsWith("23514", "TICKET_ALREADY_APPROVED"),
    );
  } finally {
    await t.close();
  }
});

test("cancelling a batch is soft, idempotent and scoped to its own gradebook", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    const key = "batch-cancel-1";
    const hash = randomBytes(32).toString("hex");
    const unassigned = await makeSession(f.owner, "GIAO_VIEN", "batch_cancel");
    // IDOR: giáo viên không được phân công, lô của bảng điểm khác, bảng điểm/lô không tồn tại.
    await assert.rejects(
      t.cancelBatch(receipt.batchId, { session: unassigned.session }),
      failsWith("42501", "FORBIDDEN"),
    );
    await assert.rejects(
      t.cancelBatch(receipt.batchId, { book: 2_000_000_000 }),
      failsWith("P0002", "NOT_FOUND"),
    );
    await assert.rejects(
      t.cancelBatch("2000000000"),
      failsWith("P0002", "BATCH_NOT_FOUND"),
    );
    await assert.rejects(
      t.cancelBatch(receipt.batchId, { reason: "   " }),
      failsWith("23514", "INVALID_CANCEL_REQUEST"),
    );
    assert.equal((await t.batchRow(receipt.batchId)).status, "DANG_XU_LY");

    const cancelled = await t.cancelBatch(receipt.batchId, {
      reason: "  Chụp nhầm bảng  ",
      key,
      hash,
    });
    assert.deepEqual(cancelled, {
      batchId: receipt.batchId,
      batchVersion: 1,
      gradebookId: f.book,
      status: "DA_HUY",
      cancelledTickets: 2,
    });
    const row = (
      await f.owner.query(
        "SELECT trang_thai::text AS status, ly_do_huy, nguoi_huy, thoi_diem_huy IS NOT NULL AS has_time FROM lo_nhan_dien WHERE ma_lo=$1",
        [receipt.batchId],
      )
    ).rows[0];
    assert.deepEqual(row, {
      status: "DA_HUY",
      ly_do_huy: "Chụp nhầm bảng",
      nguoi_huy: f.teacherId,
      has_time: true,
    });
    for (const ticket of receipt.tickets)
      assert.equal((await t.ticketStatus(ticket.ticketId)).status, "DA_HUY");
    // Dispatcher không gửi lại sự kiện của lô đã hủy.
    assert.equal(
      Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM recognition_outbox WHERE ma_lo=$1 AND da_gui_luc IS NULL",
            [receipt.batchId],
          )
        ).rows[0].count,
      ),
      0,
    );
    // Cùng khóa -> cùng kết quả; khóa khác -> vẫn là lô đã hủy, không đổi lý do; cùng khóa khác nội dung -> từ chối.
    assert.deepEqual(
      await t.cancelBatch(receipt.batchId, {
        reason: "Chụp nhầm bảng",
        key,
        hash,
      }),
      cancelled,
    );
    const again = await t.cancelBatch(receipt.batchId, {
      reason: "Lý do khác",
    });
    assert.equal(again.status, "DA_HUY");
    assert.equal(again.batchVersion, 1);
    assert.equal(again.cancelledTickets, 0);
    await assert.rejects(
      t.cancelBatch(receipt.batchId, {
        reason: "Lý do khác",
        key,
        hash: randomBytes(32).toString("hex"),
      }),
      failsWith("23505", "IDEMPOTENCY_MISMATCH"),
    );
    // Kết quả đến muộn của worker bị bỏ qua: không dòng nào được ghi, không lỗi.
    await t.saveResults(receipt.batchId, fullResults(receipt));
    for (const ticket of receipt.tickets)
      assert.equal((await t.evidence(ticket.ticketId)).length, 0);
    assert.equal((await t.batchRow(receipt.batchId)).status, "DA_HUY");
  } finally {
    await t.close();
  }
});

test("the uploader who lost the assignment can no longer cancel the batch; nothing changes", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    const count = async (sql: string) =>
      Number((await f.owner.query(sql, [receipt.batchId])).rows[0].count);
    const snapshot = async () => ({
      batch: await t.batchRow(receipt.batchId),
      tickets: await Promise.all(
        receipt.tickets.map((ticket) => t.ticketStatus(ticket.ticketId)),
      ),
      audit: Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM nhat_ky_bao_mat WHERE hanh_dong IN ('RECOGNITION_CANCELLED','RECOGNITION_BATCH_CANCELLED')",
          )
        ).rows[0].count,
      ),
      idempotency: Number(
        (
          await f.owner.query(
            "SELECT count(*) FROM khoa_idempotency WHERE thao_tac='RECOGNITION_BATCH_CANCEL'",
          )
        ).rows[0].count,
      ),
      pendingOutbox: await count(
        "SELECT count(*) FROM recognition_outbox WHERE ma_lo=$1 AND da_gui_luc IS NULL",
      ),
    });
    const before = await snapshot();
    await f.owner.query(
      "DELETE FROM phan_cong_giang_day WHERE ma_giao_vien=$1",
      [f.teacherId],
    );
    await assert.rejects(
      t.cancelBatch(receipt.batchId),
      failsWith("42501", "FORBIDDEN"),
    );
    assert.deepEqual(await snapshot(), before);
    assert.equal(before.batch.status, "DANG_XU_LY");
  } finally {
    await t.close();
  }
});

test("cancelling keeps the tickets that are already approved", async () => {
  const t = await createBatchFixture();
  try {
    const receipt = await t.createBatch();
    await t.saveResults(receipt.batchId, fullResults(receipt));
    const tx1 = receipt.tickets.find((x) => x.templateColumnIndex === 2)!;
    const tx2 = receipt.tickets.find((x) => x.templateColumnIndex === 4)!;
    await t.approve(
      tx1.ticketId,
      (await t.evidence(tx1.ticketId)).map((row, index) => ({
        rowId: String(row.ma_dong),
        value: TX1_VALUES[index],
        reason: "Đối chiếu ảnh giả",
      })),
      "batch-keep-approved",
    );
    const cancelled = await t.cancelBatch(receipt.batchId);
    assert.equal(cancelled.cancelledTickets, 1);
    assert.equal((await t.ticketStatus(tx1.ticketId)).status, "DA_DUYET");
    assert.equal((await t.ticketStatus(tx2.ticketId)).status, "DA_HUY");
    // Kết quả đã duyệt (bằng chứng) không bị xóa.
    assert.equal((await t.evidence(tx1.ticketId)).length, 4);
  } finally {
    await t.close();
  }
});

test("batch and page rows are protected: runtime is read-only and nothing is ever deleted", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    const denied = failsWith("42501", "permission denied");
    assert.equal(
      (
        await f.runtime.query("SELECT 1 FROM lo_nhan_dien WHERE ma_lo=$1", [
          receipt.batchId,
        ])
      ).rowCount,
      1,
    );
    assert.equal(
      (
        await f.runtime.query(
          "SELECT 1 FROM trang_lo_nhan_dien WHERE ma_lo=$1",
          [receipt.batchId],
        )
      ).rowCount,
      2,
    );
    for (const sql of [
      "UPDATE lo_nhan_dien SET so_trang=1 WHERE ma_lo=$1",
      "DELETE FROM lo_nhan_dien WHERE ma_lo=$1",
      "DELETE FROM trang_lo_nhan_dien WHERE ma_lo=$1",
      "UPDATE trang_lo_nhan_dien SET so_trang=3 WHERE ma_lo=$1",
      "INSERT INTO trang_lo_nhan_dien(ma_lo,so_trang,ma_bam_tep,duong_dan_anh) SELECT $1,3,repeat('a',64),'recognition/original/00000000-0000-0000-0000-000000000000.png'",
    ])
      await assert.rejects(
        f.runtime.query(sql, [receipt.batchId]),
        denied,
        sql,
      );
    // Kể cả chủ sở hữu bảng cũng không xóa được lô hay sửa/xóa trang.
    for (const sql of [
      "DELETE FROM lo_nhan_dien WHERE ma_lo=$1",
      "DELETE FROM trang_lo_nhan_dien WHERE ma_lo=$1",
      "UPDATE trang_lo_nhan_dien SET ma_bam_tep=repeat('b',64) WHERE ma_lo=$1",
    ])
      await assert.rejects(
        f.owner.query(sql, [receipt.batchId]),
        failsWith("42501", "BATCH_DELETE_FORBIDDEN"),
        sql,
      );
    assert.equal((await t.batchRow(receipt.batchId)).so_trang, 2);
  } finally {
    await t.close();
  }
});

test("table constraints reject malformed batch rows even for the table owner", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const receipt = await t.createBatch();
    const checks = (name: string) => failsWith("23514", name);
    await assert.rejects(
      f.owner.query("UPDATE lo_nhan_dien SET so_trang=5 WHERE ma_lo=$1", [
        receipt.batchId,
      ]),
      checks("lo_so_trang_hop_le"),
    );
    await assert.rejects(
      f.owner.query("UPDATE lo_nhan_dien SET trang_thai='LOI' WHERE ma_lo=$1", [
        receipt.batchId,
      ]),
      checks("lo_loi_hop_le"),
    );
    await assert.rejects(
      f.owner.query(
        "UPDATE lo_nhan_dien SET trang_thai='DA_HUY' WHERE ma_lo=$1",
        [receipt.batchId],
      ),
      checks("lo_huy_day_du"),
    );
    await assert.rejects(
      f.owner.query(
        "UPDATE lo_nhan_dien SET trang_thai='LOI', ma_loi='X', trang_loi=3 WHERE ma_lo=$1",
        [receipt.batchId],
      ),
      checks("lo_loi_hop_le"),
    );
    // Phiếu thuộc lô phải có chỉ số cột mẫu và mẫu; mỗi thành phần/cột mẫu chỉ một phiếu trong một lô.
    await assert.rejects(
      f.owner.query(
        "UPDATE phieu_nhan_dien SET chi_so_cot_mau=NULL WHERE ma_lo=$1",
        [receipt.batchId],
      ),
      checks("phieu_lo_day_du"),
    );
    await assert.rejects(
      f.owner.query(
        "UPDATE phieu_nhan_dien SET chi_so_cot_mau=2 WHERE ma_lo=$1 AND chi_so_cot_mau=4",
        [receipt.batchId],
      ),
      failsWith("23505", "phieu_lo_cot_mau_key"),
    );
    await assert.rejects(
      f.owner.query(
        "UPDATE phieu_nhan_dien SET ma_thanh_phan=$2 WHERE ma_lo=$1 AND chi_so_cot_mau=4",
        [receipt.batchId, t.component1],
      ),
      failsWith("23505", "phieu_lo_thanh_phan_key"),
    );
    // Cùng một ảnh không dùng cho hai trang.
    await assert.rejects(
      f.owner.query(
        "INSERT INTO trang_lo_nhan_dien(ma_lo,so_trang,ma_bam_tep,duong_dan_anh) SELECT ma_lo,3,ma_bam_tep,'recognition/original/00000000-0000-0000-0000-000000000000.png' FROM trang_lo_nhan_dien WHERE ma_lo=$1 AND so_trang=1",
        [receipt.batchId],
      ),
      failsWith("23505", "trang_lo_ma_bam_key"),
    );
    await assert.rejects(
      f.owner.query(
        "INSERT INTO trang_lo_nhan_dien(ma_lo,so_trang,ma_bam_tep,duong_dan_anh) VALUES($1,3,repeat('a',64),'../x.png')",
        [receipt.batchId],
      ),
      checks("trang_lo_duong_dan_hop_le"),
    );
    // Dòng kết quả: số trang phải đi cùng phiếu thuộc lô và không vượt số trang của lô.
    const ticket = receipt.tickets[0]!.ticketId;
    const student = f.valid[0]!.studentId;
    const insertRow = (page: number | null) =>
      f.owner.query(
        "INSERT INTO ket_qua_dong(ma_phieu,ma_hoc_sinh,thu_tu_dong,so_trang,ket_luan_doi_chieu,muc_phan_loai) VALUES($1,$2,1,$3,'KHONG_DOC_DUOC'::\"KetLuan\",'DO'::\"MucPhanLoai\")",
        [ticket, student, page],
      );
    await assert.rejects(insertRow(null), checks("BATCH_ROW_PAGE_MISMATCH"));
    await assert.rejects(insertRow(3), checks("BATCH_ROW_PAGE_MISMATCH"));
    await assert.rejects(insertRow(5), checks("BATCH_ROW_PAGE_MISMATCH"));
    // Phiếu cũ (không thuộc lô) không được mang số trang.
    const legacy = await f.createTicket(f.valid, "batch-legacy-row");
    await assert.rejects(
      f.owner.query(
        "INSERT INTO ket_qua_dong(ma_phieu,ma_hoc_sinh,thu_tu_dong,so_trang,ket_luan_doi_chieu,muc_phan_loai) VALUES($1,$2,1,1,'KHONG_DOC_DUOC'::\"KetLuan\",'DO'::\"MucPhanLoai\")",
        [legacy.ticketId, student],
      ),
      checks("BATCH_ROW_PAGE_MISMATCH"),
    );
    // Outbox: đúng một trong ma_phieu / ma_lo.
    await assert.rejects(
      f.owner.query(
        "INSERT INTO recognition_outbox(loai_su_kien,ma_lo,du_lieu) VALUES('RECOGNITION_REQUESTED',$1,'{}'::jsonb)",
        [receipt.batchId],
      ),
      checks("recognition_outbox_payload"),
    );
  } finally {
    await t.close();
  }
});

test("the old single-photo path is unchanged: a legacy ticket still takes rows without a page", async () => {
  const t = await createBatchFixture();
  const { f } = t;
  try {
    const legacy = await f.createTicket(f.valid, "batch-legacy-ok");
    const ticket = legacy.ticketId;
    const channel = (value: string) => ({
      rawOutput: value,
      value,
      confidence: "0.95",
      isBlank: false,
    });
    await f.serializable((query) =>
      query("SELECT public.luu_ket_qua_nhan_dien($1,$2,$3::jsonb)", [
        ticket,
        "fake-v1",
        JSON.stringify([
          {
            order: 1,
            stt: 2,
            sttOnPaper: 2,
            nameRead: "Họ tên đọc được giả",
            matchConfidence: 0.97,
            matchNote: "Khớp",
            numeric: channel("8.0"),
            written: channel("8.0"),
            numericCropKey: `recognition/crops/${ticket}/1-numeric.png`,
            writtenCropKey: `recognition/crops/${ticket}/1-written.png`,
            nameCropKey: `recognition/crops/${ticket}/1-name.png`,
            comparison: "KHOP",
            reviewLevel: "XANH",
            suggestedSource: "SO",
          },
        ]),
      ]),
    );
    const rows = await f.owner.query(
      "SELECT so_trang FROM ket_qua_dong WHERE ma_phieu=$1",
      [ticket],
    );
    assert.deepEqual(
      rows.rows.map((row) => row.so_trang),
      [null],
    );
    assert.equal(
      (
        await f.owner.query(
          "SELECT ma_lo, chi_so_cot_mau FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [ticket],
        )
      ).rows[0].ma_lo,
      null,
    );
  } finally {
    await t.close();
  }
});
