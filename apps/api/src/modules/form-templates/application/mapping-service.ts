import {
  BadRequestException,
  ForbiddenException,
  Inject,
  Injectable,
} from "@nestjs/common";
import {
  authenticated,
  type Actor,
} from "../../authorization/application/policy.js";
import { mapColumnsToComponents } from "../domain/definition.js";
import { templateError } from "./errors.js";
import {
  FORM_TEMPLATE_MAPPING_STORE,
  type FormTemplateMappingStore,
} from "./port.js";

function positiveInt(value: unknown): number {
  const text = typeof value === "number" ? String(value) : value;
  if (typeof text !== "string" || !/^[1-9][0-9]{0,9}$/.test(text))
    throw new BadRequestException();
  const parsed = Number(text);
  if (!Number.isSafeInteger(parsed) || parsed > 2_147_483_647)
    throw new BadRequestException();
  return parsed;
}

@Injectable()
export class FormTemplateMappingService {
  constructor(
    @Inject(FORM_TEMPLATE_MAPPING_STORE)
    private readonly store: FormTemplateMappingStore,
  ) {}

  async mapping(
    actor: Actor | undefined,
    gradebookIdInput: unknown,
    templateIdInput: unknown,
  ) {
    authenticated(actor);
    if (actor.role === "HOC_SINH") throw new ForbiddenException();
    const gradebookId = positiveInt(gradebookIdInput);
    const templateId = positiveInt(templateIdInput);
    const context = await this.store.mappingContext(
      actor,
      gradebookId,
      templateId,
    );
    if (!context) throw templateError("TEMPLATE_NOT_FOUND");
    if (context.templateStatus !== "DANG_DUNG")
      throw templateError("TEMPLATE_INACTIVE");
    const byId = new Map(context.components.map((item) => [item.id, item]));
    const items = mapColumnsToComponents(
      context.columns,
      context.components.map((item) => ({
        id: item.id,
        group: item.group,
        displayOrder: item.displayOrder,
      })),
    ).map((item) => {
      const component =
        item.componentId === null ? null : byId.get(item.componentId)!;
      return {
        templateColumnIndex: item.templateColumnIndex,
        key: item.key,
        group: item.group,
        order: item.order,
        channels:
          item.readMode === "SO_VA_CHU" ? ("SO_CHU" as const) : ("SO" as const),
        componentId: item.componentId,
        componentName: component?.name ?? null,
        locked: component?.locked ?? false,
        pending: component?.pending ?? false,
      };
    });
    return { gradebookId, templateId, items };
  }
}
