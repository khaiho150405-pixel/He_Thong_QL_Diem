import assert from "node:assert/strict";
import { test } from "node:test";
import {
  MAX_RED_RATIO,
  NAME_STRONG,
  NAME_WEAK,
  combineLevel,
  matchRows,
  nameSimilarity,
  normalizeName,
  type DetectedRow,
  type RosterEntry,
  type RowMatchResult,
} from "../src/modules/recognition/domain/row-matching.js";

// Họ tên hoàn toàn giả; mã học sinh cố ý khác thứ tự STT.
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
  rowIndex: number,
  entry: RosterEntry | null,
  overrides: Partial<DetectedRow> = {},
): DetectedRow {
  return {
    rowIndex,
    struck: false,
    sttValue: entry ? entry.stt : null,
    sttConfidence: 0.95,
    nameRaw: entry ? entry.fullName : null,
    nameConfidence: 0.9,
    hasGradeInk: true,
    hasNameInk: true,
    ...overrides,
  };
}

function ok(result: RowMatchResult) {
  assert.equal(
    result.ok,
    true,
    result.ok ? "" : `${result.reason}: ${result.detail}`,
  );
  if (!result.ok) throw new Error("unreachable");
  return result;
}

const pages = (roster: RosterEntry[], from: number, to: number) =>
  roster.slice(from - 1, to).map((entry, index) => row(index + 1, entry));

test("rows in order map to the roster by STT and name, all green", () => {
  const roster = makeRoster(8);
  const { matches, skipped } = ok(matchRows(pages(roster, 1, 8), roster));
  assert.equal(skipped.length, 0);
  assert.deepEqual(
    matches.map((m) => [m.rowIndex, m.stt, m.studentId]),
    roster.map((e, i) => [i + 1, e.stt, e.studentId]),
  );
  assert.ok(matches.every((m) => m.matchLevel === "XANH"));
  assert.ok(matches.every((m) => m.matchConfidence > 0.9));
});

test("a second page that starts at STT 39 matches the tail of the roster", () => {
  const roster = makeRoster(41);
  const { matches } = ok(matchRows(pages(roster, 39, 41), roster));
  assert.deepEqual(
    matches.map((m) => m.stt),
    [39, 40, 41],
  );
  assert.ok(matches.every((m) => m.matchLevel === "XANH"));
  // Trang đầu chỉ chứa đoạn đầu của lớp.
  const first = ok(matchRows(pages(roster, 1, 4), roster)).matches;
  assert.deepEqual(
    first.map((m) => m.stt),
    [1, 2, 3, 4],
  );
});

test("struck rows and fully empty rows are dropped before matching", () => {
  const roster = makeRoster(6);
  const detected = [
    row(1, roster[0]!),
    row(2, roster[1]!, { struck: true, hasGradeInk: false }),
    row(3, roster[2]!),
    row(4, null, { hasGradeInk: false, hasNameInk: false }),
    row(5, roster[3]!),
  ];
  const result = ok(matchRows(detected, roster));
  assert.deepEqual(
    result.matches.map((m) => m.stt),
    [1, 3, 4],
  );
  assert.deepEqual(result.skipped, [
    { rowIndex: 2, reason: "STRUCK" },
    { rowIndex: 4, reason: "EMPTY" },
  ]);
});

test("a student missing from the paper shifts nothing after it", () => {
  const roster = makeRoster(6);
  // Giấy thiếu học sinh STT 3: các dòng sau vẫn về đúng học sinh.
  const detected = [1, 2, 4, 5, 6].map((stt, index) =>
    row(index + 1, roster[stt - 1]!),
  );
  const { matches } = ok(matchRows(detected, roster));
  assert.deepEqual(
    matches.map((m) => m.stt),
    [1, 2, 4, 5, 6],
  );
  assert.ok(matches.every((m) => m.matchLevel === "XANH"));
});

