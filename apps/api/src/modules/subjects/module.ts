import { Module } from "@nestjs/common";
import { SubjectsService } from "./application/subjects.js";
import { SubjectsController } from "./presentation/subjects.js";
import { ComponentsService } from "./application/components.js";
import { ComponentsController } from "./presentation/components.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({
  controllers: [SubjectsController, ComponentsController],
  providers: [SubjectsService, ComponentsService],
})
export class SubjectsModule {}
