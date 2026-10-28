import type { Unit } from "../../../common/store.js";

export interface SchoolProfile {
  name: string;
  shortName: string;
  governingBody: string | null;
  address: string | null;
  phone: string | null;
  email: string | null;
  principal: string | null;
  hasLogo: boolean;
  version: number;
  updatedAt: string;
}
export interface SchoolLogoRef {
  key: string;
  contentType: string;
}
export interface SchoolLogoValue extends SchoolLogoRef {
  checksum: string;
}
export interface IdempotentCall {
  idempotencyKey: string;
  requestHash: string;
}
export interface SchoolUnit {
  authorization: Unit;
  profile(): Promise<SchoolProfile>;
  update(
    sessionHash: string,
    expectedVersion: number,
    data: Record<string, string | null>,
    call: IdempotentCall,
  ): Promise<void>;
  /** `logo = null` là gỡ logo. */
  setLogo(
    sessionHash: string,
    expectedVersion: number,
    logo: SchoolLogoValue | null,
    call: IdempotentCall,
  ): Promise<void>;
}
export interface SchoolStore {
  /** Đọc công khai, không cần phiên. */
  profile(): Promise<SchoolProfile>;
  logoRef(): Promise<SchoolLogoRef | null>;
  run<T>(work: (tx: SchoolUnit) => Promise<T>): Promise<T>;
}

export const SCHOOL_STORE = Symbol("SCHOOL_STORE");
