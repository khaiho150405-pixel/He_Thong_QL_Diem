import { Pool } from "pg";
import { createClient } from "redis";
import { HeadBucketCommand, S3Client } from "@aws-sdk/client-s3";
import type { DependencyProbe } from "./health.js";
import type { AppConfig } from "./config.js";

export class InfrastructureProbe implements DependencyProbe {
  private readonly pool: Pool;
  private readonly s3: S3Client;
  constructor(private readonly config: AppConfig) {
    this.pool = new Pool({
      connectionString: config.databaseUrl,
      max: 2,
      connectionTimeoutMillis: 1500,
      query_timeout: 1500,
    });
    this.pool.on("error", () => {
      /* Request checks report sanitized readiness failures. */
    });
    this.s3 = new S3Client({
      endpoint: config.s3Endpoint,
      region: "us-east-1",
      forcePathStyle: true,
      maxAttempts: 1,
      credentials: {
        accessKeyId: config.s3AccessKey,
        secretAccessKey: config.s3SecretKey,
      },
    });
  }
  async check(): Promise<boolean> {
    const redis = createClient({
      url: this.config.redisUrl,
      socket: { connectTimeout: 1500, reconnectStrategy: false },
    });
    redis.on("error", () => {});
    const redisCheck = async () => {
      const timer = setTimeout(() => {
        if (redis.isOpen) redis.destroy();
      }, 2000);
      try {
        await redis.connect();
        await redis.ping();
      } finally {
        clearTimeout(timer);
        if (redis.isOpen) redis.destroy();
      }
    };
    const results = await Promise.allSettled([
      this.pool.query("SELECT 1"),
      redisCheck(),
      this.s3.send(new HeadBucketCommand({ Bucket: this.config.s3Bucket }), {
        abortSignal: AbortSignal.timeout(2000),
      }),
    ]);
    return results.every((result) => result.status === "fulfilled");
  }
  async close(): Promise<void> {
    this.s3.destroy();
    await this.pool.end();
  }
}
