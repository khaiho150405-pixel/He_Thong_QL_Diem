import { Module } from "@nestjs/common";
import { RecognitionService } from "./application/service.js";
import { RECOGNITION_STORE } from "./application/port.js";
import { PrismaRecognitionStore } from "./infrastructure/prisma-store.js";
import { RecognitionController } from "./presentation/controller.js";

@Module({
  controllers: [RecognitionController],
  providers: [
    RecognitionService,
    { provide: RECOGNITION_STORE, useClass: PrismaRecognitionStore },
  ],
  exports: [RecognitionService],
})
export class RecognitionModule {}
