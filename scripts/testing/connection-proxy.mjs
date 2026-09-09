// Test-only fault injection. Never started by the application or deployment scripts.
import { createServer } from "node:http";

if (process.env.CONNECTION_SMOKE_TEST !== "1")
  throw new Error("CONNECTION_SMOKE_TEST=1 is required");

let failNext = true;
const server = createServer(async (request, response) => {
  response.setHeader("Access-Control-Allow-Origin", "http://localhost:8080");
  response.setHeader("Content-Type", "application/json");
  if (request.method === "GET" && request.url === "/__ready") {
    response.end('{"status":"ready"}');
    return;
  }
  if (request.method !== "GET" || request.url !== "/api/v1/health/live") {
    response.writeHead(404).end();
    return;
  }
  if (failNext) {
    failNext = false;
    response.writeHead(503).end(
      JSON.stringify({
        code: "SMOKE_TRANSIENT_FAILURE",
        message: "Test-only transient failure",
        details: null,
        requestId: "smoke-proxy",
      }),
    );
    return;
  }
  try {
    const upstream = await fetch("http://127.0.0.1:3000/api/v1/health/live", {
      signal: AbortSignal.timeout(3000),
    });
    response.writeHead(upstream.status).end(await upstream.text());
  } catch {
    response.writeHead(502).end('{"code":"SMOKE_UPSTREAM_UNAVAILABLE"}');
  }
});
server.listen(3001, "127.0.0.1", () =>
  console.log("Smoke proxy ready on 3001"),
);
for (const signal of ["SIGINT", "SIGTERM"])
  process.on(signal, () => server.close());
