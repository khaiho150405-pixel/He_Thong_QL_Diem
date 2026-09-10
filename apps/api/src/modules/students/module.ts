import { Module } from "@nestjs/common";
import { StudentsService } from "./application/students.js";
import { StudentsController } from "./presentation/students.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({ controllers: [StudentsController], providers: [StudentsService] })
export class StudentsModule {}
