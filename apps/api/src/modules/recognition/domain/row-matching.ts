// Ghép dòng trên ảnh với danh sách lớp đã chốt của phiếu (ADR-0015). Miền thuần: không import NestJS/Prisma.
//
// Máy chỉ đề xuất. Hàm này không chọn điểm; nó chỉ gán mỗi dòng có dữ liệu cho một học sinh trong snapshot
// (theo STT + họ tên đọc được trên giấy) và đánh giá độ chắc chắn của phép ghép. Không ghép được thì dừng.

export type ReviewLevel = "XANH" | "VANG" | "DO";

export interface DetectedRow {
  /** Vị trí dòng trên ảnh, bắt đầu từ 1. */
  rowIndex: number;
  struck: boolean;
  /** STT in trên giấy đọc được; null khi không đọc được. */
  sttValue: number | null;
  sttConfidence: number | null;
  nameRaw: string | null;
  nameConfidence: number | null;
  hasGradeInk: boolean;
  hasNameInk: boolean;
}

export interface RosterEntry {
  stt: number;
  studentId: number;
  fullName: string;
}

export interface RowMatch {
  rowIndex: number;
  /** STT hệ thống đã ghép (từ snapshot), không phải STT đọc trên giấy. */
  stt: number;
  studentId: number;
  sttOnPaper: number | null;
  nameRead: string | null;
  /** 0..1, tối đa 4 chữ số thập phân (khớp numeric(5,4)). */
  matchConfidence: number;
  matchLevel: ReviewLevel;
  /** Ghi chú ≤ 200 ký tự, không chứa họ tên. */
  note: string;
}

export interface SkippedRow {
  rowIndex: number;
  reason: "STRUCK" | "EMPTY" | "UNMATCHED_BLANK";
}

export type RowMatchFailureReason =
  | "NO_ROWS"
  | "ROW_UNMATCHED"
  | "DUPLICATE_STUDENT"
  | "TOO_MANY_LOW_CONFIDENCE";

export type RowMatchResult =
  | { ok: true; matches: RowMatch[]; skipped: SkippedRow[] }
  | {
      ok: false;
      code: "ROW_MATCH_FAILED";
      reason: RowMatchFailureReason;
      detail: string;
    };

// Các ngưỡng dưới đây là giá trị khởi điểm, dò lại ở bước BE-21–BE-22 trên dữ liệu cấp 3 thật.
/** Độ giống họ tên từ mức này trở lên là khớp mạnh. */
export const NAME_STRONG = 0.85;
/** Dưới mức này là họ tên khác nhiều so với học sinh được ghép. */
export const NAME_WEAK = 0.6;
/** Tỷ lệ dòng mức Đỏ do ghép tối đa; vượt thì dừng, yêu cầu ảnh khác. */
export const MAX_RED_RATIO = 0.3;
/** Họ tên khớp học sinh kề tốt hơn từ mức chênh này trở lên thì nghi lệch dòng. */
export const NEIGHBOR_MARGIN = 0.15;
/** STT đọc được chỉ được coi là mâu thuẫn khi độ tin cậy từ mức này trở lên. */
export const STT_CONFLICT_MIN_CONFIDENCE = 0.5;
/** Thưởng khi STT đọc được trùng STT của học sinh trong snapshot. */
export const STT_MATCH_BONUS = 0.5;
/** Phạt khi STT đọc được (tin cậy) khác STT của học sinh trong snapshot. */
export const STT_CONFLICT_PENALTY = 0.3;
/** Phạt cho mỗi học sinh trong snapshot bị bỏ qua giữa hai dòng liên tiếp (đầu/cuối danh sách không phạt). */
export const GAP_PENALTY = 0.3;
/** Độ giống quy ước khi dòng không có họ tên đọc được: không thưởng cũng không phạt nặng. */
export const UNKNOWN_NAME_SIMILARITY = 0.4;
/** Điểm cơ sở trừ khỏi mỗi phép ghép để ghép kém không có lợi hơn bỏ qua dòng không có điểm. */
export const PAIR_BASELINE = 0.5;

