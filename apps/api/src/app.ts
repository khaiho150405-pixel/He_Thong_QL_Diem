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
import { ErrorFilter, requestContext } from "./common/http.js";
import type { AppConfig } from "./common/config.js";
import * as domainModules from "./modules/index.js";

export async function createApp(
  config: Pick<AppConfig, "origins" | "environment">,
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
  @Module({
    imports: Object.values(domainModules),
    controllers: [HealthController, NotFoundController],
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
  return SwaggerModule.createDocument(
    app,
    new DocumentBuilder()
      .setTitle("Quản lý điểm API")
      .setVersion("1.0.0")
      .build(),
    {
      operationIdFactory: (_controller, method) =>
        `health${method[0]?.toUpperCase()}${method.slice(1)}`,
    },
  );
}
