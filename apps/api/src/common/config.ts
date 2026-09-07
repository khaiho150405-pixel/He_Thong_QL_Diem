export interface AppConfig {
  environment: "development" | "staging" | "production";
  port: number;
  origins: string[];
  databaseUrl: string;
  redisUrl: string;
  s3Endpoint: string;
  s3AccessKey: string;
  s3SecretKey: string;
  s3Bucket: string;
}

export function readConfig(env: NodeJS.ProcessEnv): AppConfig {
  const required = (key: string): string => {
    const value = env[key];
    if (!value || value.includes("REPLACE_LOCALLY"))
      throw new Error(`Invalid configuration: ${key}`);
    return value;
  };
  const environment = required("APP_ENV");
  if (!["development", "staging", "production"].includes(environment))
    throw new Error("Invalid APP_ENV");
  const port = Number(required("API_PORT"));
  if (!Number.isInteger(port) || port < 1 || port > 65535)
    throw new Error("Invalid API_PORT");
  const url = (key: string, protocols: string[]) => {
    const value = required(key);
    let parsed: URL;
    try {
      parsed = new URL(value);
    } catch {
      throw new Error(`Invalid URL: ${key}`);
    }
    if (!protocols.includes(parsed.protocol))
      throw new Error(`Invalid protocol: ${key}`);
    return value;
  };
  const databaseUrl = url("DATABASE_URL", ["postgres:", "postgresql:"]);
  if (["postgres", "app_migration"].includes(new URL(databaseUrl).username))
    throw new Error("DATABASE_URL requires a runtime role");
  const origins = required("ALLOWED_ORIGINS")
    .split(",")
    .map((s) => s.trim());
  for (const origin of origins) {
    let parsed: URL;
    try {
      parsed = new URL(origin);
    } catch {
      throw new Error("Invalid ALLOWED_ORIGINS");
    }
    if (
      !["http:", "https:"].includes(parsed.protocol) ||
      parsed.origin !== origin
    )
      throw new Error("Invalid ALLOWED_ORIGINS");
    if (environment !== "development" && parsed.protocol !== "https:")
      throw new Error("HTTPS origins required");
  }
  return {
    environment: environment as AppConfig["environment"],
    port,
    origins,
    databaseUrl,
    redisUrl: url("REDIS_URL", ["redis:", "rediss:"]),
    s3Endpoint: url("S3_ENDPOINT", ["http:", "https:"]),
    s3AccessKey: required("S3_ACCESS_KEY"),
    s3SecretKey: required("S3_SECRET_KEY"),
    s3Bucket: required("S3_BUCKET"),
  };
}
