import { Module } from "@nestjs/common";
import { ClassesService } from "./application/classes.js";
import { ClassesController } from "./presentation/classes.js";

@Module({ controllers: [ClassesController], providers: [ClassesService] })
export class ClassesModule {}
