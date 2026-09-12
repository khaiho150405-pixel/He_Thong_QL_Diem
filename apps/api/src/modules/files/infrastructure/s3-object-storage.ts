import {
  Inject,
  Injectable,
  ServiceUnavailableException,
} from "@nestjs/common";
import {
  DeleteObjectCommand,
  GetObjectCommand,
  PutObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { SETTINGS, type Settings } from "../../../common/database.js";
import type { ObjectStorage, StoredObject } from "../application/port.js";

@Injectable()
export class S3ObjectStorage implements ObjectStorage {
  private readonly client?: S3Client;
  private readonly bucket?: string;

  constructor(@Inject(SETTINGS) settings: Settings) {
    if (
      settings.s3Endpoint &&
      settings.s3AccessKey &&
      settings.s3SecretKey &&
      settings.s3Bucket
    ) {
      this.bucket = settings.s3Bucket;
      this.client = new S3Client({
        endpoint: settings.s3Endpoint,
        region: "us-east-1",
        forcePathStyle: true,
        credentials: {
          accessKeyId: settings.s3AccessKey,
          secretAccessKey: settings.s3SecretKey,
        },
      });
    }
  }

  async put(object: StoredObject): Promise<void> {
    if (!this.client || !this.bucket) throw new ServiceUnavailableException();
    try {
      await this.client.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: object.key,
          Body: object.bytes,
          ContentLength: object.bytes.byteLength,
          ContentType: object.contentType,
          Metadata: { sha256: object.checksum },
        }),
      );
    } catch {
      throw new ServiceUnavailableException();
    }
  }

  async get(key: string): Promise<Uint8Array> {
    if (!this.client || !this.bucket) throw new ServiceUnavailableException();
    try {
      const result = await this.client.send(
        new GetObjectCommand({ Bucket: this.bucket, Key: key }),
      );
      if (!result.Body) throw new Error("Object body missing");
      return await result.Body.transformToByteArray();
    } catch {
      throw new ServiceUnavailableException();
    }
  }

  async remove(key: string): Promise<void> {
    if (!this.client || !this.bucket) return;
    await this.client.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: key }),
    );
  }
}