test("a paper row for a student no longer in the roster is red but tolerated when rare", () => {
  const roster = makeRoster(10);
  const stranger: RosterEntry = {
    stt: 4,
    studentId: 1,
    fullName: "Ngô Quang Zzzzz",
  };
  const detected = [
    ...pages(roster, 1, 3),
    row(4, stranger, { sttValue: 4 }),
    ...roster.slice(4, 10).map((entry, index) => row(index + 5, entry)),
  ];
  // 10 dòng giấy ↔ 10 học sinh; dòng 4 khác tên nhưng STT khớp.
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[3]!.stt, 4);
  assert.equal(matches[3]!.matchLevel, "DO");
  assert.ok(matches.filter((m) => m.matchLevel === "DO").length === 1);
  assert.ok(matches.filter((m) => m.matchLevel === "XANH").length === 9);
});

test("OCR typos lower the level: one wrong character stays green, heavier damage goes yellow", () => {
  const roster = makeRoster(5);
  const target = roster[2]!.fullName;
  const oneTypo = target.replace("Châu", "Chău");
  assert.ok(
    nameSimilarity(normalizeName(oneTypo), normalizeName(target)) >=
      NAME_STRONG,
  );
  const damaged = roster[3]!.fullName.slice(0, -3) + "xyz";
  const damagedSimilarity = nameSimilarity(
    normalizeName(damaged),
    normalizeName(roster[3]!.fullName),
  );
  assert.ok(damagedSimilarity >= NAME_WEAK && damagedSimilarity < NAME_STRONG);
  const detected = [
    row(1, roster[0]!),
    row(2, roster[1]!),
    row(3, roster[2]!, { nameRaw: oneTypo }),
    row(4, roster[3]!, { nameRaw: damaged }),
    row(5, roster[4]!),
  ];
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[2]!.matchLevel, "XANH");
  assert.equal(matches[3]!.matchLevel, "VANG");
  assert.ok(matches[3]!.matchConfidence < matches[0]!.matchConfidence);
  assert.deepEqual(
    matches.map((m) => m.stt),
    [1, 2, 3, 4, 5],
  );
});

test("a partly similar name is yellow and a very different one is red", () => {
  const roster = makeRoster(10);
  const detected = pages(roster, 1, 10);
  const partial = roster[3]!.fullName.slice(0, -3) + "xyz";
  const different = "zzzz wwww kkkkk";
  detected[3] = { ...detected[3]!, nameRaw: partial };
  detected[6] = { ...detected[6]!, nameRaw: different };
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[3]!.matchLevel, "VANG");
  assert.match(matches[3]!.note, /một phần/);
  assert.equal(matches[6]!.matchLevel, "DO");
  assert.equal(matches[6]!.stt, 7);
  assert.match(matches[6]!.note, /khác nhiều/);
});

test("duplicate full names inside the class are never green", () => {
  const roster = makeRoster(6);
  roster[1] = { ...roster[1]!, fullName: roster[4]!.fullName };
  const detected = pages(roster, 1, 6);
  const { matches } = ok(matchRows(detected, roster));
  // Hai dòng trùng tên phân định bằng STT/thứ tự, đúng học sinh nhưng chỉ tối đa Vàng.
  assert.equal(matches[1]!.studentId, roster[1]!.studentId);
  assert.equal(matches[4]!.studentId, roster[4]!.studentId);
  assert.equal(matches[1]!.matchLevel, "VANG");
  assert.equal(matches[4]!.matchLevel, "VANG");
  assert.match(matches[1]!.note, /Trùng họ tên/);
  assert.equal(matches[0]!.matchLevel, "XANH");
});

