import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../../generated/prisma/client.js";
import { readConfig } from "../../common/config.js";
import { RecognitionDispatcher } from "./application/outbox.js";
import { BullRecognitionQueue } from "./infrastructure/bull-queue.js";
import { PrismaRecognitionOutbox } from "./infrastructure/prisma-outbox.js";

async function main() {
  const config = readConfig(process.env);
  const database = new PrismaClient({
    adapter: new PrismaPg({
      connectionString: config.databaseUrl,
      options: "-c timezone=UTC",
    }),
  });
  const dispatcher = new RecognitionDispatcher(
    new PrismaRecognitionOutbox(database),
    new BullRecognitionQueue(config.redisUrl),
  );
  const abort = new AbortController();
  for (const signal of ["SIGINT", "SIGTERM"] as const)
    process.once(signal, () => abort.abort());
  process.stdout.write('{"event":"recognition_dispatcher_started"}\n');
  try {
    await dispatcher.run(abort.signal);
  } finally {
    await dispatcher.close();
    await database.$disconnect();
  }
}

main().catch(() => {
  process.stderr.write(
    '{"event":"recognition_dispatcher_failed","message":"Check database and Redis configuration"}\n',
  );
  process.exitCode = 1;
});
