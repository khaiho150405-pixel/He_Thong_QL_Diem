import type { Settings } from "../../common/database.js";
import type { ObjectStorage } from "./application/port.js";
import { S3ObjectStorage } from "./infrastructure/s3-object-storage.js";

export type { ObjectStorage, StoredObject } from "./application/port.js";

export function makeObjectStorage(settings: Settings): ObjectStorage {
  return new S3ObjectStorage(settings);
}
