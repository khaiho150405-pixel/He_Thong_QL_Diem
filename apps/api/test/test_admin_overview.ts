import "dotenv/config";
import { PrismaClient } from "../src/generated/prisma/client.js";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaReportStore } from "../src/modules/reports/infrastructure/prisma-store.js";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL required");

const pool = new PrismaPg({
  connectionString,
});
const prisma = new PrismaClient({ adapter: pool });
const store = new PrismaReportStore(prisma);

async function run() {
  const res = await store.run((tx) => tx.adminOverview());
  console.log("adminOverview result:", JSON.stringify(res, null, 2));
  await prisma.$disconnect();
}
run().catch((e) => {
  console.error(e);
  process.exit(1);
});
