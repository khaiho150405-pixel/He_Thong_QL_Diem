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
import { ErrorDto, ErrorFilter, requestContext } from "./common/http.js";
import type { AppConfig } from "./common/config.js";
import * as domainModules from "./modules/index.js";
import { DatabaseModule } from "./common/database.js";

export async function createApp(
  config: Pick<AppConfig, "origins" | "environment"> &
    Partial<Pick<AppConfig, "databaseUrl">>,
  probe: DependencyProbe,
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
      ...Object.values(domainModules),
      NotFoundModule,
    ],
    controllers: [HealthController],
    providers: [HealthService, { provide: PROBE, useValue: probe }],
  })
  class AppModule {}
  const app = await NestFactory.create(AppModule, { logger: false });
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
      if (!path.endsWith("/login"))
        operation.security = [
          { bearer: [] },
          method === "get" ? { cookie: [] } : { cookie: [], csrf: [] },
        ];
      for (const status of [400, 401, 403, 409, 429, 500])
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
