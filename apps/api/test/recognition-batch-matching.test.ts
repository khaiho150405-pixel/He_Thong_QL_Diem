import assert from "node:assert/strict";
import { test } from "node:test";
import {
  matchBatchRows,
  matchRows,
  type BatchDetectedRow,
  type BatchMatchResult,
  type RosterEntry,
} from "../src/modules/recognition/domain/row-matching.js";

// Ghép học sinh cho lô nhiều trang (ADR-0016 mục 3): MỘT lần trên toàn lô, dữ liệu hoàn toàn giả.
const FAMILY = ["Nguyễn", "Trần", "Lê", "Phạm", "Hoàng", "Vũ", "Đặng", "Bùi"];
const MIDDLE = ["Văn", "Thị", "Minh", "Quốc", "Ngọc", "Hữu", "Thanh", "Anh"];
const GIVEN = [
  "An",
  "Bình",
  "Châu",
  "Dũng",
  "Em",
  "Phúc",
  "Giang",
  "Hà",
  "Khánh",
  "Lan",
  "Mai",
  "Nam",
  "Oanh",
  "Phương",
  "Quân",
  "Sơn",
  "Tâm",
  "Uyên",
  "Việt",
  "Xuân",
];
const fullName = (index: number) =>
  `${FAMILY[index % FAMILY.length]} ${MIDDLE[(index * 3) % MIDDLE.length]} ${GIVEN[index % GIVEN.length]}${index >= GIVEN.length ? ` ${Math.floor(index / GIVEN.length)}` : ""}`;

function makeRoster(size: number): RosterEntry[] {
  return Array.from({ length: size }, (_, index) => ({
    stt: index + 1,
    studentId: 1000 - index * 7,
    fullName: fullName(index),
  }));
}

function row(
  page: number,
  rowIndex: number,
  entry: RosterEntry,
  printedStt: number = entry.stt,
  overrides: Partial<BatchDetectedRow> = {},
): BatchDetectedRow {
  return {
    page,
    rowIndex,
    struck: false,
    sttValue: printedStt,
    sttConfidence: 0.95,
    nameRaw: entry.fullName,
    nameConfidence: 0.9,
    hasGradeInk: true,
    hasNameInk: true,
    ...overrides,
  };
}

/** Các dòng của một trang chứa học sinh STT `from..to` của danh sách lớp, STT in trên giấy lệch `shift`. */
const page = (
  roster: RosterEntry[],
  pageNumber: number,
  from: number,
  to: number,
  shift = 0,
): BatchDetectedRow[] =>
  roster
    .slice(from - 1, to)
    .map((entry, index) =>
      row(pageNumber, index + 1, entry, entry.stt + shift),
    );

function ok(result: BatchMatchResult) {
  assert.equal(
    result.ok,
    true,
    result.ok ? "" : `${result.reason}: ${result.detail}`,
  );
  if (!result.ok) throw new Error("unreachable");
  return result;
}

const similarRoster = (names: string[]): RosterEntry[] =>
  names.map((name, index) => ({
    stt: index + 1,
    studentId: index + 1,
    fullName: name,
  }));

test("a student repeated on page 2 fails even when a similar-named classmate could absorb the repeated row", () => {
  // Hồi quy P3-F1: "Nguyen Van An" và "Nguyen Van Anh" giống nhau 0,93; dòng lặp không được ép sang học sinh thứ hai.
  const roster = similarRoster([
    "Nguyen Van An",
    "Nguyen Van Anh",
    "Tran Thi Binh",
    "Le Thi Chi",
  ]);
  const detected = [
    row(1, 1, roster[0]!),
    row(1, 2, roster[2]!),
    row(1, 3, roster[3]!),
    row(2, 1, roster[0]!),
  ];
  for (const sttCheck of [false, true]) {
    const result = matchBatchRows(detected, roster, { sttCheck });
    assert.equal(result.ok, false, `sttCheck=${sttCheck}`);
    if (result.ok) throw new Error("unreachable");
    assert.equal(result.code, "ROW_MATCH_FAILED");
    assert.equal(result.reason, "DUPLICATE_STUDENT");
    assert.doesNotMatch(result.detail, /Nguyen/);
  }
});

