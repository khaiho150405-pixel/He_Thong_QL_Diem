import { Module } from "@nestjs/common";
import { SchoolService } from "./application/service.js";
import { SCHOOL_STORE } from "./application/port.js";
import { PrismaSchoolStore } from "./infrastructure/prisma-store.js";
import {
  SchoolProfileAdminController,
  SchoolProfilePublicController,
} from "./presentation/controller.js";

@Module({
  controllers: [SchoolProfilePublicController, SchoolProfileAdminController],
  providers: [
    SchoolService,
    { provide: SCHOOL_STORE, useClass: PrismaSchoolStore },
  ],
  exports: [SchoolService],
})
export class SchoolModule {}
