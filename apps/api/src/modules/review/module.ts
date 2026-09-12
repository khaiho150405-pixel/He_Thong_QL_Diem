import { Module } from "@nestjs/common";
import { ReviewService } from "./application/service.js";
import { REVIEW_STORE } from "./application/port.js";
import { PrismaReviewStore } from "./infrastructure/prisma-store.js";
import { ReviewController } from "./presentation/controller.js";

@Module({
  controllers: [ReviewController],
  providers: [
    ReviewService,
    { provide: REVIEW_STORE, useClass: PrismaReviewStore },
  ],
})
export class ReviewModule {}
