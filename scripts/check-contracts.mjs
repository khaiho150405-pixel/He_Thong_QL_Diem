import { readdir, readFile } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { createHash } from "node:crypto";
async function snapshot(dir) {
  const entries = await readdir(dir, { withFileTypes: true });
  const files = {};
  for (const e of entries) {
    if (
      [".dart_tool", "build", ".openapi-generator", "pubspec.lock"].includes(
        e.name,
      )
    )
      continue;
    const p = `${dir}/${e.name}`;
    Object.assign(
      files,
      e.isDirectory()
        ? await snapshot(p)
        : {
            [p]: createHash("sha256")
              .update(await readFile(p))
              .digest("hex"),
          },
    );
  }
  return files;
}
const before = {
  ...(await snapshot("docs/api")),
  ...(await snapshot("packages/api_client_dart")),
};
for (const command of ["api:export", "client:generate"]) {
  const result = spawnSync(
    process.platform === "win32" ? "pnpm.cmd" : "pnpm",
    [command],
    { stdio: "inherit", shell: process.platform === "win32" },
  );
  if (result.status !== 0) process.exit(result.status ?? 1);
}
const after = {
  ...(await snapshot("docs/api")),
  ...(await snapshot("packages/api_client_dart")),
};
if (JSON.stringify(before) !== JSON.stringify(after))
  throw new Error(
    "Contract drift: regenerate and review OpenAPI/client changes",
  );
