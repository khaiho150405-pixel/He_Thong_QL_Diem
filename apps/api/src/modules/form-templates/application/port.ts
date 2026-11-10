import type { Actor } from "../../authorization/application/policy.js";
import type { LayoutSignature } from "../../recognition/public.js";
import type { TemplateColumn } from "../domain/definition.js";

export type TemplateStatus = "NHAP" | "DANG_DUNG" | "NGUNG";

export interface TemplateSummary {
  id: number;
  name: string;
  description: string | null;
  status: TemplateStatus;
  revision: number;
  rootTemplateId: number | null;
  columnCount: number;
  gradeColumnCount: number;
  version: number;
  createdAt: string;
}

export interface TemplateDetail extends TemplateSummary {
  columns: TemplateColumn[];
  imageKey: string;
}

export interface TemplateForTry {
  id: number;
  signature: LayoutSignature;
  columns: TemplateColumn[];
}

export interface TemplatePage {
  items: TemplateSummary[];
  nextCursor: string | null;
}

export type SaveMode = "TAO" | "SUA" | "PHIEN_BAN";

export interface SaveTemplate {
  actor: Actor;
  mode: SaveMode;
  templateId: number | null;
  expectedVersion: number | null;
  name: string;
  description: string | null;
  columns: TemplateColumn[];
  image?: {
    signature: LayoutSignature;
    objectKey: string;
    checksum: string;
  };
}

export interface MappingComponent {
  id: number;
  name: string;
  group: string;
  displayOrder: number;
  locked: boolean;
  pending: boolean;
}

export interface MappingContext {
  gradebookId: number;
  templateId: number;
  templateStatus: TemplateStatus;
  columns: TemplateColumn[];
  components: MappingComponent[];
}

export interface FormTemplateMappingStore {
  mappingContext(
    actor: Actor,
    gradebookId: number,
    templateId: number,
  ): Promise<MappingContext | null>;
}

export interface FormTemplateStore {
  list(
    actor: Actor,
    cursor: number | null,
    status: TemplateStatus | null,
  ): Promise<TemplatePage>;
  detail(actor: Actor, id: number): Promise<TemplateDetail | null>;
  forTry(actor: Actor, id: number): Promise<TemplateForTry | null>;
  save(input: SaveTemplate): Promise<{ templateId: number }>;
  setStatus(
    actor: Actor,
    id: number,
    expectedVersion: number,
    status: "DANG_DUNG" | "NGUNG",
  ): Promise<void>;
  consumeRateLimit(
    actor: Actor,
    operation: "FORM_TEMPLATE_TRY" | "FORM_TEMPLATE_ANALYZE",
  ): Promise<boolean>;
  recordAudit(actor: Actor, action: string, target: string): Promise<void>;
}

export const FORM_TEMPLATE_STORE = Symbol("FORM_TEMPLATE_STORE");
export const FORM_TEMPLATE_MAPPING_STORE = Symbol(
  "FORM_TEMPLATE_MAPPING_STORE",
);
export const FORM_TEMPLATE_RECOGNIZER = Symbol("FORM_TEMPLATE_RECOGNIZER");
