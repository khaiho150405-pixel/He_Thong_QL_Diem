import { Module } from "@nestjs/common";
import { TimetableController } from "./presentation/controller.js";
import { TimetableService } from "./application/service.js";

@Module({
  controllers: [TimetableController],
  providers: [TimetableService],
  exports: [TimetableService],
})
export class TimetableModule {}
