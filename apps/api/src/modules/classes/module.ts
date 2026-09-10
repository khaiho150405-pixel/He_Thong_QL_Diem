import { Module } from "@nestjs/common";
import { ClassesService } from "./application/classes.js";
import { ClassesController } from "./presentation/classes.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({ controllers: [ClassesController], providers: [ClassesService] })
export class ClassesModule {}
