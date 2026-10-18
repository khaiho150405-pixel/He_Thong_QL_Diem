import { Module, type DynamicModule } from "@nestjs/common";
import {
  UnconfiguredRecognitionV2Client,
  type RecognitionV2Client,
} from "../recognition/public.js";
import {
  FORM_TEMPLATE_RECOGNIZER,
  FORM_TEMPLATE_STORE,
} from "./application/port.js";
import { FormTemplatesService } from "./application/service.js";
import { PrismaFormTemplateStore } from "./infrastructure/prisma-store.js";
import { FormTemplatesController } from "./presentation/controller.js";

/**
 * Mẫu bảng điểm (ADR-0016). Client dịch vụ nhận dạng v2 được cấu hình ở app.ts (như FilesModule.configure) để test thay
 * bằng fake và để xuất OpenAPI không cần dịch vụ.
 */
@Module({})
export class FormTemplatesModule {
  static configure(recognizer?: RecognitionV2Client): DynamicModule {
    return {
      module: FormTemplatesModule,
      controllers: [FormTemplatesController],
      providers: [
        FormTemplatesService,
        { provide: FORM_TEMPLATE_STORE, useClass: PrismaFormTemplateStore },
        {
          provide: FORM_TEMPLATE_RECOGNIZER,
          useValue: recognizer ?? new UnconfiguredRecognitionV2Client(),
        },
      ],
      exports: [FormTemplatesService],
    };
  }
}
