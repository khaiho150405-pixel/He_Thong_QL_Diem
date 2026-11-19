import { Module } from "@nestjs/common";
import { SchoolModule } from "../school/module.js";
import { ReportsService } from "./application/service.js";
import { REPORT_STORE } from "./application/port.js";
import { PrismaReportStore } from "./infrastructure/prisma-store.js";
import {
  ReportsController,
  AdminReportsController,
} from "./presentation/controller.js";

@Module({
  imports: [SchoolModule],
  controllers: [ReportsController, AdminReportsController],
  providers: [
    ReportsService,
    { provide: REPORT_STORE, useClass: PrismaReportStore },
  ],
  exports: [ReportsService],
})
export class ReportsModule {}
