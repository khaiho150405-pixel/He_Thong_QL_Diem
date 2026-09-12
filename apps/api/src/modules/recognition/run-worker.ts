import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { Worker, type Job } from "bullmq";
import { PrismaClient } from "../../generated/prisma/client.js";
import { readConfig } from "../../common/config.js";
import { makeObjectStorage } from "../files/public.js";
import { RecognitionJobProcessor } from "./application/worker.js";
import { redisConnection } from "./infrastructure/bull-queue.js";
import { HttpRecognitionModel } from "./infrastructure/http-model.js";
import { PrismaRecognitionWorkerStore } from "./infrastructure/prisma-worker-store.js";

async function main() {
  const config = readConfig(process.env);
  const database = new PrismaClient({
    adapter: new PrismaPg({
      connectionString: config.databaseUrl,
      options: "-c timezone=UTC",
    }),
  });
  const store = new PrismaRecognitionWorkerStore(database);
  const processor = new RecognitionJobProcessor(
    store,
    makeObjectStorage(config),
    new HttpRecognitionModel(config.recognitionServiceUrl),
  );
  const worker = new Worker<{ ticketId: string }>(
    "recognition",
    async (job: Job<{ ticketId: string }>) => {
      try {
        await processor.process(job.data.ticketId);
      } catch (error) {
        const code =
          error instanceof Error ? error.message : "RECOGNITION_FAILED";
        const finalAttempt = job.attemptsMade + 1 >= (job.opts.attempts ?? 1);
        if (code === "MODEL_UNAVAILABLE" || finalAttempt)
          await store.fail(job.data.ticketId, code.replace(/[^A-Z0-9_]/g, "_"));
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
