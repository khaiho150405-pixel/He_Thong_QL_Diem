import { SemesterWeightsService } from "./application/semester-weights.js";
import { SemesterWeightsController } from "./presentation/semester-weights.js";
import { Module } from "@nestjs/common";
import { SubjectsService } from "./application/subjects.js";
import { SubjectsController } from "./presentation/subjects.js";
import { ComponentsService } from "./application/components.js";
import { ComponentsController } from "./presentation/components.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({
  controllers: [
    SemesterWeightsController,
    SubjectsController,
    ComponentsController,
  ],
  providers: [SemesterWeightsService, SubjectsService, ComponentsService],
})
export class SubjectsModule {}
