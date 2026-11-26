import { Module } from "@nestjs/common";
import { SchoolModule } from "../school/module.js";
import { ReportsService } from "./application/service.js";
import { REPORT_STORE } from "./application/port.js";
import { PrismaReportStore } from "./infrastructure/prisma-store.js";
import { YearReportsService } from "./application/year-reports.js";
import { YEAR_REPORT_STORE } from "./application/year-port.js";
import { PrismaYearReportStore } from "./infrastructure/prisma-year-store.js";
import { YearReportsController } from "./presentation/year-controller.js";
import {
  ReportsController,
  AdminReportsController,
} from "./presentation/controller.js";

@Module({
  imports: [SchoolModule],
  controllers: [
    ReportsController,
    AdminReportsController,
    YearReportsController,
  ],
  providers: [
    ReportsService,
    { provide: REPORT_STORE, useClass: PrismaReportStore },
    YearReportsService,
    { provide: YEAR_REPORT_STORE, useClass: PrismaYearReportStore },
  ],
  exports: [ReportsService],
})
export class ReportsModule {}
