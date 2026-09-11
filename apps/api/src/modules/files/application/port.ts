export interface StoredObject {
  key: string;
  bytes: Uint8Array;
  contentType: "image/png" | "image/jpeg";
  checksum: string;
}

export interface ObjectStorage {
  put(object: StoredObject): Promise<void>;
  remove(key: string): Promise<void>;
}

export const OBJECT_STORAGE = Symbol("OBJECT_STORAGE");