test("similar-named classmates that each appear once are still matched across two pages", () => {
  const roster = similarRoster([
    "Nguyen Van An",
    "Nguyen Van Anh",
    "Tran Thi Binh",
  ]);
  const result = ok(
    matchBatchRows(
      [row(1, 1, roster[0]!), row(1, 2, roster[2]!), row(2, 1, roster[1]!)],
      roster,
      { sttCheck: true },
    ),
  );
  assert.deepEqual(
    result.matches.map((match) => [match.page, match.studentId]),
    [
      [1, 1],
      [1, 3],
      [2, 2],
    ],
  );
});

test("a 41-student class over two pages is matched once: 38 rows then 3 rows", () => {
  const roster = makeRoster(41);
  const detected = [...page(roster, 1, 1, 38), ...page(roster, 2, 39, 41)];
  for (const sttCheck of [false, true]) {
    const result = ok(matchBatchRows(detected, roster, { sttCheck }));
    assert.equal(result.matches.length, 41, `sttCheck=${sttCheck}`);
    assert.deepEqual(
      result.matches.map((m) => m.stt),
      roster.map((e) => e.stt),
    );
    // Mỗi dòng mang theo số trang; trang 2 bắt đầu lại từ dòng 1.
    assert.deepEqual(
      result.matches.slice(37).map((m) => [m.page, m.rowIndex, m.stt]),
      [
        [1, 38, 38],
        [2, 1, 39],
        [2, 2, 40],
        [2, 3, 41],
      ],
    );
    assert.ok(result.matches.every((m) => m.matchLevel === "XANH"));
    assert.equal(result.skipped.length, 0);
  }
});

test("a student that appears on two pages fails the whole batch with ROW_MATCH_FAILED", () => {
  const roster = makeRoster(41);
  // Học sinh STT 5 có dòng ở cả trang 1 lẫn trang 2; tổng số dòng vẫn nhỏ hơn sĩ số.
  const detected = [
    ...page(roster, 1, 1, 30),
    row(2, 1, roster[4]!),
    ...page(roster, 2, 31, 33).map((item) => ({
      ...item,
      rowIndex: item.rowIndex + 1,
    })),
  ];
  for (const sttCheck of [false, true]) {
    const result = matchBatchRows(detected, roster, { sttCheck });
    assert.equal(result.ok, false, `sttCheck=${sttCheck}`);
    if (result.ok) throw new Error("unreachable");
    assert.equal(result.code, "ROW_MATCH_FAILED");
    assert.equal(result.reason, "DUPLICATE_STUDENT");
    // Thông báo ghi vị trí theo trang.dòng và không chứa họ tên.
    assert.match(result.detail, /1\.5/);
    assert.match(result.detail, /2\.1/);
    assert.doesNotMatch(result.detail, new RegExp(roster[4]!.fullName));
  }
});

test("more paper rows than students over all pages fails with ROW_MATCH_FAILED", () => {
  const roster = makeRoster(41);
  // 38 + 1 + 3 = 42 dòng có điểm cho 41 học sinh: chắc chắn có một học sinh xuất hiện hai lần.
  const detected = [
    ...page(roster, 1, 1, 38),
    row(2, 1, roster[4]!),
    ...page(roster, 2, 39, 41).map((item) => ({
      ...item,
      rowIndex: item.rowIndex + 1,
    })),
  ];
  const result = matchBatchRows(detected, roster, { sttCheck: true });
  assert.equal(result.ok, false);
  if (result.ok) throw new Error("unreachable");
  assert.equal(result.code, "ROW_MATCH_FAILED");
});

test("a missing or empty page 2 leaves its students blank without an error", () => {
  const roster = makeRoster(41);
  const only = page(roster, 1, 1, 38);
  for (const detected of [
    only,
    // Trang 2 có mặt nhưng toàn dòng gạch/trống.
    [
      ...only,
      row(2, 1, roster[38]!, 39, { struck: true, hasGradeInk: false }),
      row(2, 2, roster[39]!, 40, { hasGradeInk: false, hasNameInk: false }),
    ],
  ]) {
    const result = ok(matchBatchRows(detected, roster, { sttCheck: true }));
    assert.equal(result.matches.length, 38);
    assert.deepEqual(
      result.matches.map((m) => m.stt),
      roster.slice(0, 38).map((e) => e.stt),
    );
    assert.ok(result.matches.every((m) => m.page === 1));
  }
});

