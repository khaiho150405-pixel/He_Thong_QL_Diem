import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

export interface WebReleaseSettings {
  apiBaseUrl: string;
}

export function readWebReleaseSettings(
  env: NodeJS.ProcessEnv,
): WebReleaseSettings {
  const apiBaseUrl = env.WEB_API_BASE_URL?.trim();
  if (!apiBaseUrl) throw new Error("WEB_API_BASE_URL required");
  let url: URL;
  try {
    url = new URL(apiBaseUrl);
  } catch {
    throw new Error("WEB_API_BASE_URL must be a valid URL");
  }
  if (
    url.protocol !== "https:" ||
    url.origin !== apiBaseUrl ||
    url.username ||
    url.password ||
    url.hostname === "localhost" ||
    url.hostname.endsWith(".invalid") ||
    /^127[.]/.test(url.hostname) ||
    ["::1", "[::1]"].includes(url.hostname)
  )
    throw new Error(
      "WEB_API_BASE_URL must be a credential-free production HTTPS origin",
    );
  return { apiBaseUrl };
}

export function flutterWebReleaseArguments(settings: WebReleaseSettings) {
  return [
    "build",
    "web",
    "--release",
    "--dart-define=APP_ENV=production",
    `--dart-define=API_BASE_URL=${settings.apiBaseUrl}`,
  ];
}

export function buildWebRelease(
  settings: WebReleaseSettings,
  root = process.cwd(),
) {
  const clientDirectory = resolve(root, "apps/client_flutter");
  const result = spawnSync(
    process.env.FLUTTER_BIN || "flutter",
    flutterWebReleaseArguments(settings),
    { cwd: clientDirectory, stdio: "inherit", shell: false },
  );
  if (result.status !== 0)
    throw new Error(
      result.error?.message ?? "Flutter Web release build failed",
    );
  const entrypoint = resolve(clientDirectory, "build/web/index.html");
  if (!existsSync(entrypoint))
    throw new Error("Web artifact has no index.html");
  process.stdout.write(
    JSON.stringify({ event: "web_release_built", artifact: "build/web" }) +
      "\n",
  );
}

if (
  process.argv[1] &&
  fileURLToPath(import.meta.url) === resolve(process.argv[1])
)
  buildWebRelease(readWebReleaseSettings(process.env));
