import "reflect-metadata";
import {
  All,
  Controller,
  Module,
  NotFoundException,
  ValidationPipe,
  type INestApplication,
} from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import {
  ApiExcludeController,
  DocumentBuilder,
  SwaggerModule,
} from "@nestjs/swagger";
import {
  HealthController,
  HealthService,
  PROBE,
  type DependencyProbe,
} from "./common/health.js";
import {
  ErrorDto,
  ErrorFilter,
  requestContext,
  securityHeaders,
} from "./common/http.js";
import type { AppConfig } from "./common/config.js";
import * as domainModules from "./modules/index.js";
import { DatabaseModule } from "./common/database.js";
import { FilesModule } from "./modules/files/module.js";
import { FormTemplatesModule } from "./modules/form-templates/module.js";
import type { ObjectStorage } from "./modules/files/application/port.js";
import {
  HttpRecognitionV2Client,
  type RecognitionV2Client,
} from "./modules/recognition/public.js";

const DEFAULT_TRY_TIMEOUT_MS = 90_000;

/** Thời gian chờ "thử nhận dạng" đồng bộ (mặc định 90 s); đặt bằng FORM_TEMPLATE_TRY_TIMEOUT_MS, 1 s–10 phút. */
function tryTimeoutMs(env: NodeJS.ProcessEnv): number {
  const value = Number(
    env.FORM_TEMPLATE_TRY_TIMEOUT_MS ?? DEFAULT_TRY_TIMEOUT_MS,
  );
  if (!Number.isInteger(value) || value < 1_000 || value > 600_000)
    throw new Error("Invalid FORM_TEMPLATE_TRY_TIMEOUT_MS");
  return value;
}

export async function createApp(
  config: Pick<AppConfig, "origins" | "environment"> &
    Partial<
      Pick<
        AppConfig,
        | "databaseUrl"
        | "uploadRateLimitPerMinute"
        | "recognitionServiceUrl"
        | "recognitionTimeoutMs"
      >
    >,
  probe: DependencyProbe,
  overrides: {
    objectStorage?: ObjectStorage;
    recognitionV2?: RecognitionV2Client;
  } = {},
): Promise<INestApplication> {
  @ApiExcludeController()
  @Controller()
  class NotFoundController {
    @All("{*path}")
    missing(): never {
      throw new NotFoundException();
    }
  }
  @Module({ controllers: [NotFoundController] })
  class NotFoundModule {}
  @Module({
    imports: [
      DatabaseModule.configure(
        config.databaseUrl ??
          "postgresql://app_runtime@127.0.0.1:5432/unconfigured",
        config,
      ),
      FilesModule.configure(overrides.objectStorage),
      FormTemplatesModule.configure(
        overrides.recognitionV2 ??
          (config.recognitionServiceUrl
            ? new HttpRecognitionV2Client(
                config.recognitionServiceUrl,
                fetch,
                config.recognitionTimeoutMs,
                tryTimeoutMs(process.env),
              )
            : undefined),
      ),
      ...Object.values(domainModules).filter(
        (module) =>
          module !== domainModules.FilesModule &&
          module !== domainModules.FormTemplatesModule,
      ),
      NotFoundModule,
    ],
    controllers: [HealthController],
    providers: [HealthService, { provide: PROBE, useValue: probe }],
  })
  class AppModule {}
  const app = await NestFactory.create(AppModule, { logger: false });
  app.use(securityHeaders(config.environment));
  app.use(requestContext);
  app.enableCors({
    origin: config.origins,
    credentials: true,
    exposedHeaders: ["x-request-id"],
  });
  app.setGlobalPrefix("api/v1");
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );
  app.useGlobalFilters(new ErrorFilter());
  if (config.environment === "development")
    SwaggerModule.setup("api/docs", app, makeOpenApi(app));
  return app;
}
export function makeOpenApi(app: INestApplication) {
  const document = SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle("Quản lý điểm API")
      .setVersion("1.0.0")
      .addBearerAuth({ type: "http", scheme: "bearer" })
      .addCookieAuth("qld_session")
      .addApiKey({ type: "apiKey", in: "header", name: "x-csrf-token" }, "csrf")
      .build(),
    {
      extraModels: [ErrorDto],
      operationIdFactory: (controller, method) =>
        `${controller.replace(/Controller$/, "").replace(/^./, (c) => c.toLowerCase())}${method[0]?.toUpperCase()}${method.slice(1)}`,
    },
  );
  for (const [path, item] of Object.entries(document.paths)) {
    for (const method of ["get", "post", "put", "delete"] as const) {
      const operation = item?.[method];
      if (!operation || path.includes("/health/")) continue;
      const open =
        path.endsWith("/login") ||
        (method === "get" &&
          /^\/(?:api\/v1\/)?school-profile(?:\/logo)?$/.test(path));
      if (!open)
        operation.security = [
          { bearer: [] },
          method === "get" ? { cookie: [] } : { cookie: [], csrf: [] },
        ];
      for (const status of [400, 401, 403, 404, 409, 429, 500])
        operation.responses[status] = {
          description: "Error envelope",
          content: {
            "application/json": {
              schema: { $ref: "#/components/schemas/ErrorDto" },
            },
          },
        };
    }
  }
  return document;
}
