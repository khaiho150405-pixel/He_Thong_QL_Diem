export interface StudentRemovalStore {
  remove(
    sessionHash: string,
    studentId: number,
    reason: string,
  ): Promise<"DELETED" | "ANONYMIZED">;
}

export const STUDENT_REMOVAL_STORE = Symbol("STUDENT_REMOVAL_STORE");
