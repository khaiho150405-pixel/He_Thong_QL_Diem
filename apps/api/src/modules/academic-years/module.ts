import { Module } from "@nestjs/common";
import { YearsService } from "./application/years.js";
import { YearsController } from "./presentation/years.js";
import { SemestersService } from "./application/semesters.js";
import { SemestersController } from "./presentation/semesters.js";

// Ownership is reserved here; business endpoints are introduced with their UC tests.
@Module({
  controllers: [YearsController, SemestersController],
  providers: [YearsService, SemestersService],
})
export class AcademicYearsModule {}
