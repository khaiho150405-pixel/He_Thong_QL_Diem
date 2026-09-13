import { Module } from "@nestjs/common";
import { ReportsService } from "./application/service.js";
import { REPORT_STORE } from "./application/port.js";
import { PrismaReportStore } from "./infrastructure/prisma-store.js";
import { ReportsController } from "./presentation/controller.js";

@Module({
  controllers: [ReportsController],
  providers: [
    ReportsService,
    { provide: REPORT_STORE, useClass: PrismaReportStore },
  ],
  exports: [ReportsService],
})
export class ReportsModule {}
