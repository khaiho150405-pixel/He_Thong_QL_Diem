import "dotenv/config";
import { readConfig } from "./common/config.js";
import { InfrastructureProbe } from "./common/dependency-probe.js";
import { GradebooksService } from "./modules/gradebooks/application/service.js";
import { createApp } from "./app.js";

async function main() {
  const config = readConfig(process.env);
  const probe = new InfrastructureProbe(config);
  const app = await createApp(config, probe);
  await app.listen(config.port, "0.0.0.0");
  const gradebooks = app.get(GradebooksService);
  let closing = false;
  const closeDue = async () => {
    if (closing) return;
    closing = true;
    try {
      const columns = await gradebooks.processDue();
      if (columns > 0)
        process.stdout.write(
          JSON.stringify({ event: "grade_deadlines_processed", columns }) +
            "\n",
        );
    } catch {
      process.stderr.write(
        '{"event":"grade_deadline_failed","message":"Will retry; deadline guards remain active"}\n',
      );
    } finally {
      closing = false;
    }
  };
  await closeDue();
  const deadlineTimer = setInterval(() => void closeDue(), 30000);
  deadlineTimer.unref();
  process.stdout.write(
    JSON.stringify({ event: "api_started", port: config.port }) + "\n",
  );
  for (const signal of ["SIGINT", "SIGTERM"] as const)
    process.once(signal, () => {
      clearInterval(deadlineTimer);
      void app
        .close()
        .then(() => probe.close())
        .then(() => process.exit(0));
    });
}
main().catch(() => {
  process.stderr.write(
    '{"event":"startup_failed","message":"Check required configuration and dependencies"}\n',
  );
  process.exitCode = 1;
});