test("a batch of no usable rows fails instead of guessing", () => {
  const roster = makeRoster(5);
  const result = matchBatchRows(
    [row(1, 1, roster[0]!, 1, { hasGradeInk: false, hasNameInk: false })],
    roster,
  );
  assert.equal(result.ok, false);
  if (result.ok) throw new Error("unreachable");
  assert.equal(result.reason, "NO_ROWS");
});

test("one page behaves exactly like the single-photo matcher", () => {
  const roster = makeRoster(12);
  const detected = page(roster, 1, 1, 12);
  const single = matchRows(
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    detected.map(({ page: _page, ...rest }) => rest),
    roster,
    { sttCheck: true },
  );
  const batch = ok(matchBatchRows(detected, roster, { sttCheck: true }));
  if (!single.ok) throw new Error("unreachable");
  assert.deepEqual(
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    batch.matches.map(({ page: _page, ...rest }) => rest),
    single.matches,
  );
  assert.equal(batch.stt.pages.length, 1);
  assert.deepEqual(batch.stt.pages[0]!.model, single.stt.model);
  assert.equal(batch.stt.pages[0]!.evidence, single.stt.evidence);
});

test("the STT model is chosen per page: a shifted second page stays green", () => {
  const roster = makeRoster(41);
  // Trang 2 in STT lệch +1 (một học sinh đã nghỉ ở trang 1); trang 1 in đúng STT hệ thống.
  const detected = [...page(roster, 1, 1, 38), ...page(roster, 2, 39, 41, 1)];
  const result = ok(matchBatchRows(detected, roster, { sttCheck: true }));
  assert.equal(result.matches.length, 41);
  assert.ok(
    result.matches.every((m) => m.matchLevel === "XANH"),
    result.matches
      .filter((m) => m.matchLevel !== "XANH")
      .map((m) => `${m.page}.${m.rowIndex}:${m.note}`)
      .join(" | "),
  );
  assert.deepEqual(
    result.stt.pages.map((item) => [item.page, item.model?.k]),
    [
      [1, 0],
      [2, 1],
    ],
  );
});

test("struck rows are counted per page when shifting printed STT", () => {
  const roster = makeRoster(10);
  // Trang 1: STT 1..4 với dòng 3 bị gạch (học sinh STT 3 vẫn trong lớp nên in STT không dịch);
  // trang 2: STT 5..8, không gạch.
  const detected: BatchDetectedRow[] = [
    row(1, 1, roster[0]!),
    row(1, 2, roster[1]!),
    row(1, 3, roster[2]!, 3, { struck: true, hasGradeInk: false }),
    row(1, 4, roster[3]!),
    ...page(roster, 2, 5, 8),
  ];
  const result = ok(matchBatchRows(detected, roster, { sttCheck: true }));
  assert.deepEqual(
    result.matches.map((m) => m.stt),
    [1, 2, 4, 5, 6, 7, 8],
  );
  assert.deepEqual(result.skipped, [
    { page: 1, rowIndex: 3, reason: "STRUCK" },
  ]);
  assert.ok(result.matches.every((m) => m.matchLevel === "XANH"));
});

test("a row without a readable name on a later page is never green", () => {
  const roster = makeRoster(41);
  const detected = [
    ...page(roster, 1, 1, 38),
    ...page(roster, 2, 39, 41).map((item, index) =>
      index === 1 ? { ...item, nameRaw: null, sttValue: null } : item,
    ),
  ];
  const result = ok(matchBatchRows(detected, roster, { sttCheck: true }));
  const unknown = result.matches.find((m) => m.page === 2 && m.rowIndex === 2)!;
  assert.equal(unknown.stt, 40);
  assert.equal(unknown.matchLevel, "DO");
});
