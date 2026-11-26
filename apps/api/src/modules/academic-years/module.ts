import { Module } from "@nestjs/common";
import { GradebooksModule } from "../gradebooks/module.js";
import { YearsService } from "./application/years.js";
import { YearClosingService } from "./application/closing.js";
import { YEAR_CLOSING_STORE } from "./application/closing-port.js";
import { PrismaYearClosingStore } from "./infrastructure/prisma-closing.js";
import { YearsController } from "./presentation/years.js";
import { SemestersService } from "./application/semesters.js";
import { SemestersController } from "./presentation/semesters.js";

@Module({
  imports: [GradebooksModule],
  controllers: [YearsController, SemestersController],
  providers: [
    YearsService,
    SemestersService,
    YearClosingService,
    { provide: YEAR_CLOSING_STORE, useClass: PrismaYearClosingStore },
  ],
})
export class AcademicYearsModule {}
