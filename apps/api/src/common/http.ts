import { randomUUID } from "node:crypto";
import {
  Catch,
  HttpException,
  type ArgumentsHost,
  type ExceptionFilter,
} from "@nestjs/common";
import { ApiProperty } from "@nestjs/swagger";
import type { Request, Response, NextFunction } from "express";

export class ErrorDto {
  @ApiProperty({ type: String }) code!: string;
  @ApiProperty({ type: String }) message!: string;
  @ApiProperty({ type: Object, nullable: true }) details!: Record<
    string,
    unknown
  > | null;
  @ApiProperty({ type: String }) requestId!: string;
}
export function securityHeaders(environment: string) {
  return (_req: Request, res: Response, next: NextFunction): void => {
    res.setHeader("x-content-type-options", "nosniff");
    res.setHeader("x-frame-options", "DENY");
    res.setHeader("referrer-policy", "no-referrer");
    res.setHeader(
      "permissions-policy",
      "camera=(), geolocation=(), microphone=()",
    );
    res.setHeader("cache-control", "no-store");
    if (environment !== "development") {
      res.setHeader(
        "content-security-policy",
        "default-src 'none'; frame-ancestors 'none'; base-uri 'none'",
      );
      res.setHeader(
        "strict-transport-security",
        "max-age=31536000; includeSubDomains",
      );
    }
    next();
  };
}
export function requestContext(
  req: Request,
  res: Response,
  next: NextFunction,
): void {
  const candidate = req.header("x-request-id");
  const requestId =
    candidate && /^[a-zA-Z0-9_-]{1,64}$/.test(candidate)
      ? candidate
      : randomUUID();
  res.setHeader("x-request-id", requestId);
  const started = performance.now();
  res.on("finish", () => {
    // Deliberate allowlist: no URL query, body, cookies, auth headers or exception text.
    process.stdout.write(
      JSON.stringify({
        event: "http_request",
        requestId,
        method: req.method,
        status: res.statusCode,
        durationMs: Math.round(performance.now() - started),
      }) + "\n",
    );
  });
  next();
}
@Catch()
export class ErrorFilter implements ExceptionFilter {
  catch(error: unknown, host: ArgumentsHost): void {
    const response = host.switchToHttp().getResponse<Response>();
    const status = error instanceof HttpException ? error.getStatus() : 500;
    const codes: Record<number, string> = {
      400: "VALIDATION_ERROR",
      401: "UNAUTHENTICATED",
      403: "FORBIDDEN",
      404: "NOT_FOUND",
      409: "CONFLICT",
      413: "PAYLOAD_TOO_LARGE",
      429: "RATE_LIMITED",
      503: "DEPENDENCY_UNAVAILABLE",
    };
    response.status(status).json({
      code: codes[status] ?? "INTERNAL_ERROR",
      message:
        status >= 500
          ? "Dịch vụ tạm thời không sẵn sàng."
          : "Yêu cầu không hợp lệ.",
      details: null,
      requestId: response.getHeader("x-request-id"),
    });
  }
}
