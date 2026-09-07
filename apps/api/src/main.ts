import "dotenv/config";
import { readConfig } from "./common/config.js";
import { InfrastructureProbe } from "./common/dependency-probe.js";
import { createApp } from "./app.js";

async function main() {
  const config = readConfig(process.env);
  const probe = new InfrastructureProbe(config);
  const app = await createApp(config, probe);
  await app.listen(config.port, "0.0.0.0");
  process.stdout.write(
    JSON.stringify({ event: "api_started", port: config.port }) + "\n",
  );
  for (const signal of ["SIGINT", "SIGTERM"] as const)
    process.once(signal, () => {
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
