import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { Worker, type Job } from "bullmq";
import { PrismaClient } from "../../generated/prisma/client.js";
import { readConfig } from "../../common/config.js";
import { makeObjectStorage } from "../files/public.js";
import { RecognitionBatchProcessor } from "./application/batch-worker.js";
import { RecognitionJobProcessor } from "./application/worker.js";
import { redisConnection } from "./infrastructure/bull-queue.js";
import {
  HttpRecognitionModel,
  HttpRecognitionV2Client,
} from "./infrastructure/http-model.js";
import { PrismaRecognitionBatchWorkerStore } from "./infrastructure/prisma-batch-worker-store.js";
import { PrismaRecognitionWorkerStore } from "./infrastructure/prisma-worker-store.js";

type RecognitionJobData = { ticketId?: string; batchId?: string };

async function main() {
  const config = readConfig(process.env);
  const database = new PrismaClient({
    adapter: new PrismaPg({
      connectionString: config.databaseUrl,
      options: "-c timezone=UTC",
    }),
  });
  const store = new PrismaRecognitionWorkerStore(database);
  const storage = makeObjectStorage(config);
  // Ràng buộc STT + họ tên mặc định BẬT (BE-24b); đặt RECOGNITION_STT_CHECK=0 để tắt (cùng giá trị với dịch vụ nhận dạng).
  const sttCheck = process.env.RECOGNITION_STT_CHECK !== "0";
  const processor = new RecognitionJobProcessor(
    store,
    storage,
    new HttpRecognitionModel(
      config.recognitionServiceUrl,
      fetch,
      config.recognitionTimeoutMs,
    ),
    { sttCheck },
  );
  // Lô nhiều trang/nhiều thành phần theo mẫu (ADR-0016): /v2/recognize dùng cùng thời gian chờ như /v1.
  const batchStore = new PrismaRecognitionBatchWorkerStore(database);
  const batchProcessor = new RecognitionBatchProcessor(
    batchStore,
    storage,
    new HttpRecognitionV2Client(
      config.recognitionServiceUrl,
      fetch,
      config.recognitionTimeoutMs,
      config.recognitionTimeoutMs,
    ),
    { sttCheck },
  );
  const worker = new Worker<RecognitionJobData>(
    "recognition",
    async (job: Job<RecognitionJobData>) => {
      const { batchId, ticketId } = job.data;
      try {
        if (batchId) await batchProcessor.process(batchId);
        else if (ticketId) await processor.process(ticketId);
        else throw new Error("INVALID_JOB");
      } catch (error) {
        const code =
          error instanceof Error ? error.message : "RECOGNITION_FAILED";
        const finalAttempt = job.attemptsMade + 1 >= (job.opts.attempts ?? 1);
        const safeCode = code.replace(/[^A-Z0-9_]/g, "_");
        if (code === "MODEL_UNAVAILABLE" || finalAttempt) {
          if (batchId) await batchStore.fail(batchId, safeCode, null);
          else if (ticketId) await store.fail(ticketId, safeCode);
        }
        throw error;
      }
    },
    { connection: redisConnection(config.redisUrl), concurrency: 2 },
  );
  process.stdout.write('{"event":"recognition_worker_started"}\n');
  const shutdown = async () => {
    await worker.close();
    await database.$disconnect();
  };
  process.once("SIGINT", shutdown);
  process.once("SIGTERM", shutdown);
}

main().catch(() => {
  process.stderr.write(
    '{"event":"recognition_worker_failed","message":"Check database, Redis, storage and recognition service configuration"}\n',
  );
  process.exitCode = 1;
});
