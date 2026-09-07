import { readdir, readFile } from "node:fs/promises";
import path from "node:path";
async function walk(dir) {
  const out = [];
  for (const e of await readdir(dir, { withFileTypes: true })) {
    if (e.name === "generated") continue;
    const p = path.join(dir, e.name);
    out.push(
      ...(e.isDirectory() ? await walk(p) : p.endsWith(".ts") ? [p] : []),
    );
  }
  return out;
}
for (const file of await walk("apps/api/src")) {
  const normalized = file.replaceAll("\\", "/");
  const sourceModule = normalized.match(/\/modules\/([^/]+)\//)?.[1];
  for (const match of (await readFile(file, "utf8")).matchAll(
    /(?:from\s*|import\s*\()['"]([^'"]+)['"]/g,
  )) {
    const target = match[1];
    if (!target.startsWith(".")) continue;
    const resolved = path
      .resolve(path.dirname(file), target)
      .replaceAll("\\", "/");
    const targetModule = resolved.match(/\/modules\/([^/]+)\//)?.[1];
    if (
      targetModule &&
      targetModule !== sourceModule &&
      /\/(infrastructure|domain|presentation)\//.test(resolved)
    )
      throw new Error(`Private module import in ${file}: ${target}`);
  }
}
console.log("Module boundaries passed.");
