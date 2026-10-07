import assert from "node:assert/strict";
import { randomBytes } from "node:crypto";
import { test } from "node:test";
import { createRosterFixture } from "./roster-fixture.js";

// ADR-0015: tao_phieu_nhan_dien chốt danh sách lớp (STT -> học sinh) vào phiếu; dữ liệu hoàn toàn giả.
test("recognition ticket accepts only a valid class roster snapshot", async () => {
  const f = await createRosterFixture();
  const {
    owner,
    cls,
    students: s,
    makeStudent,
    entry,
    valid,
    createTicket: create,
    countTickets,
  } = f;
  try {
    const isCheckViolation = (error: { code?: string }) =>
      error.code === "23514";

    // Roster sai: không tạo phiếu, không ghi danh sách.
    const bad: Array<[string, unknown]> = [
      ["thiếu một học sinh", valid.slice(0, 3)],
      ["thừa học sinh đã nghỉ", [...valid, entry(5, s.left)]],
      [
        "thay bằng học sinh nghỉ",
        [entry(1, s.an), entry(2, s.bao), entry(3, s.cuong), entry(4, s.left)],
      ],
      [
        "học sinh lớp khác",
        [
          entry(1, s.an),
          entry(2, s.bao),
          entry(3, s.cuong),
          entry(4, s.outsider),
        ],
      ],
      [
        "STT không liên tục",
        [entry(1, s.an), entry(2, s.bao), entry(3, s.cuong), entry(5, s.dat)],
      ],
      [
        "STT bắt đầu từ 0",
        [entry(0, s.an), entry(1, s.bao), entry(2, s.cuong), entry(3, s.dat)],
      ],
      [
        "trùng STT",
        [entry(1, s.an), entry(2, s.bao), entry(2, s.cuong), entry(4, s.dat)],
      ],
      [
        "trùng học sinh",
        [entry(1, s.an), entry(2, s.bao), entry(3, s.bao), entry(4, s.dat)],
      ],
      [
        "sai họ tên",
        [{ ...valid[0]!, fullName: "Tên khác" }, ...valid.slice(1)],
      ],
      ["thừa khóa", [{ ...valid[0]!, extra: true }, ...valid.slice(1)]],
      ["STT dạng số thực", [{ ...valid[0]!, stt: 1.5 }, ...valid.slice(1)]],
      ["mảng rỗng", []],
      ["không phải mảng", { stt: 1 }],
      ["null", null],
    ];
    for (const [label, roster] of bad) {
      await assert.rejects(
        create(roster, `bad-${randomBytes(4).toString("hex")}`),
        isCheckViolation,
        label,
      );
      assert.equal(await countTickets(), 0, label);
    }

    // Roster hợp lệ: phiếu mới, snapshot ghi đúng STT -> học sinh, so_dong_khai_bao = sĩ số.
    const receipt = await create(valid, "roster-ok", "b".repeat(64));
    assert.equal(receipt.status, "DANG_XU_LY");
    const stored = await owner.query(
      "SELECT stt,ma_hoc_sinh,ho_ten FROM danh_sach_phieu WHERE ma_phieu=$1 ORDER BY stt",
      [receipt.ticketId],
    );
    assert.deepEqual(
      stored.rows.map((r) => [r.stt, r.ma_hoc_sinh, r.ho_ten]),
      valid.map((e) => [e.stt, e.studentId, e.fullName]),
    );
    assert.equal(
      (
        await owner.query(
          "SELECT so_dong_khai_bao FROM phieu_nhan_dien WHERE ma_phieu=$1",
          [receipt.ticketId],
        )
      ).rows[0].so_dong_khai_bao,
      4,
    );

    // Replay cùng khóa/hash trả lại phiếu cũ và không ghi thêm snapshot.
    assert.deepEqual(await create(valid, "roster-ok", "b".repeat(64)), receipt);
    assert.equal(await countTickets(), 1);
    assert.equal(
      Number(
        (
          await owner.query(
            "SELECT count(*) FROM danh_sach_phieu WHERE ma_phieu=$1",
            [receipt.ticketId],
          )
        ).rows[0].count,
      ),
      4,
    );
    await assert.rejects(
      create(valid, "roster-ok", "c".repeat(64)),
      (error: { code?: string }) => error.code === "23505",
    );

    // Lớp đổi sau khi tạo phiếu: snapshot giữ nguyên.
    await makeStudent(cls, "Mới Vào Lớp");
    await owner.query(
      "UPDATE hoc_sinh SET dang_theo_hoc=false WHERE ma_hoc_sinh=$1",
      [s.cuong],
    );
    const after = await owner.query(
      "SELECT stt,ma_hoc_sinh FROM danh_sach_phieu WHERE ma_phieu=$1 ORDER BY stt",
      [receipt.ticketId],
    );
    assert.deepEqual(
      after.rows.map((r) => [r.stt, r.ma_hoc_sinh]),
      valid.map((e) => [e.stt, e.studentId]),
    );

    // Roster cũ không còn khớp sĩ số hiện tại nên bị từ chối với phiếu mới.
    await assert.rejects(create(valid, "stale"), isCheckViolation);
  } finally {
    await f.close();
  }
});
