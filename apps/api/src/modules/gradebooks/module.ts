import { Module } from "@nestjs/common";
import { GradebooksService } from "./application/service.js";
import { GRADEBOOK_STORE } from "./application/port.js";
import { PrismaGradebookStore } from "./infrastructure/prisma-store.js";
import { GradebooksController } from "./presentation/controller.js";

@Module({
  controllers: [GradebooksController],
  providers: [
    GradebooksService,
    { provide: GRADEBOOK_STORE, useClass: PrismaGradebookStore },
  ],
  exports: [GradebooksService],
})
export class GradebooksModule {}
