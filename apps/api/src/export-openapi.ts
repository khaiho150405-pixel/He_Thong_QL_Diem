import { mkdir, writeFile } from "node:fs/promises";
import { createApp, makeOpenApi } from "./app.js";
import { format } from "prettier";

const app = await createApp(
  { environment: "production", origins: [] },
  {
    check: () => {
      throw new Error("Schema export must not probe infrastructure");
    },
    close: async () => {},
  },
);
try {
  await app.init();
  await mkdir("docs/api", { recursive: true });
  await writeFile(
    "docs/api/openapi.json",
    await format(JSON.stringify(makeOpenApi(app)), { parser: "json" }),
  );
} finally {
  await app.close();
}
