// Điểm vào công khai của module recognition cho các module khác (ranh giới: scripts/check-boundaries.mjs).
// Hiện chỉ lộ client contract v2 (ADR-0016) mà module form-templates dùng để phân tích bố cục và thử nhận dạng.
export {
  HttpRecognitionV2Client,
  RecognitionV2Error,
  UnconfiguredRecognitionV2Client,
} from "./infrastructure/http-model.js";
export type {
  AnalyzedColumn,
  GradeGroup,
  LayoutAnalysis,
  LayoutSignature,
  RecognitionV2Client,
  SuggestedRole,
  V2Grade,
  V2Layout,
  V2Result,
  V2Row,
} from "./infrastructure/http-model.js";
