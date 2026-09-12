import { spawnSync } from "node:child_process";
import { readdir, readFile, writeFile } from "node:fs/promises";
import { repairRecognitionMultipart } from "./repair-generated-client.mjs";
const result = spawnSync(
  process.platform === "win32" ? "pnpm.cmd" : "pnpm",
  [
    "exec",
    "openapi-generator-cli",
    "generate",
    "-i",
    "docs/api/openapi.json",
    "-g",
    "dart-dio",
    "-t",
    "scripts/openapi-templates",
    "-o",
    "packages/api_client_dart",
    "--additional-properties=pubName=api_client_dart,serializationLibrary=json_serializable,hideGenerationTimestamp=true",
    "--global-property=apiTests=false,modelTests=false",
  ],
  { stdio: "inherit", shell: process.platform === "win32" },
);
process.exitCode = result.status ?? 1;
if (process.exitCode === 0) await repairRecognitionMultipart();
if (process.exitCode === 0) {
  for (const args of [
    ["pub", "get"],
    ["run", "build_runner", "build", "--delete-conflicting-outputs"],
    ["format", "lib"],
  ]) {
    const build = spawnSync(
      process.platform === "win32" ? "dart.bat" : "dart",
      args,
      {
        cwd: "packages/api_client_dart",
        stdio: "inherit",
        shell: process.platform === "win32",
      },
    );
    if (build.status !== 0) {
      process.exitCode = build.status ?? 1;
      break;
    }
  }
}
async function normalize(dir) {
  for (const entry of await readdir(dir, { withFileTypes: true })) {
    if ([".dart_tool", "build", ".openapi-generator"].includes(entry.name))
      continue;
    const file = `${dir}/${entry.name}`;
    if (entry.isDirectory()) await normalize(file);
    else if (/\.(dart|md|yaml)$/.test(file)) {
      const content = await readFile(file, "utf8");
      await writeFile(
        file,
        content
          .replaceAll("\r\n", "\n")
          .replace(/[ \t]+$/gm, "")
          .trimEnd() + "\n",
      );
    }
  }
}
if (process.exitCode === 0) {
  await normalize("packages/api_client_dart");
}