const LEVEL_RANK: Record<ReviewLevel, number> = { DO: 0, VANG: 1, XANH: 2 };

/** Mức thấp hơn giữa hai mức (DO < VANG < XANH). */
export function combineLevel(
  gradeLevel: ReviewLevel,
  matchLevel: ReviewLevel,
): ReviewLevel {
  return LEVEL_RANK[gradeLevel] <= LEVEL_RANK[matchLevel]
    ? gradeLevel
    : matchLevel;
}

/** NFC, bỏ dấu, chữ thường, chỉ giữ chữ/số, gộp khoảng trắng. */
export function normalizeName(value: string | null | undefined): string {
  if (!value) return "";
  return value
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "d")
    .toLowerCase()
    .normalize("NFC")
    .replace(/[^\p{L}\p{N}\s]/gu, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function editDistance(a: string, b: string): number {
  if (a === b) return 0;
  if (!a) return b.length;
  if (!b) return a.length;
  let previous = Array.from({ length: b.length + 1 }, (_, index) => index);
  for (let i = 1; i <= a.length; i += 1) {
    const current = [i];
    for (let j = 1; j <= b.length; j += 1) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      current[j] = Math.min(
        (previous[j] ?? 0) + 1,
        (current[j - 1] ?? 0) + 1,
        (previous[j - 1] ?? 0) + cost,
      );
    }
    previous = current;
  }
  return previous[b.length] ?? 0;
}

/** 1 - khoảng cách sửa / độ dài, trên họ tên đã chuẩn hóa. */
export function nameSimilarity(a: string, b: string): number {
  const length = Math.max(a.length, b.length);
  if (length === 0) return 0;
  return 1 - editDistance(a, b) / length;
}

const round4 = (value: number) =>
  Math.round(Math.min(1, Math.max(0, value)) * 10_000) / 10_000;

function fail(
  reason: RowMatchFailureReason,
  detail: string,
): Extract<RowMatchResult, { ok: false }> {
  return { ok: false, code: "ROW_MATCH_FAILED", reason, detail };
}

interface Cell {
  score: number;
  /** Ô trước đó trong đường căn chỉnh; null nếu là dòng được ghép đầu tiên. */
  previous: { row: number; roster: number } | null;
}

