import "dotenv/config";
import { defineConfig } from "prisma/config";

export default defineConfig({
  schema: "database/prisma/schema.prisma",
  migrations: {
    path: "database/migrations",
    seed: "tsx database/seeds/seed.ts",
  },
  datasource: {
    url:
      process.env.MIGRATION_DATABASE_URL ??
      "postgresql://invalid:invalid@localhost:1/unconfigured",
  },
});
