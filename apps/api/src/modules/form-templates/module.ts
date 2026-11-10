import { Module, type DynamicModule } from "@nestjs/common";
import {
  UnconfiguredRecognitionV2Client,
  type RecognitionV2Client,
} from "../recognition/public.js";
import {
  FORM_TEMPLATE_MAPPING_STORE,
  FORM_TEMPLATE_RECOGNIZER,
  FORM_TEMPLATE_STORE,
} from "./application/port.js";
import { FormTemplateMappingService } from "./application/mapping-service.js";
import { FormTemplatesService } from "./application/service.js";
import { PrismaFormTemplateStore } from "./infrastructure/prisma-store.js";
import { FormTemplatesController } from "./presentation/controller.js";
import { FormTemplateMappingController } from "./presentation/mapping-controller.js";

@Module({})
export class FormTemplatesModule {
  static configure(recognizer?: RecognitionV2Client): DynamicModule {
    return {
      module: FormTemplatesModule,
      controllers: [FormTemplatesController, FormTemplateMappingController],
      providers: [
        FormTemplatesService,
        FormTemplateMappingService,
        { provide: FORM_TEMPLATE_STORE, useClass: PrismaFormTemplateStore },
        {
          provide: FORM_TEMPLATE_MAPPING_STORE,
          useExisting: FORM_TEMPLATE_STORE,
        },
        {
          provide: FORM_TEMPLATE_RECOGNIZER,
          useValue: recognizer ?? new UnconfiguredRecognitionV2Client(),
        },
      ],
      exports: [FormTemplatesService, FormTemplateMappingService],
    };
  }
}