export function matchRows(
  detected: DetectedRow[],
  roster: RosterEntry[],
): RowMatchResult {
  const skipped: SkippedRow[] = [];
  const rows: DetectedRow[] = [];
  for (const row of [...detected].sort((a, b) => a.rowIndex - b.rowIndex)) {
    if (row.struck) skipped.push({ rowIndex: row.rowIndex, reason: "STRUCK" });
    else if (!row.hasGradeInk && !row.hasNameInk)
      skipped.push({ rowIndex: row.rowIndex, reason: "EMPTY" });
    else rows.push(row);
  }
  const entries = [...roster].sort((a, b) => a.stt - b.stt);
  if (!rows.length) return fail("NO_ROWS", "Không có dòng nào có dữ liệu.");
  if (!entries.length) return fail("ROW_UNMATCHED", "Danh sách lớp rỗng.");

  const names = rows.map((row) => normalizeName(row.nameRaw));
  const rosterNames = entries.map((entry) => normalizeName(entry.fullName));
  // similarity[i][j]: null khi dòng i không có họ tên đọc được.
  const similarity = rows.map((_, i) =>
    names[i]
      ? rosterNames.map((name) => nameSimilarity(names[i]!, name))
      : null,
  );
  const sttConflict = (i: number, j: number): boolean => {
    const row = rows[i]!;
    return (
      row.sttValue !== null &&
      row.sttValue !== entries[j]!.stt &&
      (row.sttConfidence ?? 0) >= STT_CONFLICT_MIN_CONFIDENCE
    );
  };
  const pair = (i: number, j: number): number => {
    const sim = similarity[i]?.[j] ?? UNKNOWN_NAME_SIMILARITY;
    const row = rows[i]!;
    let score = sim - PAIR_BASELINE;
    if (row.sttValue !== null) {
      if (row.sttValue === entries[j]!.stt) score += STT_MATCH_BONUS;
      else if (sttConflict(i, j)) score -= STT_CONFLICT_PENALTY;
    }
    return score;
  };

  // Căn chỉnh quy hoạch động giữ thứ tự. Dòng có điểm bắt buộc phải được ghép; dòng chỉ có họ tên (ô điểm trống)
  // được ghép khi có lợi. Khoảng trống đầu/cuối danh sách lớp không phạt, khoảng trống giữa bị phạt.
  const n = rows.length;
  const m = entries.length;
  const table: Array<Array<Cell | null>> = Array.from({ length: n }, () =>
    Array.from({ length: m }, () => null),
  );
  const skippableBetween = (from: number, to: number): boolean => {
    for (let r = from + 1; r < to; r += 1)
      if (rows[r]!.hasGradeInk) return false;
    return true;
  };
  for (let i = 0; i < n; i += 1) {
    for (let j = 0; j < m; j += 1) {
      let best: Cell | null = null;
      if (skippableBetween(-1, i)) best = { score: pair(i, j), previous: null };
      for (let p = i - 1; p >= 0; p -= 1) {
        if (!skippableBetween(p, i)) break;
        for (let q = 0; q < j; q += 1) {
          const before = table[p]![q];
          if (!before) continue;
          const score = before.score + pair(i, j) - GAP_PENALTY * (j - q - 1);
          if (!best || score > best.score)
            best = { score, previous: { row: p, roster: q } };
        }
      }
      table[i]![j] = best;
    }
  }
  let end: { row: number; roster: number; score: number } | null = null;
  for (let i = 0; i < n; i += 1) {
    if (!skippableBetween(i, n)) continue;
    for (let j = 0; j < m; j += 1) {
      const cell = table[i]![j];
      if (cell && (!end || cell.score > end.score))
        end = { row: i, roster: j, score: cell.score };
    }
  }
  if (!end)
    return fail(
      "ROW_UNMATCHED",
      "Có dòng có điểm không ghép được với danh sách lớp (nhiều dòng hơn sĩ số hoặc sai thứ tự).",
    );
  const assignment = new Map<number, number>();
  for (
    let cursor: { row: number; roster: number } | null = end;
    cursor;
    cursor = table[cursor.row]![cursor.roster]!.previous
  )
    assignment.set(cursor.row, cursor.roster);

  // Hai dòng cùng chỉ khớp mạnh duy nhất một học sinh là cùng một học sinh xuất hiện hai lần.
  const strongTargets = similarity.map((row) => {
    if (!row) return [];
    const targets: number[] = [];
    row.forEach((value, index) => {
      if (value >= NAME_STRONG) targets.push(index);
    });
    return targets;
  });
  for (let a = 0; a < n; a += 1)
    for (let b = a + 1; b < n; b += 1) {
      const first = strongTargets[a]!;
      const second = strongTargets[b]!;
      if (first.length === 1 && second.length === 1 && first[0] === second[0])
        return fail(
          "DUPLICATE_STUDENT",
          `Dòng ${rows[a]!.rowIndex} và dòng ${rows[b]!.rowIndex} cùng khớp một học sinh (STT ${entries[first[0]!]!.stt}).`,
        );
    }

  const matches: RowMatch[] = [];
  for (let i = 0; i < n; i += 1) {
    const j = assignment.get(i);
    const row = rows[i]!;
    if (j === undefined) {
      // Dòng không điểm bị bỏ qua: không có học sinh nào đáng ghép.
      skipped.push({ rowIndex: row.rowIndex, reason: "UNMATCHED_BLANK" });
      continue;
    }
    matches.push(describe(row, i, j, entries, similarity, rosterNames));
  }
  if (new Set(matches.map((match) => match.studentId)).size !== matches.length)
    return fail("DUPLICATE_STUDENT", "Hai dòng được ghép cùng một học sinh.");
  const red = matches.filter((match) => match.matchLevel === "DO").length;
  if (matches.length && red / matches.length > MAX_RED_RATIO)
    return fail(
      "TOO_MANY_LOW_CONFIDENCE",
      `${red}/${matches.length} dòng không ghép được chắc chắn với danh sách lớp.`,
    );
  matches.sort((a, b) => a.rowIndex - b.rowIndex);
  skipped.sort((a, b) => a.rowIndex - b.rowIndex);
  return { ok: true, matches, skipped };
}

