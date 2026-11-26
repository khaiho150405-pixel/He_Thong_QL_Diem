import { Module } from "@nestjs/common";
import { StudentsService } from "./application/students.js";
import { StudentsController } from "./presentation/students.js";
import { STUDENT_REMOVAL_STORE } from "./application/port.js";
import { PrismaStudentRemovalStore } from "./infrastructure/prisma-removal.js";

@Module({
  controllers: [StudentsController],
  providers: [
    StudentsService,
    { provide: STUDENT_REMOVAL_STORE, useClass: PrismaStudentRemovalStore },
  ],
})
export class StudentsModule {}
