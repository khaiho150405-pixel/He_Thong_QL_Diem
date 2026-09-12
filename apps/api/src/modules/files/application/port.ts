export interface StoredObject {
  key: string;
  bytes: Uint8Array;
  contentType: "image/png" | "image/jpeg";
  checksum: string;
}

export interface ObjectStorage {
  put(object: StoredObject): Promise<void>;
  get(key: string): Promise<Uint8Array>;
  signedGetUrl(key: string, expiresInSeconds: number): Promise<string>;
  remove(key: string): Promise<void>;
}

export const OBJECT_STORAGE = Symbol("OBJECT_STORAGE");
