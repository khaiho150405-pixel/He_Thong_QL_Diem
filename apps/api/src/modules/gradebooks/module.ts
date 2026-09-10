import { Module } from "@nestjs/common";
import { GradebooksService } from "./application/service.js";
import { GRADEBOOK_STORE } from "./application/port.js";
import { PrismaGradebookStore } from "./infrastructure/prisma-store.js";

// Part 1 exports the tested application service; HTTP contracts arrive in part 2.
@Module({
  providers: [
    GradebooksService,
    { provide: GRADEBOOK_STORE, useClass: PrismaGradebookStore },
  ],
  exports: [GradebooksService],
})
export class GradebooksModule {}
