import { Module } from "@nestjs/common";
import { StudentsService } from "./application/students.js";
import { StudentsController } from "./presentation/students.js";

@Module({ controllers: [StudentsController], providers: [StudentsService] })
export class StudentsModule {}
