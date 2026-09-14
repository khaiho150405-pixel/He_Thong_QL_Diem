import { createHash } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import {
  GetObjectCommand,
  HeadBucketCommand,
  ListObjectsV2Command,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";

const FORMAT = "s3-object-backup-v1";
const RESTORE_SUFFIX = "-restore-test";

export interface StorageBackupObject {
  key: string;
  file: string;
  contentType?: string;
  size: number;
  sha256: string;
}

export interface StorageBackupManifest {
  format: typeof FORMAT;
  createdAt: string;
  sourceBucket: string;
  objects: StorageBackupObject[];
}

interface StorageSettings {
  endpoint: string;
  accessKeyId: string;
  secretAccessKey: string;
  sourceBucket: string;
  restoreBucket?: string;
}

function required(env: NodeJS.ProcessEnv, name: string) {
  const value = env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function validateBucketName(bucket: string, name: string) {
  if (
    !/^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$/.test(bucket) ||
    bucket.includes("..")
  )
    throw new Error(`${name} is not a valid S3 bucket name`);
}

export function readStorageSettings(
  env: NodeJS.ProcessEnv,
  restore = false,
): StorageSettings {
  const endpoint = required(env, "S3_ENDPOINT");
  const parsed = new URL(endpoint);
  if (!["http:", "https:"].includes(parsed.protocol))
    throw new Error("S3_ENDPOINT must use HTTP or HTTPS");
  const sourceBucket = required(env, "S3_BUCKET");
  const restoreBucket = restore
    ? required(env, "RESTORE_S3_BUCKET")
    : undefined;
  validateBucketName(sourceBucket, "S3_BUCKET");
  if (restoreBucket) validateBucketName(restoreBucket, "RESTORE_S3_BUCKET");
  if (restoreBucket && !restoreBucket.endsWith(RESTORE_SUFFIX))
    throw new Error(`Restore bucket must end with ${RESTORE_SUFFIX}`);
  if (restoreBucket === sourceBucket)
    throw new Error("Restore bucket must differ from source bucket");
  return {
    endpoint,
    accessKeyId: required(env, "S3_ACCESS_KEY"),
    secretAccessKey: required(env, "S3_SECRET_KEY"),
    sourceBucket,
    restoreBucket,
  };
}

export function cliArguments(values: string[]) {
  return values.filter((value) => value !== "--");
}

export function backupFileName(key: string) {
  return `${createHash("sha256").update(key).digest("hex")}.object`;
}

function checksum(bytes: Uint8Array) {
  return createHash("sha256").update(bytes).digest("hex");
}

function client(settings: StorageSettings) {
  return new S3Client({
    endpoint: settings.endpoint,
    region: "us-east-1",
    forcePathStyle: true,
    credentials: {
      accessKeyId: settings.accessKeyId,
      secretAccessKey: settings.secretAccessKey,
    },
  });
}

async function listKeys(s3: S3Client, bucket: string) {
  const keys: string[] = [];
  let continuationToken: string | undefined;
  do {
    const page = await s3.send(
      new ListObjectsV2Command({
        Bucket: bucket,
        ContinuationToken: continuationToken,
      }),
    );
    for (const object of page.Contents ?? []) {
      if (!object.Key) throw new Error("Object listing returned an empty key");
      keys.push(object.Key);
    }
    continuationToken = page.IsTruncated
      ? page.NextContinuationToken
      : undefined;
    if (page.IsTruncated && !continuationToken)
      throw new Error("Object listing pagination token missing");
  } while (continuationToken);
  return keys.sort();
}

async function getObject(s3: S3Client, bucket: string, key: string) {
  const result = await s3.send(
    new GetObjectCommand({ Bucket: bucket, Key: key }),
  );
  if (!result.Body) throw new Error(`Object body missing: ${key}`);
  return {
    bytes: await result.Body.transformToByteArray(),
    contentType: result.ContentType,
  };
}

function parseManifest(path: string): StorageBackupManifest {
  const value = JSON.parse(
    readFileSync(path, "utf8"),
  ) as Partial<StorageBackupManifest>;
  if (
    value.format !== FORMAT ||
    typeof value.createdAt !== "string" ||
    typeof value.sourceBucket !== "string" ||
    !Array.isArray(value.objects)
  )
    throw new Error("Storage backup manifest is invalid");
  const files = new Set<string>();
  const keys = new Set<string>();
  for (const object of value.objects) {
    if (
      typeof object?.key !== "string" ||
      !object.key ||
      typeof object.file !== "string" ||
      object.file !== backupFileName(object.key) ||
      typeof object.size !== "number" ||
      !Number.isSafeInteger(object.size) ||
      object.size < 0 ||
      typeof object.sha256 !== "string" ||
      !/^[a-f0-9]{64}$/.test(object.sha256) ||
      (object.contentType !== undefined &&
        typeof object.contentType !== "string") ||
      files.has(object.file) ||
      keys.has(object.key)
    )
      throw new Error("Storage backup manifest object is invalid");
    files.add(object.file);
    keys.add(object.key);
  }
  return value as StorageBackupManifest;
}

export function verifyStorageBackup(manifestPath: string) {
  const path = resolve(manifestPath);
  const manifest = parseManifest(path);
  for (const object of manifest.objects) {
    const bytes = new Uint8Array(
      readFileSync(join(dirname(path), "objects", object.file)),
    );
    if (bytes.byteLength !== object.size || checksum(bytes) !== object.sha256)
      throw new Error(`Storage backup checksum mismatch: ${object.key}`);
  }
  return manifest;
}

export async function backupStorage(
  settings: StorageSettings,
  outputDirectory: string,
) {
  const s3 = client(settings);
  const stamp = new Date().toISOString().replace(/[:.]/g, "-");
  const directory = resolve(
    outputDirectory,
    `${settings.sourceBucket}-${stamp}`,
  );
  const objectsDirectory = join(directory, "objects");
  mkdirSync(objectsDirectory, { recursive: true, mode: 0o700 });
  const objects: StorageBackupObject[] = [];
  try {
    const keys = await listKeys(s3, settings.sourceBucket);
    if (keys.length === 0)
      throw new Error("Source bucket is empty; rehearsal would prove nothing");
    for (const key of keys) {
      const object = await getObject(s3, settings.sourceBucket, key);
      const file = backupFileName(key);
      const finalPath = join(objectsDirectory, file);
      const temporaryPath = `${finalPath}.part`;
      try {
        writeFileSync(temporaryPath, object.bytes, { mode: 0o600 });
        renameSync(temporaryPath, finalPath);
      } finally {
        if (existsSync(temporaryPath)) rmSync(temporaryPath);
      }
      objects.push({
        key,
        file,
        ...(object.contentType ? { contentType: object.contentType } : {}),
        size: object.bytes.byteLength,
        sha256: checksum(object.bytes),
      });
    }
    const manifest: StorageBackupManifest = {
      format: FORMAT,
      createdAt: new Date().toISOString(),
      sourceBucket: settings.sourceBucket,
      objects,
    };
    const manifestPath = join(directory, "manifest.json");
    const temporaryManifestPath = `${manifestPath}.part`;
    try {
      writeFileSync(
        temporaryManifestPath,
        `${JSON.stringify(manifest, null, 2)}\n`,
        { mode: 0o600 },
      );
      renameSync(temporaryManifestPath, manifestPath);
    } finally {
      if (existsSync(temporaryManifestPath)) rmSync(temporaryManifestPath);
    }
    return manifestPath;
  } finally {
    s3.destroy();
  }
}

export async function restoreStorage(
  settings: StorageSettings,
  manifestPath: string,
) {
  if (!settings.restoreBucket)
    throw new Error("Restore storage settings required");
  const manifest = verifyStorageBackup(manifestPath);
  if (manifest.sourceBucket !== settings.sourceBucket)
    throw new Error("Backup source bucket does not match S3_BUCKET");
  const directory = dirname(resolve(manifestPath));
  const s3 = client(settings);
  try {
    await s3.send(new HeadBucketCommand({ Bucket: settings.restoreBucket }));
    if ((await listKeys(s3, settings.restoreBucket)).length !== 0)
      throw new Error("Restore bucket must be empty");
    for (const object of manifest.objects) {
      const bytes = new Uint8Array(
        readFileSync(join(directory, "objects", object.file)),
      );
      await s3.send(
        new PutObjectCommand({
          Bucket: settings.restoreBucket,
          Key: object.key,
          Body: bytes,
          ContentLength: object.size,
          ...(object.contentType ? { ContentType: object.contentType } : {}),
          Metadata: { sha256: object.sha256 },
        }),
      );
    }
    const restoredKeys = await listKeys(s3, settings.restoreBucket);
    if (
      JSON.stringify(restoredKeys) !==
      JSON.stringify(manifest.objects.map(({ key }) => key).sort())
    )
      throw new Error("Restored object inventory mismatch");
    for (const object of manifest.objects) {
      const restored = await getObject(s3, settings.restoreBucket, object.key);
      if (
        restored.bytes.byteLength !== object.size ||
        checksum(restored.bytes) !== object.sha256
      )
        throw new Error(`Restored object checksum mismatch: ${object.key}`);
    }
    const sample = manifest.objects[0];
    if (sample) {
      const signedUrl = await getSignedUrl(
        s3,
        new GetObjectCommand({
          Bucket: settings.restoreBucket,
          Key: sample.key,
        }),
        { expiresIn: 60 },
      );
      const response = await fetch(signedUrl);
      if (!response.ok) throw new Error("Restored signed URL check failed");
      if (
        checksum(new Uint8Array(await response.arrayBuffer())) !== sample.sha256
      )
        throw new Error("Restored signed URL checksum mismatch");
    }
    return { bucket: settings.restoreBucket, objects: manifest.objects.length };
  } finally {
    s3.destroy();
  }
}

if (
  process.argv[1] &&
  resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const [command, target] = cliArguments(process.argv.slice(2));
  if (!target || !["backup", "verify", "restore"].includes(command ?? ""))
    throw new Error(
      "Usage: backup <directory> | verify <manifest> | restore <manifest>",
    );
  if (command === "backup")
    console.log(await backupStorage(readStorageSettings(process.env), target));
  if (command === "verify")
    console.log(JSON.stringify(verifyStorageBackup(target)));
  if (command === "restore") {
    const result = await restoreStorage(
      readStorageSettings(process.env, true),
      target,
    );
    console.log(
      `Storage restore rehearsal completed: ${result.objects} objects.`,
    );
  }
}
