import { Module } from "@nestjs/common";
import { AdjustmentsService } from "./application/service.js";
import { ADJUSTMENT_STORE } from "./application/port.js";
import { PrismaAdjustmentStore } from "./infrastructure/prisma-store.js";
import {
  AdjustmentsController,
  GradebookAdjustmentsController,
} from "./presentation/controller.js";

@Module({
  controllers: [GradebookAdjustmentsController, AdjustmentsController],
  providers: [
    AdjustmentsService,
    { provide: ADJUSTMENT_STORE, useClass: PrismaAdjustmentStore },
  ],
  exports: [AdjustmentsService],
})
export class AdjustmentsModule {}