test("without a readable STT the name alone matches (green when unambiguous)", () => {
  const roster = makeRoster(7);
  const detected = pages(roster, 1, 7).map((entry) => ({
    ...entry,
    sttValue: null,
    sttConfidence: null,
  }));
  const { matches } = ok(matchRows(detected, roster));
  assert.deepEqual(
    matches.map((m) => m.stt),
    [1, 2, 3, 4, 5, 6, 7],
  );
  assert.ok(matches.every((m) => m.matchLevel === "XANH"));
  assert.ok(matches.every((m) => m.sttOnPaper === null));
  // Trang 2 không đọc được STT: tên đủ để định vị đoạn cuối của lớp.
  const roster41 = makeRoster(41);
  const tail = pages(roster41, 38, 41).map((entry) => ({
    ...entry,
    sttValue: null,
    sttConfidence: null,
  }));
  assert.deepEqual(
    ok(matchRows(tail, roster41)).matches.map((m) => m.stt),
    [38, 39, 40, 41],
  );
});

test("a printed STT that contradicts the matched student is red", () => {
  const roster = makeRoster(5);
  const detected = pages(roster, 1, 5);
  detected[2] = { ...detected[2]!, sttValue: 9, sttConfidence: 0.95 };
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[2]!.stt, 3);
  assert.equal(matches[2]!.matchLevel, "DO");
  assert.match(matches[2]!.note, /STT trên giấy \(9\)/);
  // STT lệch nhưng độ tin cậy thấp chỉ làm Vàng.
  detected[2] = { ...detected[2]!, sttValue: 9, sttConfidence: 0.2 };
  assert.equal(ok(matchRows(detected, roster)).matches[2]!.matchLevel, "VANG");
});

test("a name that fits the neighbouring student better is red", () => {
  // Hai học sinh kề nhau có tên gần giống nhau; dòng 3 đọc gần "bbbbbb" hơn "aaaaaa" nhưng khoảng trống bị phạt.
  const roster: RosterEntry[] = [
    { stt: 1, studentId: 11, fullName: "Hà Thanh Xuân" },
    { stt: 2, studentId: 12, fullName: "Đỗ Quốc Việt" },
    { stt: 3, studentId: 13, fullName: "Le Van Aaaaaa" },
    { stt: 4, studentId: 14, fullName: "Le Van Bbbbbb" },
    { stt: 5, studentId: 15, fullName: "Mai Hữu Phúc" },
  ];
  const detected = [
    row(1, roster[0]!, { sttValue: null, sttConfidence: null }),
    row(2, roster[1]!, { sttValue: null, sttConfidence: null }),
    row(3, roster[2]!, {
      nameRaw: "Le Van Bbbbaa",
      sttValue: null,
      sttConfidence: null,
    }),
    row(4, roster[3]!, { sttValue: null, sttConfidence: null }),
    row(5, roster[4]!, { sttValue: null, sttConfidence: null }),
  ];
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[2]!.stt, 3);
  assert.equal(matches[2]!.matchLevel, "DO");
  assert.match(matches[2]!.note, /khớp STT 4 hơn STT 3/);
  assert.equal(matches[3]!.stt, 4);
  assert.equal(matches[3]!.matchLevel, "XANH");
});

test("a row between two others with an unreadable name is red, never guessed green", () => {
  const roster = makeRoster(6);
  const detected = pages(roster, 1, 6);
  detected[2] = {
    ...detected[2]!,
    nameRaw: null,
    hasNameInk: false,
    sttValue: null,
    sttConfidence: null,
  };
  const { matches } = ok(matchRows(detected, roster));
  assert.equal(matches[2]!.stt, 3);
  assert.equal(matches[2]!.matchLevel, "DO");
  // Chỉ còn STT: ghép theo STT nhưng không xanh.
  detected[2] = { ...detected[2]!, sttValue: 3, sttConfidence: 0.9 };
  const stt = ok(matchRows(detected, roster)).matches[2]!;
  assert.equal(stt.matchLevel, "VANG");
});