function describe(
  row: DetectedRow,
  i: number,
  j: number,
  entries: RosterEntry[],
  similarity: Array<number[] | null>,
  rosterNames: string[],
): RowMatch {
  const entry = entries[j]!;
  const sims = similarity[i];
  const sim = sims ? sims[j]! : null;
  const sttKnown = row.sttValue !== null;
  const sttMatches = sttKnown && row.sttValue === entry.stt;
  const confidentConflict =
    sttKnown &&
    !sttMatches &&
    (row.sttConfidence ?? 0) >= STT_CONFLICT_MIN_CONFIDENCE;
  const duplicatedName = rosterNames.some(
    (name, index) => index !== j && !!name && name === rosterNames[j],
  );
  const neighbors = [j - 1, j + 1].filter((k) => k >= 0 && k < entries.length);
  const betterNeighbor =
    sim === null
      ? null
      : (neighbors.find((k) => (sims![k] ?? 0) > sim + NEIGHBOR_MARGIN) ??
        null);

  let level: ReviewLevel;
  let note: string;
  if (confidentConflict) {
    level = "DO";
    note = `STT trên giấy (${row.sttValue}) khác STT hệ thống (${entry.stt}).`;
  } else if (betterNeighbor !== null) {
    level = "DO";
    note = `Họ tên khớp STT ${entries[betterNeighbor]!.stt} hơn STT ${entry.stt}; nghi lệch dòng.`;
  } else if (sim === null && !sttKnown) {
    // Không có bằng chứng định danh nào: chỉ dựa vào vị trí, nên không đủ tin để bỏ qua.
    level = "DO";
    note = `Không đọc được STT lẫn họ tên; chỉ ghép theo vị trí (STT ${entry.stt}).`;
  } else if (sim === null) {
    level = "VANG";
    note = sttMatches
      ? `Không đọc được họ tên; ghép theo STT ${entry.stt}.`
      : `Không đọc được họ tên; ghép theo vị trí (STT ${entry.stt}).`;
  } else if (sim < NAME_WEAK) {
    level = "DO";
    note = `Họ tên khác nhiều so với danh sách (độ giống ${sim.toFixed(2)}).`;
  } else if (sim < NAME_STRONG) {
    level = "VANG";
    note = `Họ tên khớp một phần (độ giống ${sim.toFixed(2)}).`;
  } else if (duplicatedName) {
    level = "VANG";
    note = "Trùng họ tên với học sinh khác trong lớp; ghép theo STT/thứ tự.";
  } else if (sttKnown && !sttMatches) {
    level = "VANG";
    note = `STT trên giấy (${row.sttValue}) khác STT hệ thống (${entry.stt}) nhưng độ tin cậy thấp.`;
  } else {
    level = "XANH";
    note = sttMatches
      ? "Khớp họ tên và STT."
      : "Khớp họ tên; STT không đọc được.";
  }
  const nameComponent = sim ?? 0.5;
  const sttComponent = sttMatches ? 1 : sttKnown ? 0 : 0.5;
  return {
    rowIndex: row.rowIndex,
    stt: entry.stt,
    studentId: entry.studentId,
    sttOnPaper: row.sttValue,
    nameRead: row.nameRaw,
    matchConfidence: round4(0.7 * nameComponent + 0.3 * sttComponent),
    matchLevel: level,
    note: note.slice(0, 200),
  };
}
