import { execFileSync } from "node:child_process";
import { readFileSync, existsSync } from "node:fs";
const files = execFileSync(
  "git",
  ["ls-files", "--cached", "--others", "--exclude-standard", "-z"],
  { encoding: "utf8" },
)
  .split("\0")
  .filter(Boolean);
for (const file of files) {
  if (/^\.env(?:\.|$)/.test(file) && file !== ".env.example")
    throw new Error("Secret env file included in repository");
  if (/\.(png|ico|jar|ttf)$/.test(file)) continue;
  const text = readFileSync(file, "utf8");
  if (
    /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/.test(text) ||
    /(?:ghp_|github_pat_)[a-zA-Z0-9_]{30,}/.test(text)
  )
    throw new Error(`Credential-like content in ${file}`);
}
for (const file of [
  "AGENTS.md",
  "README.md",
  "CONTRIBUTING.md",
  "docs/development/status.md",
  ".github/workflows/ci.yml",
]) {
  if (!existsSync(file)) throw new Error(`Missing ${file}`);
}
console.log("Repository baseline scan passed (not a substitute for review).");
