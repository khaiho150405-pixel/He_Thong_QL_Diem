export type ReviewLevel = "XANH" | "VANG" | "DO";

export interface DetectedRow {
  rowIndex: number;
  struck: boolean;
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
  stt: number;
  studentId: number;
  sttOnPaper: number | null;
  nameRead: string | null;
  matchConfidence: number;
  matchLevel: ReviewLevel;
  note: string;
}

export type SttConvention = "A" | "B";

export interface SttModel {
  convention: SttConvention;
  k: number;
  strikeShift: boolean;
  support: number;
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
  | {
      ok: true;
      matches: RowMatch[];
      skipped: SkippedRow[];
      stt: { enabled: boolean; model: SttModel | null; evidence: number };
    }
  | {
      ok: false;
      code: "ROW_MATCH_FAILED";
      reason: RowMatchFailureReason;
      detail: string;
    };

export const NAME_STRONG = 0.85;
export const NAME_WEAK = 0.6;
export const MAX_RED_RATIO = 0.34;
export const NEIGHBOR_MARGIN = 0.15;
export const ORDER_BONUS = 0.1;
export const ORDER_NOTE = "Thứ tự trên giấy khác hệ thống.";
export const UNKNOWN_NAME_SIMILARITY = 0.4;
export const PAIR_BASELINE = 0.5;

const LEVEL_RANK: Record<ReviewLevel, number> = { DO: 0, VANG: 1, XANH: 2 };

export function combineLevel(
  gradeLevel: ReviewLevel,
  matchLevel: ReviewLevel,
): ReviewLevel {
  return LEVEL_RANK[gradeLevel] <= LEVEL_RANK[matchLevel]
    ? gradeLevel
    : matchLevel;
}

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

const FORBIDDEN = 1e6;

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

export interface MatchOptions {
  sttCheck?: boolean;
}

export interface BatchDetectedRow extends DetectedRow {
  page: number;
}

export interface BatchRowMatch extends RowMatch {
  page: number;
}

export interface BatchSkippedRow extends SkippedRow {
  page: number;
}

export interface BatchSttPage {
  page: number;
  model: SttModel | null;
  evidence: number;
}

export type BatchMatchResult =
  | {
      ok: true;
      matches: BatchRowMatch[];
      skipped: BatchSkippedRow[];
      stt: { enabled: boolean; pages: BatchSttPage[] };
    }
  | Extract<RowMatchResult, { ok: false }>;

export function matchRows(
  detected: DetectedRow[],
  roster: RosterEntry[],
  options: MatchOptions = {},
): RowMatchResult {
  const result = matchPaged(
    detected.map((row) => ({ ...row, page: 1 })),
    roster,
    options,
  );
  if (!result.ok) return result;
  const single = result.stt.pages[0];
  return {
    ok: true,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    matches: result.matches.map(({ page: _page, ...match }) => match),
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    skipped: result.skipped.map(({ page: _page, ...item }) => item),
    stt: {
      enabled: result.stt.enabled,
      model: single?.model ?? null,
      evidence: single?.evidence ?? 0,
    },
  };
}

export function matchBatchRows(
  detected: BatchDetectedRow[],
  roster: RosterEntry[],
  options: MatchOptions = {},
): BatchMatchResult {
  return matchPaged(detected, roster, options);
}

function matchPaged(
  detected: BatchDetectedRow[],
  roster: RosterEntry[],
  options: MatchOptions,
): BatchMatchResult {
  const skipped: BatchSkippedRow[] = [];
  const rows: BatchDetectedRow[] = [];
  const byPosition = (
    a: { page: number; rowIndex: number },
    b: { page: number; rowIndex: number },
  ) => a.page - b.page || a.rowIndex - b.rowIndex;
  for (const row of [...detected].sort(byPosition)) {
    if (row.struck)
      skipped.push({
        page: row.page,
        rowIndex: row.rowIndex,
        reason: "STRUCK",
      });
    else if (!row.hasGradeInk && !row.hasNameInk)
      skipped.push({ page: row.page, rowIndex: row.rowIndex, reason: "EMPTY" });
    else rows.push(row);
  }
  const pageNumbers = [...new Set(detected.map((row) => row.page))].sort(
    (a, b) => a - b,
  );
  const multiPage = pageNumbers.length > 1;
  const where = (row: BatchDetectedRow) =>
    multiPage ? `${row.page}.${row.rowIndex}` : String(row.rowIndex);
  const entries = [...roster].sort((a, b) => a.stt - b.stt);
  if (!rows.length) return fail("NO_ROWS", "Không có dòng nào có dữ liệu.");
  if (!entries.length) return fail("ROW_UNMATCHED", "Danh sách lớp rỗng.");

  const names = rows.map((row) => normalizeName(row.nameRaw));
  const rosterNames = entries.map((entry) => normalizeName(entry.fullName));
  const similarity = rows.map((_, i) =>
    names[i]
      ? rosterNames.map((name) => nameSimilarity(names[i]!, name))
      : null,
  );
  const pair = (i: number, j: number): number => {
    const sim = similarity[i]?.[j] ?? UNKNOWN_NAME_SIMILARITY;
    return sim ** 3 - PAIR_BASELINE ** 3;
  };
  const sttActive = options.sttCheck === true;

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
  const offsetByPage = new Map<number, number>();
  let carry = 0;
  for (const page of pageNumbers) {
    const offsets = [...first.entries()]
      .filter(
        ([i, j]) =>
          rows[i]!.page === page && (similarity[i]?.[j] ?? 0) >= NAME_STRONG,
      )
      .map(([i, j]) => j - (rows[i]!.rowIndex - 1))
      .sort((a, b) => a - b);
    const offset = offsets.length
      ? offsets[Math.floor((offsets.length - 1) / 2)]!
      : carry;
    offsetByPage.set(page, offset);
    carry =
      offset +
      Math.max(
        0,
        ...detected.filter((row) => row.page === page).map((r) => r.rowIndex),
      );
  }
  const assignment = solve(
    (i, j) =>
      ORDER_BONUS /
      (1 +
        Math.abs(
          j - (rows[i]!.rowIndex - 1 + offsetByPage.get(rows[i]!.page)!),
        )),
  );
  if (rows.some((_, i) => mandatory[i] && !assignment.has(i)))
    return fail(
      "ROW_UNMATCHED",
      "Có dòng có điểm không ghép được với danh sách lớp (nhiều dòng hơn sĩ số hoặc sai thứ tự).",
    );
  const rowsOfPage = (page: number): number[] =>
    rows.flatMap((row, i) => (row.page === page ? [i] : []));
  const flagged = new Set<number>();
  for (const page of pageNumbers)
    for (const i of outOfOrderRows(rowsOfPage(page), assignment))
      flagged.add(i);

  const struckBefore = rows.map(
    (row) =>
      detected.filter(
        (other) =>
          other.struck &&
          other.page === row.page &&
          other.rowIndex < row.rowIndex,
      ).length,
  );
  const sttBy: Record<SttConvention, number[]> = {
    A: entries.map((entry) => entry.stt),
    B: accentFoldedNumbers(entries),
  };
  const isDuplicatedName = (j: number): boolean =>
    rosterNames.some(
      (name, index) => index !== j && !!name && name === rosterNames[j],
    );
  const evidence = [...assignment.entries()]
    .filter(
      ([i, j]) =>
        rows[i]!.sttValue !== null &&
        (similarity[i]?.[j] ?? 0) >= NAME_STRONG &&
        !isDuplicatedName(j),
    )
    .map(([i, j]) => ({ i, j }));
  const models = new Map<number, SttModel | null>();
  const sttPages: BatchSttPage[] = pageNumbers.map((page) => {
    const pageRows = rowsOfPage(page);
    const pageEvidence = evidence.filter(({ i }) => rows[i]!.page === page);
    const model = sttActive
      ? chooseSttModel(
          pageEvidence,
          rows,
          sttBy,
          struckBefore,
          pageRows.length <= 5 ? 2 : 3,
        )
      : null;
    models.set(page, model);
    return { page, model, evidence: pageEvidence.length };
  });
  const expectedPaper = (i: number, j: number): number | null => {
    const model = models.get(rows[i]!.page) ?? null;
    return model === null
      ? null
      : sttBy[model.convention][j]! +
          model.k +
          (model.strikeShift ? struckBefore[i]! : 0);
  };
  const duplicateState = new Map<number, "RESOLVED" | "AMBIGUOUS">();
  if (sttActive)
    resolveDuplicateNames(
      rows,
      assignment,
      rosterNames,
      expectedPaper,
      duplicateState,
    );

  const targetOf = (similar: number[] | null): number | null => {
    if (!similar) return null;
    const top = Math.max(...similar);
    if (top < NAME_STRONG) return null;
    const first = similar.indexOf(top);
    return similar.indexOf(top, first + 1) === -1 ? first : null;
  };
  const targets = similarity.map(targetOf);
  for (let a = 0; a < n; a += 1)
    for (let b = a + 1; b < n; b += 1) {
      const target = targets[a];
      if (target != null && target === targets[b])
        return fail(
          "DUPLICATE_STUDENT",
          `Dòng ${where(rows[a]!)} và dòng ${where(rows[b]!)} cùng khớp một học sinh (STT ${entries[target]!.stt})${multiPage ? "; vị trí ghi theo dạng trang.dòng" : ""}.`,
        );
    }

  const matches: BatchRowMatch[] = [];
  for (let i = 0; i < n; i += 1) {
    const j = assignment.get(i);
    const row = rows[i]!;
    if (j === undefined) {
      skipped.push({
        page: row.page,
        rowIndex: row.rowIndex,
        reason: "UNMATCHED_BLANK",
      });
      continue;
    }
    matches.push({
      ...describe(row, i, j, entries, similarity, rosterNames, flagged.has(i), {
        active: sttActive,
        hasModel: models.get(row.page) != null,
        expected: expectedPaper(i, j),
        duplicate: duplicateState.get(i) ?? null,
      }),
      page: row.page,
    });
  }
  if (new Set(matches.map((match) => match.studentId)).size !== matches.length)
    return fail("DUPLICATE_STUDENT", "Hai dòng được ghép cùng một học sinh.");
  const red = matches.filter((match) => match.matchLevel === "DO").length;
  if (matches.length && red / matches.length > MAX_RED_RATIO)
    return fail(
      "TOO_MANY_LOW_CONFIDENCE",
      `${red}/${matches.length} dòng không ghép được chắc chắn với danh sách lớp.`,
    );
  matches.sort(byPosition);
  skipped.sort(byPosition);
  return {
    ok: true,
    matches,
    skipped,
    stt: { enabled: sttActive, pages: sttPages },
  };
}

const stripAccents = (value: string): string =>
  value
    .normalize("NFD")
    .replace(/\p{M}/gu, "")
    .replace(/đ/g, "d")
    .replace(/Đ/g, "D");
const baseCollator = new Intl.Collator("en", { sensitivity: "base" });
const viCollator = new Intl.Collator("vi", { sensitivity: "variant" });

function accentFoldedNumbers(entries: RosterEntry[]): number[] {
  const given = (name: string) => name.trim().split(/\s+/).at(-1) ?? "";
  const order = entries
    .map((entry, index) => ({ entry, index }))
    .sort(
      (a, b) =>
        baseCollator.compare(
          stripAccents(given(a.entry.fullName)),
          stripAccents(given(b.entry.fullName)),
        ) ||
        baseCollator.compare(
          stripAccents(a.entry.fullName.trim()),
          stripAccents(b.entry.fullName.trim()),
        ) ||
        viCollator.compare(given(a.entry.fullName), given(b.entry.fullName)) ||
        viCollator.compare(a.entry.fullName.trim(), b.entry.fullName.trim()) ||
        a.entry.studentId - b.entry.studentId,
    );
  const numbers = new Array<number>(entries.length).fill(0);
  order.forEach(({ index }, position) => {
    numbers[index] = position + 1;
  });
  return numbers;
}

function chooseSttModel(
  evidence: Array<{ i: number; j: number }>,
  rows: DetectedRow[],
  sttBy: Record<SttConvention, number[]>,
  struckBefore: number[],
  minSupport: number,
): SttModel | null {
  let best: SttModel | null = null;
  for (const strikeShift of [false, true])
    for (const convention of ["A", "B"] as const) {
      const counts = new Map<number, number>();
      for (const { i, j } of evidence) {
        const delta =
          rows[i]!.sttValue! -
          (sttBy[convention][j]! + (strikeShift ? struckBefore[i]! : 0));
        counts.set(delta, (counts.get(delta) ?? 0) + 1);
      }
      const [k, support] = [...counts.entries()].sort(
        (x, y) => y[1] - x[1] || Math.abs(x[0]) - Math.abs(y[0]) || x[0] - y[0],
      )[0] ?? [0, 0];
      if (support >= minSupport && (best === null || support > best.support))
        best = { convention, k, strikeShift, support };
    }
  return best;
}

function resolveDuplicateNames(
  rows: BatchDetectedRow[],
  assignment: Map<number, number>,
  rosterNames: string[],
  expectedPaper: (i: number, j: number) => number | null,
  state: Map<number, "RESOLVED" | "AMBIGUOUS">,
): void {
  const groups = new Map<string, number[]>();
  rosterNames.forEach((name, j) => {
    if (!name) return;
    groups.set(name, [...(groups.get(name) ?? []), j]);
  });
  for (const members of groups.values()) {
    if (members.length < 2) continue;
    const memberSet = new Set(members);
    const group = [...assignment.entries()]
      .filter(([, j]) => memberSet.has(j))
      .map(([i]) => i)
      .sort(
        (a, b) =>
          rows[a]!.page - rows[b]!.page ||
          rows[a]!.rowIndex - rows[b]!.rowIndex,
      );
    if (!group.length) continue;
    const claims = new Map<number, number[]>();
    for (const i of group) {
      const wanted = rows[i]!.sttValue;
      const hits = members.filter((j) => expectedPaper(i, j) === wanted);
      if (wanted !== null && hits.length === 1)
        claims.set(hits[0]!, [...(claims.get(hits[0]!) ?? []), i]);
    }
    const taken = new Set<number>();
    for (const [j, claimants] of claims)
      if (claimants.length === 1) {
        assignment.set(claimants[0]!, j);
        state.set(claimants[0]!, "RESOLVED");
        taken.add(j);
      }
    const free = members.filter((j) => !taken.has(j));
    for (const i of group) {
      if (state.has(i)) continue;
      const current = assignment.get(i)!;
      const pick = free.includes(current) ? current : free[0]!;
      free.splice(free.indexOf(pick), 1);
      assignment.set(i, pick);
      state.set(i, "AMBIGUOUS");
    }
  }
}

interface SttContext {
  active: boolean;
  hasModel: boolean;
  expected: number | null;
  duplicate: "RESOLVED" | "AMBIGUOUS" | null;
}

function describe(
  row: DetectedRow,
  i: number,
  j: number,
  entries: RosterEntry[],
  similarity: Array<number[] | null>,
  rosterNames: string[],
  outOfOrder: boolean,
  stt: SttContext,
): RowMatch {
  const entry = entries[j]!;
  const sims = similarity[i];
  const sim = sims ? sims[j]! : null;
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
  if (betterNeighbor !== null) {
    level = "DO";
    note = `Họ tên khớp STT ${entries[betterNeighbor]!.stt} hơn STT ${entry.stt}; nghi lệch dòng.`;
  } else if (sim === null) {
    level = "DO";
    note = `Không đọc được họ tên; chỉ ghép theo vị trí (STT ${entry.stt}).`;
  } else if (sim < NAME_WEAK) {
    level = "DO";
    note = `Họ tên khác nhiều so với danh sách (độ giống ${sim.toFixed(2)}).`;
  } else if (sim < NAME_STRONG) {
    level = "VANG";
    note = `Họ tên khớp một phần (độ giống ${sim.toFixed(2)}).`;
  } else if (duplicatedName) {
    if (!stt.active) {
      level = "VANG";
      note = "Trùng họ tên với học sinh khác trong lớp; ghép theo thứ tự.";
    } else if (stt.duplicate === "RESOLVED") {
      level = "VANG";
      note = `Trùng họ tên — phân biệt bằng STT ${row.sttValue}.`;
    } else {
      level = "DO";
      note = "Trùng họ tên — không phân biệt được bằng STT.";
    }
  } else if (stt.active) {
    if (!stt.hasModel || row.sttValue === null || stt.expected === null) {
      level = "VANG";
      note = "Không xác nhận được STT.";
    } else if (row.sttValue !== stt.expected) {
      level = "VANG";
      note = `STT trên giấy ${row.sttValue} khác STT dự kiến ${stt.expected}.`;
    } else {
      level = "XANH";
      note = "Khớp họ tên và STT.";
    }
  } else if (outOfOrder) {
    level = "XANH";
    note = ORDER_NOTE;
  } else {
    level = "XANH";
    note = "Khớp họ tên.";
  }
  if (
    stt.active &&
    level === "VANG" &&
    sim !== null &&
    sim < NAME_STRONG &&
    stt.expected !== null &&
    row.sttValue !== null &&
    row.sttValue !== stt.expected
  ) {
    level = "DO";
    note = `${note} STT trên giấy ${row.sttValue} khác STT dự kiến ${stt.expected}.`;
  }
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
