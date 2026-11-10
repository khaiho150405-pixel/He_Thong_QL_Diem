import { Module } from "@nestjs/common";
import { APP_GUARD } from "@nestjs/core";
import { IdentityService } from "./application/service.js";
import { IdentityController } from "./presentation/controller.js";
import { SessionGuard } from "./guard.js";

@Module({
  controllers: [IdentityController],
  providers: [IdentityService, { provide: APP_GUARD, useClass: SessionGuard }],
  exports: [IdentityService],
})
export class IdentityModule {}
