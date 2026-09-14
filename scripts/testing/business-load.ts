import { performance } from "node:perf_hooks";
import { resolve } from "node:path";
import { fileURLToPath } from "node:url";

export interface LoadProfile {
  baseUrl: string;
  path: string;
  authorization: string;
  durationSeconds: number;
  concurrency: number;
  requestTimeoutMs: number;
  maxP95Ms: number;
  maxErrorRate: number;
}

export interface LoadResult {
  target: string;
  durationSeconds: number;
  concurrency: number;
  requests: number;
  errors: number;
  errorRate: number;
  latencyMs: { p50: number; p95: number; p99: number; max: number };
  statuses: Record<string, number>;
  passed: boolean;
}

function required(env: NodeJS.ProcessEnv, name: string) {
  const value = env[name];
  if (!value) throw new Error(`${name} is required`);
  return value;
}

function integer(
  env: NodeJS.ProcessEnv,
  name: string,
  minimum: number,
  maximum: number,
) {
  const value = Number(required(env, name));
  if (!Number.isInteger(value) || value < minimum || value > maximum)
    throw new Error(`${name} must be an integer from ${minimum} to ${maximum}`);
  return value;
}

export function readLoadProfile(env: NodeJS.ProcessEnv): LoadProfile {
  const rawBaseUrl = required(env, "LOAD_BASE_URL");
  const parsed = new URL(rawBaseUrl);
  if (!["http:", "https:"].includes(parsed.protocol))
    throw new Error("LOAD_BASE_URL must use HTTP or HTTPS");
  if (parsed.pathname !== "/" || parsed.search || parsed.hash)
    throw new Error("LOAD_BASE_URL must contain only an origin");
  const local = ["localhost", "127.0.0.1", "::1", "[::1]"].includes(
    parsed.hostname,
  );
  if (!local && env.LOAD_ALLOW_REMOTE !== "1")
    throw new Error("Remote load tests require LOAD_ALLOW_REMOTE=1");
  if (!local && parsed.protocol !== "https:")
    throw new Error("Remote load tests require HTTPS");

  const path = required(env, "LOAD_PATH");
  const target = new URL(path, parsed.origin);
  if (
    target.origin !== parsed.origin ||
    !target.pathname.startsWith("/api/v1/") ||
    target.pathname.includes("/health/") ||
    target.pathname.startsWith("/api/v1/identity/")
  )
    throw new Error(
      "LOAD_PATH must target a business /api/v1 GET endpoint outside health and identity",
    );

  const authorization = required(env, "LOAD_AUTHORIZATION");
  if (!/^Bearer [^\s]+$/.test(authorization))
    throw new Error("LOAD_AUTHORIZATION must be a Bearer token");
  const maxErrorRate = Number(required(env, "LOAD_MAX_ERROR_RATE"));
  if (!Number.isFinite(maxErrorRate) || maxErrorRate < 0 || maxErrorRate > 1)
    throw new Error("LOAD_MAX_ERROR_RATE must be from 0 to 1");

  return {
    baseUrl: parsed.origin,
    path: `${target.pathname}${target.search}`,
    authorization,
    durationSeconds: integer(env, "LOAD_DURATION_SECONDS", 1, 900),
    concurrency: integer(env, "LOAD_CONCURRENCY", 1, 200),
    requestTimeoutMs: integer(env, "LOAD_REQUEST_TIMEOUT_MS", 100, 60_000),
    maxP95Ms: integer(env, "LOAD_MAX_P95_MS", 1, 60_000),
    maxErrorRate,
  };
}

function percentile(histogram: Uint32Array, total: number, fraction: number) {
  if (total === 0) return 0;
  const rank = Math.max(1, Math.ceil(total * fraction));
  let seen = 0;
  for (let latency = 0; latency < histogram.length; latency += 1) {
    seen += histogram[latency] ?? 0;
    if (seen >= rank) return latency;
  }
  return histogram.length - 1;
}

export async function runLoadProfile(
  profile: LoadProfile,
): Promise<LoadResult> {
  const endpoint = new URL(profile.path, profile.baseUrl);
  const histogram = new Uint32Array(profile.requestTimeoutMs + 2);
  const statuses: Record<string, number> = {};
  const deadline = performance.now() + profile.durationSeconds * 1000;
  let requests = 0;
  let errors = 0;
  let maximum = 0;

  const worker = async () => {
    while (performance.now() < deadline) {
      const started = performance.now();
      let status = "network-error";
      try {
        const response = await fetch(endpoint, {
          headers: { authorization: profile.authorization },
          signal: AbortSignal.timeout(profile.requestTimeoutMs),
        });
        await response.arrayBuffer();
        status = String(response.status);
        if (!response.ok) errors += 1;
      } catch {
        errors += 1;
      }
      const elapsed = Math.max(0, Math.ceil(performance.now() - started));
      const bucket = Math.min(elapsed, histogram.length - 1);
      histogram[bucket] = (histogram[bucket] ?? 0) + 1;
      maximum = Math.max(maximum, elapsed);
      statuses[status] = (statuses[status] ?? 0) + 1;
      requests += 1;
    }
  };

  await Promise.all(Array.from({ length: profile.concurrency }, worker));
  const errorRate = requests === 0 ? 1 : errors / requests;
  const p95 = percentile(histogram, requests, 0.95);
  return {
    target: `${endpoint.origin}${endpoint.pathname}`,
    durationSeconds: profile.durationSeconds,
    concurrency: profile.concurrency,
    requests,
    errors,
    errorRate,
    latencyMs: {
      p50: percentile(histogram, requests, 0.5),
      p95,
      p99: percentile(histogram, requests, 0.99),
      max: maximum,
    },
    statuses,
    passed: errorRate <= profile.maxErrorRate && p95 <= profile.maxP95Ms,
  };
}

if (
  process.argv[1] &&
  resolve(process.argv[1]) === fileURLToPath(import.meta.url)
) {
  const result = await runLoadProfile(readLoadProfile(process.env));
  console.log(JSON.stringify(result, null, 2));
  if (!result.passed) process.exitCode = 1;
}
