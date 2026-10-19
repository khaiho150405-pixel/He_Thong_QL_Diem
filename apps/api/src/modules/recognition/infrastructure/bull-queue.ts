import { Queue, type ConnectionOptions } from "bullmq";
import type {
  RecognitionOutboxEvent,
  RecognitionQueue,
} from "../application/outbox.js";

export function redisConnection(redisUrl: string): ConnectionOptions {
  const url = new URL(redisUrl);
  const database = url.pathname.slice(1);
  return {
    host: url.hostname,
    port: Number(url.port || 6379),
    ...(url.username ? { username: decodeURIComponent(url.username) } : {}),
    ...(url.password ? { password: decodeURIComponent(url.password) } : {}),
    ...(database ? { db: Number(database) } : {}),
    ...(url.protocol === "rediss:" ? { tls: {} } : {}),
    maxRetriesPerRequest: null,
  };
}

export class BullRecognitionQueue implements RecognitionQueue {
  private readonly queue: Queue;

  constructor(redisUrl: string) {
    this.queue = new Queue("recognition", {
      connection: redisConnection(redisUrl),
    });
  }

  async enqueue(event: RecognitionOutboxEvent): Promise<void> {
    // Sự kiện lô nhiều trang là MỘT job cho cả lô (ADR-0016); sự kiện phiếu một ảnh giữ nguyên.
    const [name, data] = event.batchId
      ? (["recognize-batch", { batchId: event.batchId }] as const)
      : (["recognize-grade-sheet", { ticketId: event.ticketId }] as const);
    await this.queue.add(name, data, {
      jobId: event.jobId,
      attempts: 3,
      backoff: { type: "exponential", delay: 1000 },
      removeOnComplete: { age: 86_400, count: 10_000 },
      removeOnFail: { age: 604_800, count: 10_000 },
    });
  }

  close(): Promise<void> {
    return this.queue.close();
  }
}
