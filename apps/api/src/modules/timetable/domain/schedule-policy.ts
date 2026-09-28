export interface TimetableSlot {
  ma_mon: number;
  tiet: number;
}

const sessionOf = (period: number) => (period <= 5 ? "morning" : "afternoon");

/**
 * Validates one class/day after a timetable mutation.
 * A day with fewer than three periods is treated as an unfinished draft.
 */
export function validateClassDaySchedule(slots: TimetableSlot[]): void {
  for (const session of ["morning", "afternoon"] as const) {
    const sessionSlots = slots.filter(
      (slot) => sessionOf(slot.tiet) === session,
    );
    if (sessionSlots.length > 4) {
      throw new Error(`Mỗi buổi chỉ được xếp tối đa 4 tiết học.`);
    }

    const bySubject = new Map<number, number[]>();
    for (const slot of sessionSlots) {
      const periods = bySubject.get(slot.ma_mon) ?? [];
      periods.push(slot.tiet);
      bySubject.set(slot.ma_mon, periods);
    }
    for (const periods of bySubject.values()) {
      periods.sort((a, b) => a - b);
      if (periods.length > 2) {
        throw new Error(
          "Một môn không được xếp quá 2 tiết trong cùng một buổi.",
        );
      }
      if (periods.length === 2 && periods[1] !== periods[0]! + 1) {
        throw new Error(
          "Hai tiết cùng môn trong một buổi phải là tiết đôi liên tiếp.",
        );
      }
    }
  }

  if (slots.length >= 3 && new Set(slots.map((slot) => slot.ma_mon)).size < 3) {
    throw new Error("Mỗi ngày có từ 3 tiết phải học ít nhất 3 môn khác nhau.");
  }
}
