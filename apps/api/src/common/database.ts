import { Global, Module } from "@nestjs/common";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../generated/prisma/client.js";
import { PrismaStore, STORE } from "./store.js";

export const DATABASE = "DATABASE";
export const SETTINGS = Symbol("SETTINGS");
export interface Settings {
  environment: string;
  origins: string[];
  redisUrl?: string;
  s3Endpoint?: string;
  s3AccessKey?: string;
  s3SecretKey?: string;
  s3Bucket?: string;
}
@Global()
@Module({})
export class DatabaseModule {
  static configure(url: string, settings: Settings) {
    const db = new PrismaClient({
      adapter: new PrismaPg({
        connectionString: url,
        options: "-c timezone=UTC",
      }),
    });
    return {
      module: DatabaseModule,
      providers: [
        { provide: DATABASE, useValue: db },
        { provide: SETTINGS, useValue: settings },
        { provide: STORE, useClass: PrismaStore },
        {
          provide: "DB_LIFECYCLE",
          useValue: { onModuleDestroy: () => db.$disconnect() },
        },
      ],
      exports: [DATABASE, SETTINGS, STORE],
    };
  }
}
