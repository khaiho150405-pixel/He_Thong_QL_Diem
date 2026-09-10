import { Module } from "@nestjs/common";
import { TeachersService } from "./application/teachers.js";
import { TeachersController } from "./presentation/teachers.js";
import { AssignmentsService } from "./application/assignments.js";
import { AssignmentsController } from "./presentation/assignments.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({
  controllers: [TeachersController, AssignmentsController],
  providers: [TeachersService, AssignmentsService],
})
export class TeachersModule {}
