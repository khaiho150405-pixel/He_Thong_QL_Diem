// Ghép dòng trên ảnh với danh sách lớp đã chốt của phiếu (ADR-0015). Miền thuần: không import NestJS/Prisma.
//
// Máy chỉ đề xuất. Hàm này không chọn điểm; nó chỉ gán mỗi dòng có dữ liệu cho một học sinh trong snapshot
// (theo họ tên đọc được trên giấy, STT nếu có, thứ tự dòng chỉ là điểm thưởng nhỏ) và đánh giá độ chắc chắn của phép
// ghép. Ghép một-một tối ưu toàn cục (Hungarian), nên thứ tự trên giấy khác thứ tự hệ thống vẫn ghép đúng theo tên.
// Không ghép được thì dừng.

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

// Ngưỡng khóa ở BE-22 theo tập DEV của mẫu E0330113 (chưa có bảng điểm cấp 3 thật): NAME_STRONG/NAME_WEAK giữ nguyên;
// MAX_RED_RATIO 0,30 → 0,34 vì trang 2 chỉ có 3 dòng bị từ chối khi có đúng 1 dòng Đỏ (33%); trên DEV không làm tăng dòng gán sai.
/** Độ giống họ tên từ mức này trở lên là khớp mạnh. */
export const NAME_STRONG = 0.85;
/** Dưới mức này là họ tên khác nhiều so với học sinh được ghép. */
export const NAME_WEAK = 0.6;
/** Tỷ lệ dòng mức Đỏ do ghép tối đa; vượt thì dừng, yêu cầu ảnh khác. */
export const MAX_RED_RATIO = 0.34;
/** Họ tên khớp học sinh kề tốt hơn từ mức chênh này trở lên thì nghi lệch dòng. */
export const NEIGHBOR_MARGIN = 0.15;
/** STT đọc được chỉ được coi là mâu thuẫn khi độ tin cậy từ mức này trở lên. */
export const STT_CONFLICT_MIN_CONFIDENCE = 0.5;
/** Thưởng khi STT đọc được trùng STT của học sinh trong snapshot. */
export const STT_MATCH_BONUS = 0.5;
/** Phạt khi STT đọc được (tin cậy) khác STT của học sinh trong snapshot. */
export const STT_CONFLICT_PENALTY = 0.3;
/** Điểm thưởng tối đa (giảm dần theo độ lệch) khi dòng nằm đúng vị trí dự kiến; chỉ để phân xử khi tên yếu/trùng. */
export const ORDER_BONUS = 0.1;
/** Ghi chú khi họ tên khớp mạnh nhưng thứ tự dòng trên giấy khác thứ tự hệ thống. */
export const ORDER_NOTE = "Thứ tự trên giấy khác hệ thống.";
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

/** Chi phí cấm: dòng bắt buộc không được rơi vào cột "bỏ trống". */
const FORBIDDEN = 1e6;

/**
 * Bài toán phân công chi phí nhỏ nhất (Hungarian, O(n²·p)); ``cost`` có n hàng và p ≥ n cột. Trả về chỉ số cột cho
 * từng hàng.
 */
function assignMinCost(cost: number[][]): number[] {
  const n = cost.length;
  const p = cost[0]!.length;
  const u = new Array<number>(n + 1).fill(0);
  const v = new Array<number>(p + 1).fill(0);
  const owner = new Array<number>(p + 1).fill(0);
  const way = new Array<number>(p + 1).fill(0);
  for (let i = 1; i <= n; i += 1) {
    owner[0] = i;
    let j0 = 0;
    const minv = new Array<number>(p + 1).fill(Infinity);
    const used = new Array<boolean>(p + 1).fill(false);
    do {
      used[j0] = true;
      const i0 = owner[j0]!;
      let delta = Infinity;
      let j1 = 0;
      for (let j = 1; j <= p; j += 1) {
        if (used[j]) continue;
        const current = cost[i0 - 1]![j - 1]! - u[i0]! - v[j]!;
        if (current < minv[j]!) {
          minv[j] = current;
          way[j] = j0;
        }
        if (minv[j]! < delta) {
          delta = minv[j]!;
          j1 = j;
        }
      }
      for (let j = 0; j <= p; j += 1) {
        if (used[j]) {
          u[owner[j]!] = u[owner[j]!]! + delta;
          v[j] = v[j]! - delta;
        } else minv[j] = minv[j]! - delta;
      }
      j0 = j1;
    } while (owner[j0] !== 0);
    do {
      const j1 = way[j0]!;
      owner[j0] = owner[j1]!;
      j0 = j1;
    } while (j0 !== 0);
  }
  const result = new Array<number>(n).fill(-1);
  for (let j = 1; j <= p; j += 1)
    if (owner[j]! > 0) result[owner[j]! - 1] = j - 1;
  return result;
}