test("rows from another class fail with ROW_MATCH_FAILED", () => {
  const roster = makeRoster(8);
  const other = Array.from({ length: 8 }, (_, index) => ({
    stt: index + 1,
    studentId: 5000 + index,
    fullName: `Trương ${GIVEN[(index + 9) % GIVEN.length]} Ghi ${index * 11}`,
  }));
  const result = matchRows(
    other.map((entry, index) => row(index + 1, entry)),
    roster,
  );
  assert.equal(result.ok, false);
  if (!result.ok) {
    assert.equal(result.code, "ROW_MATCH_FAILED");
    assert.equal(result.reason, "TOO_MANY_LOW_CONFIDENCE");
  }
});

test("two paper rows for the same student fail", () => {
  const roster = makeRoster(6);
  const detected = [
    row(1, roster[0]!),
    row(2, roster[1]!),
    row(3, roster[1]!, { sttValue: null, sttConfidence: null }),
    row(4, roster[3]!),
  ];
  const result = matchRows(detected, roster);
  assert.equal(result.ok, false);
  if (!result.ok) assert.equal(result.reason, "DUPLICATE_STUDENT");
});

test("a row with a grade that cannot be matched fails; blank-grade extras are dropped", () => {
  const roster = makeRoster(3);
  const tooMany = [...pages(roster, 1, 3), row(4, makeRoster(9)[8]!)];
  const failure = matchRows(tooMany, roster);
  assert.equal(failure.ok, false);
  if (!failure.ok) assert.equal(failure.reason, "ROW_UNMATCHED");
  // Dòng cuối chỉ có chữ (ví dụ chữ ký) và không có điểm: bỏ qua, không làm hỏng phiếu.
  const footer = row(4, null, {
    hasGradeInk: false,
    nameRaw: "Ký tên giáo viên",
    sttValue: null,
    sttConfidence: null,
  });
  const result = ok(matchRows([...pages(roster, 1, 3), footer], roster));
  assert.deepEqual(
    result.matches.map((m) => m.stt),
    [1, 2, 3],
  );
  assert.deepEqual(result.skipped, [
    { rowIndex: 4, reason: "UNMATCHED_BLANK" },
  ]);
});

test("a blank grade cell still consumes its student and is reported", () => {
  const roster = makeRoster(5);
  const detected = pages(roster, 1, 5);
  detected[1] = { ...detected[1]!, hasGradeInk: false };
  const { matches } = ok(matchRows(detected, roster));
  assert.deepEqual(
    matches.map((m) => m.stt),
    [1, 2, 3, 4, 5],
  );
});

test("empty input and empty roster fail instead of guessing", () => {
  const roster = makeRoster(3);
  const none = matchRows([], roster);
  assert.equal(none.ok, false);
  if (!none.ok) assert.equal(none.reason, "NO_ROWS");
  const allEmpty = matchRows(
    [row(1, null, { hasGradeInk: false, hasNameInk: false })],
    roster,
  );
  assert.equal(allEmpty.ok, false);
  const noRoster = matchRows(pages(roster, 1, 3), []);
  assert.equal(noRoster.ok, false);
});

test("rows given out of order are matched by their position on the page", () => {
  const roster = makeRoster(5);
  const detected = pages(roster, 1, 5).reverse();
  const { matches } = ok(matchRows(detected, roster));
  assert.deepEqual(
    matches.map((m) => [m.rowIndex, m.stt]),
    [1, 2, 3, 4, 5].map((n) => [n, n]),
  );
});

test("thresholds are ordered and the red ratio is a proper fraction", () => {
  assert.ok(NAME_WEAK < NAME_STRONG);
  assert.ok(MAX_RED_RATIO > 0 && MAX_RED_RATIO < 1);
});

test("combineLevel returns the lower level", () => {
  assert.equal(combineLevel("XANH", "XANH"), "XANH");
  assert.equal(combineLevel("XANH", "VANG"), "VANG");
  assert.equal(combineLevel("VANG", "XANH"), "VANG");
  assert.equal(combineLevel("XANH", "DO"), "DO");
  assert.equal(combineLevel("DO", "XANH"), "DO");
  assert.equal(combineLevel("VANG", "DO"), "DO");
  assert.equal(combineLevel("DO", "VANG"), "DO");
});

