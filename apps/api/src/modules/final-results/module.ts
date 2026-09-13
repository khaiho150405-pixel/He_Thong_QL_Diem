import { Module } from "@nestjs/common";
import { FinalResultsService } from "./application/service.js";
import { FINAL_RESULT_STORE } from "./application/port.js";
import { PrismaFinalResultStore } from "./infrastructure/prisma-store.js";
import {
  ClassificationPoliciesController,
  FinalResultsController,
  StudentResultsController,
} from "./presentation/controller.js";

@Module({
  controllers: [
    FinalResultsController,
    ClassificationPoliciesController,
    StudentResultsController,
  ],
  providers: [
    FinalResultsService,
    { provide: FINAL_RESULT_STORE, useClass: PrismaFinalResultStore },
  ],
  exports: [FinalResultsService],
})
export class FinalResultsModule {}