/** Các dòng (theo thứ tự trên trang) không thuộc dãy tăng dài nhất của chỉ số học sinh: dòng bị đảo thứ tự. */
function outOfOrderRows(
  order: number[],
  assignment: Map<number, number>,
): Set<number> {
  const sequence = order.filter((i) => assignment.has(i));
  const length = sequence.map(() => 1);
  const previous = sequence.map(() => -1);
  let best = -1;
  for (let a = 0; a < sequence.length; a += 1) {
    for (let b = 0; b < a; b += 1)
      if (
        assignment.get(sequence[b]!)! < assignment.get(sequence[a]!)! &&
        length[b]! + 1 > length[a]!
      ) {
        length[a] = length[b]! + 1;
        previous[a] = b;
      }
    if (best < 0 || length[a]! > length[best]!) best = a;
  }
  const inOrder = new Set<number>();
  for (let cursor = best; cursor >= 0; cursor = previous[cursor]!)
    inOrder.add(sequence[cursor]!);
  const flagged = new Set<number>();
  for (const row of sequence) if (!inOrder.has(row)) flagged.add(row);
  // Hai dòng kề nhau đổi chỗ cho nhau (chỉ số học sinh cách nhau ≤ 2): đánh dấu cả hai, không chỉ dòng nằm ngoài dãy tăng dài nhất.
  for (let index = 0; index + 1 < sequence.length; index += 1) {
    const first = sequence[index]!;
    const second = sequence[index + 1]!;
    if (
      assignment.get(first)! > assignment.get(second)! &&
      assignment.get(first)! - assignment.get(second)! <= 2 &&
      (flagged.has(first) || flagged.has(second))
    ) {
      flagged.add(first);
      flagged.add(second);
    }
  }
  return flagged;
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
    // Lập phương độ giống: khớp tốt không bị đánh đổi lấy vài phần trăm cải thiện ở dòng đọc kém.
    let score = sim ** 3 - PAIR_BASELINE ** 3;
    if (row.sttValue !== null) {
      if (row.sttValue === entries[j]!.stt) score += STT_MATCH_BONUS;
      else if (sttConflict(i, j)) score -= STT_CONFLICT_PENALTY;
    }
    return score;
  };

  // Ghép một-một tối ưu toàn cục theo họ tên (và STT nếu đọc được). Dòng có điểm bắt buộc phải được ghép; dòng chỉ có
  // họ tên (ô điểm trống) được ghép khi có lợi; học sinh không có trên trang được bỏ trống. Thứ tự dòng chỉ là điểm
  // thưởng nhỏ quanh vị trí dự kiến (độ lệch ước lượng từ các dòng khớp tên mạnh) để phân xử khi tên yếu hoặc trùng.
  const n = rows.length;
  const m = entries.length;
  const mandatory = rows.map((row) => row.hasGradeInk);
  if (mandatory.filter(Boolean).length > m)
    return fail(
      "ROW_UNMATCHED",
      "Có dòng có điểm không ghép được với danh sách lớp (nhiều dòng hơn sĩ số).",
    );
  const solve = (
    extra: (i: number, j: number) => number,
  ): Map<number, number> => {
    const cost = rows.map((_, i) => [
      ...entries.map((_entry, j) => -(pair(i, j) + extra(i, j))),
      ...rows.map((_row, k) => (k === i && !mandatory[i] ? 0 : FORBIDDEN)),
    ]);
    const chosen = assignMinCost(cost);
    const result = new Map<number, number>();
    chosen.forEach((column, i) => {
      if (column < m) result.set(i, column);
    });
    return result;
  };
  const first = solve(() => 0);
  const offsets = [...first.entries()]
    .filter(([i, j]) => (similarity[i]?.[j] ?? 0) >= NAME_STRONG)
    .map(([i, j]) => j - (rows[i]!.rowIndex - 1))
    .sort((a, b) => a - b);
  const offset = offsets.length
    ? offsets[Math.floor((offsets.length - 1) / 2)]!
    : 0;
  const assignment = solve(
    (i, j) =>
      ORDER_BONUS / (1 + Math.abs(j - (rows[i]!.rowIndex - 1 + offset))),
  );
  if (rows.some((_, i) => mandatory[i] && !assignment.has(i)))
    return fail(
      "ROW_UNMATCHED",
      "Có dòng có điểm không ghép được với danh sách lớp (nhiều dòng hơn sĩ số hoặc sai thứ tự).",
    );
  const flagged = outOfOrderRows(
    rows.map((_, i) => i),
    assignment,
  );

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
    matches.push(
      describe(row, i, j, entries, similarity, rosterNames, flagged.has(i)),
    );
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
  outOfOrder: boolean,
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
    note = `Không đọc được họ tên; chỉ ghép theo vị trí (STT ${entry.stt}).`;
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
  } else if (outOfOrder) {
    // Họ tên khớp mạnh nên giữ mức theo tên; chỉ báo rằng thứ tự trên giấy khác hệ thống.
    level = sttKnown && !sttMatches ? "VANG" : "XANH";
    note = ORDER_NOTE;
  } else if (sttKnown && !sttMatches) {
    level = "VANG";
    note = `STT trên giấy (${row.sttValue}) khác STT hệ thống (${entry.stt}) nhưng độ tin cậy thấp.`;
  } else {
    level = "XANH";
    note = sttMatches ? "Khớp họ tên và STT." : "Khớp họ tên.";
  }
  // Độ tin cậy ghép chỉ dựa vào họ tên (STT đã tắt có chủ đích nên không tham gia); không đọc được tên thì 0,5.
  const nameComponent = sim ?? 0.5;
  return {
    rowIndex: row.rowIndex,
    stt: entry.stt,
    studentId: entry.studentId,
    sttOnPaper: row.sttValue,
    nameRead: row.nameRaw,
    matchConfidence: round4(nameComponent),
    matchLevel: level,
    note: note.slice(0, 200),
  };
}