test("normalizeName folds case, accents and spacing", () => {
  assert.equal(normalizeName("  Đặng   Thị-Hà "), "dang thi ha");
  assert.equal(normalizeName(null), "");
  assert.equal(normalizeName("Nguyễn Văn An"), normalizeName("NGUYEN  VAN AN"));
});

test("match output never contains student names in notes and stays within column limits", () => {
  const roster = makeRoster(6);
  const detected = pages(roster, 1, 6);
  detected[2] = { ...detected[2]!, nameRaw: "Lê Ngọc Chaa" };
  const { matches } = ok(matchRows(detected, roster));
  for (const match of matches) {
    assert.ok(match.note.length <= 200);
    assert.ok(match.matchConfidence >= 0 && match.matchConfidence <= 1);
    assert.ok(
      Math.abs(
        match.matchConfidence * 10_000 -
          Math.round(match.matchConfidence * 10_000),
      ) < 1e-6,
      "numeric(5,4) precision",
    );
    for (const entry of roster)
      assert.equal(match.note.includes(entry.fullName), false);
  }
});

// Mô phỏng nhiễu OCR có hạt giống cố định: mọi dòng Xanh phải đúng học sinh (không có lỗi im lặng).
test("simulated noisy pages never produce a green row for the wrong student", () => {
  let seed = 20261006;
  const random = () => {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed / 2 ** 32;
  };
  const roster = makeRoster(41);
  const letters = "abcdefghiklmnoprstuvxy";
  const corrupt = (name: string, edits: number) => {
    const chars = [...name];
    for (let k = 0; k < edits; k += 1) {
      const at = Math.floor(random() * chars.length);
      chars[at] = letters[Math.floor(random() * letters.length)]!;
    }
    return chars.join("");
  };
  let green = 0;
  let failures = 0;
  for (let trial = 0; trial < 400; trial += 1) {
    const length = 5 + Math.floor(random() * 37);
    const start = 1 + Math.floor(random() * (41 - length + 1));
    const truth: Array<{ rowIndex: number; entry: RosterEntry }> = [];
    const detected: DetectedRow[] = [];
    let rowIndex = 0;
    for (const entry of roster.slice(start - 1, start - 1 + length)) {
      if (random() < 0.05) continue; // học sinh vắng trên giấy
      rowIndex += 1;
      const struck = random() < 0.04;
      const readStt = random() < 0.7;
      const sttWrong = readStt && random() < 0.1;
      detected.push({
        rowIndex,
        struck,
        sttValue: !readStt
          ? null
          : sttWrong
            ? 1 + Math.floor(random() * 41)
            : entry.stt,
        sttConfidence: readStt ? 0.6 + random() * 0.4 : null,
        nameRaw:
          random() < 0.05
            ? null
            : corrupt(entry.fullName, Math.floor(random() * 4)),
        nameConfidence: 0.9,
        hasGradeInk: !struck && random() < 0.95,
        hasNameInk: true,
      });
      if (!struck) truth.push({ rowIndex, entry });
    }
    const result = matchRows(detected, roster);
    if (!result.ok) {
      failures += 1;
      continue;
    }
    for (const match of result.matches) {
      const expected = truth.find((item) => item.rowIndex === match.rowIndex);
      if (match.matchLevel === "XANH") {
        green += 1;
        assert.equal(
          match.studentId,
          expected?.entry.studentId,
          `trial ${trial} row ${match.rowIndex} is green but wrong`,
        );
      }
    }
  }
  assert.ok(green > 1_000, `expected many green rows, got ${green}`);
  assert.ok(failures < 80, `too many refused pages: ${failures}`);
});
