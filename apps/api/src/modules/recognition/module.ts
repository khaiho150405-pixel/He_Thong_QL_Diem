import { Module } from "@nestjs/common";
import { RecognitionService } from "./application/service.js";
import { RECOGNITION_STORE } from "./application/port.js";
import { RecognitionBatchService } from "./application/batch-service.js";
import { RECOGNITION_BATCH_STORE } from "./application/batch-port.js";
import { PrismaRecognitionBatchStore } from "./infrastructure/prisma-batch-store.js";
import { PrismaRecognitionStore } from "./infrastructure/prisma-store.js";
import { RecognitionBatchController } from "./presentation/batch-controller.js";
import { RecognitionController } from "./presentation/controller.js";

@Module({
  controllers: [RecognitionController, RecognitionBatchController],
  providers: [
    RecognitionService,
    RecognitionBatchService,
    { provide: RECOGNITION_STORE, useClass: PrismaRecognitionStore },
    { provide: RECOGNITION_BATCH_STORE, useClass: PrismaRecognitionBatchStore },
  ],
  exports: [RecognitionService, RecognitionBatchService],
})
export class RecognitionModule {}
