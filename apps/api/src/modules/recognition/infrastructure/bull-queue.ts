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
    await this.queue.add(
      "recognize-grade-sheet",
      { ticketId: event.ticketId },
      {
        jobId: event.jobId,
        attempts: 3,
        backoff: { type: "exponential", delay: 1000 },
        removeOnComplete: { age: 86_400, count: 10_000 },
        removeOnFail: { age: 604_800, count: 10_000 },
      },
    );
  }

  close(): Promise<void> {
    return this.queue.close();
  }
}
