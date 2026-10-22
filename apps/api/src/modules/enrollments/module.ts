import { Module } from "@nestjs/common";
import { EnrollmentsService } from "./application/service.js";
import { ENROLLMENT_STORE } from "./application/port.js";
import { PrismaEnrollmentStore } from "./infrastructure/prisma-store.js";
import {
  ClassPromotionController,
  StudentEnrollmentsController,
} from "./presentation/controller.js";

@Module({
  controllers: [ClassPromotionController, StudentEnrollmentsController],
  providers: [
    EnrollmentsService,
    { provide: ENROLLMENT_STORE, useClass: PrismaEnrollmentStore },
  ],
  exports: [EnrollmentsService],
})
export class EnrollmentsModule {}
