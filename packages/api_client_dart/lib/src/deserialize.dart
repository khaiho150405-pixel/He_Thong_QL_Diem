import 'package:api_client_dart/src/model/account_dto.dart';
import 'package:api_client_dart/src/model/account_input.dart';
import 'package:api_client_dart/src/model/account_update.dart';
import 'package:api_client_dart/src/model/accounts_dto.dart';
import 'package:api_client_dart/src/model/accounts_import_input.dart';
import 'package:api_client_dart/src/model/accounts_import_result.dart';
import 'package:api_client_dart/src/model/activate_classification_policy_input.dart';
import 'package:api_client_dart/src/model/adjustment_change_input.dart';
import 'package:api_client_dart/src/model/adjustment_dto.dart';
import 'package:api_client_dart/src/model/adjustment_input.dart';
import 'package:api_client_dart/src/model/adjustment_line_dto.dart';
import 'package:api_client_dart/src/model/adjustment_list_dto.dart';
import 'package:api_client_dart/src/model/adjustment_page_dto.dart';
import 'package:api_client_dart/src/model/adjustment_person_dto.dart';
import 'package:api_client_dart/src/model/adjustment_reject_input.dart';
import 'package:api_client_dart/src/model/adjustment_version_input.dart';
import 'package:api_client_dart/src/model/admin_grade_distribution_dto.dart';
import 'package:api_client_dart/src/model/admin_grade_level_progress_dto.dart';
import 'package:api_client_dart/src/model/admin_kpi_dto.dart';
import 'package:api_client_dart/src/model/admin_ocr_accuracy_dto.dart';
import 'package:api_client_dart/src/model/admin_overview_dto.dart';
import 'package:api_client_dart/src/model/admin_recent_activity_dto.dart';
import 'package:api_client_dart/src/model/affected_gradebook_dto.dart';
import 'package:api_client_dart/src/model/analyze_result_dto.dart';
import 'package:api_client_dart/src/model/analyzed_column_dto.dart';
import 'package:api_client_dart/src/model/assignments_dto.dart';
import 'package:api_client_dart/src/model/assignments_input.dart';
import 'package:api_client_dart/src/model/assignments_page.dart';
import 'package:api_client_dart/src/model/batch_update_input.dart';
import 'package:api_client_dart/src/model/batch_update_result_dto.dart';
import 'package:api_client_dart/src/model/calculate_final_results_dto.dart';
import 'package:api_client_dart/src/model/calculate_final_results_input.dart';
import 'package:api_client_dart/src/model/calculation_history_dto.dart';
import 'package:api_client_dart/src/model/calculation_history_list_dto.dart';
import 'package:api_client_dart/src/model/cancel_batch_input.dart';
import 'package:api_client_dart/src/model/cancel_ticket_input.dart';
import 'package:api_client_dart/src/model/cells_response_dto.dart';
import 'package:api_client_dart/src/model/classes_dto.dart';
import 'package:api_client_dart/src/model/classes_input.dart';
import 'package:api_client_dart/src/model/classes_page.dart';
import 'package:api_client_dart/src/model/classification_criterion_dto.dart';
import 'package:api_client_dart/src/model/classification_policy_dto.dart';
import 'package:api_client_dart/src/model/components_dto.dart';
import 'package:api_client_dart/src/model/components_input.dart';
import 'package:api_client_dart/src/model/components_page.dart';
import 'package:api_client_dart/src/model/create_gradebook_input.dart';
import 'package:api_client_dart/src/model/create_timetable_item_input.dart';
import 'package:api_client_dart/src/model/distribution_item_dto.dart';
import 'package:api_client_dart/src/model/enrollment_dto.dart';
import 'package:api_client_dart/src/model/enrollment_list_dto.dart';
import 'package:api_client_dart/src/model/enrollment_result_dto.dart';
import 'package:api_client_dart/src/model/error_dto.dart';
import 'package:api_client_dart/src/model/exempted_student_dto.dart';
import 'package:api_client_dart/src/model/exemption_change_input.dart';
import 'package:api_client_dart/src/model/exemptions_input.dart';
import 'package:api_client_dart/src/model/exemptions_result_dto.dart';
import 'package:api_client_dart/src/model/expected_version_input.dart';
import 'package:api_client_dart/src/model/final_result_dto.dart';
import 'package:api_client_dart/src/model/final_result_list_dto.dart';
import 'package:api_client_dart/src/model/grade_cell_dto.dart';
import 'package:api_client_dart/src/model/grade_change_input.dart';
import 'package:api_client_dart/src/model/grade_deadline_input.dart';
import 'package:api_client_dart/src/model/grade_history_dto.dart';
import 'package:api_client_dart/src/model/grade_history_entry_dto.dart';
import 'package:api_client_dart/src/model/gradebook_dto.dart';
import 'package:api_client_dart/src/model/gradebook_history_dto.dart';
import 'package:api_client_dart/src/model/gradebook_history_entry_dto.dart';
import 'package:api_client_dart/src/model/gradebook_list_dto.dart';
import 'package:api_client_dart/src/model/gradebook_summary_dto.dart';
import 'package:api_client_dart/src/model/health_dto.dart';
import 'package:api_client_dart/src/model/initialize_gradebooks_result_dto.dart';
import 'package:api_client_dart/src/model/initialized_gradebook_dto.dart';
import 'package:api_client_dart/src/model/late_student_input.dart';
import 'package:api_client_dart/src/model/late_student_result_dto.dart';
import 'package:api_client_dart/src/model/lock_input.dart';
import 'package:api_client_dart/src/model/login_input.dart';
import 'package:api_client_dart/src/model/mapping_dto.dart';
import 'package:api_client_dart/src/model/mapping_item_dto.dart';
import 'package:api_client_dart/src/model/missing_component_dto.dart';
import 'package:api_client_dart/src/model/missing_student_dto.dart';
import 'package:api_client_dart/src/model/missing_students_dto.dart';
import 'package:api_client_dart/src/model/password_input.dart';
import 'package:api_client_dart/src/model/profile_dto.dart';
import 'package:api_client_dart/src/model/promotion_class_dto.dart';
import 'package:api_client_dart/src/model/promotion_input.dart';
import 'package:api_client_dart/src/model/promotion_item_input.dart';
import 'package:api_client_dart/src/model/promotion_preview_dto.dart';
import 'package:api_client_dart/src/model/promotion_preview_item_dto.dart';
import 'package:api_client_dart/src/model/promotion_result_dto.dart';
import 'package:api_client_dart/src/model/promotion_source_class_dto.dart';
import 'package:api_client_dart/src/model/promotion_target_year_dto.dart';
import 'package:api_client_dart/src/model/publish_issue_dto.dart';
import 'package:api_client_dart/src/model/publish_readiness_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_page_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_receipt_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_ticket_dto.dart';
import 'package:api_client_dart/src/model/recognition_batch_ticket_receipt_dto.dart';
import 'package:api_client_dart/src/model/recognition_evidence_row_dto.dart';
import 'package:api_client_dart/src/model/recognition_receipt_dto.dart';
import 'package:api_client_dart/src/model/recognition_ticket_detail_dto.dart';
import 'package:api_client_dart/src/model/recognition_ticket_dto.dart';
import 'package:api_client_dart/src/model/reenroll_input.dart';
import 'package:api_client_dart/src/model/review_approval_input.dart';
import 'package:api_client_dart/src/model/review_approval_result_dto.dart';
import 'package:api_client_dart/src/model/review_decision_input.dart';
import 'package:api_client_dart/src/model/semester_deadline_dto.dart';
import 'package:api_client_dart/src/model/semester_deadline_input.dart';
import 'package:api_client_dart/src/model/semester_deadlines_dto.dart';
import 'package:api_client_dart/src/model/semester_weights_dto.dart';
import 'package:api_client_dart/src/model/semester_weights_input.dart';
import 'package:api_client_dart/src/model/semester_weights_page.dart';
import 'package:api_client_dart/src/model/semesters_dto.dart';
import 'package:api_client_dart/src/model/semesters_input.dart';
import 'package:api_client_dart/src/model/semesters_page.dart';
import 'package:api_client_dart/src/model/session_dto.dart';
import 'package:api_client_dart/src/model/skipped_gradebook_dto.dart';
import 'package:api_client_dart/src/model/skipped_student_dto.dart';
import 'package:api_client_dart/src/model/student_approved_component_dto.dart';
import 'package:api_client_dart/src/model/student_result_summary_dto.dart';
import 'package:api_client_dart/src/model/student_results_dto.dart';
import 'package:api_client_dart/src/model/student_subject_result_dto.dart';
import 'package:api_client_dart/src/model/student_year_dto.dart';
import 'package:api_client_dart/src/model/students_dto.dart';
import 'package:api_client_dart/src/model/students_import_input.dart';
import 'package:api_client_dart/src/model/students_import_result.dart';
import 'package:api_client_dart/src/model/students_input.dart';
import 'package:api_client_dart/src/model/students_page.dart';
import 'package:api_client_dart/src/model/subjects_dto.dart';
import 'package:api_client_dart/src/model/subjects_input.dart';
import 'package:api_client_dart/src/model/subjects_page.dart';
import 'package:api_client_dart/src/model/teachers_dto.dart';
import 'package:api_client_dart/src/model/teachers_import_input.dart';
import 'package:api_client_dart/src/model/teachers_import_result.dart';
import 'package:api_client_dart/src/model/teachers_input.dart';
import 'package:api_client_dart/src/model/teachers_page.dart';
import 'package:api_client_dart/src/model/template_column_dto.dart';
import 'package:api_client_dart/src/model/template_detail_dto.dart';
import 'package:api_client_dart/src/model/template_page_dto.dart';
import 'package:api_client_dart/src/model/template_summary_dto.dart';
import 'package:api_client_dart/src/model/timetable_item_dto.dart';
import 'package:api_client_dart/src/model/timetable_list_dto.dart';
import 'package:api_client_dart/src/model/transfer_input.dart';
import 'package:api_client_dart/src/model/transfer_result_dto.dart';
import 'package:api_client_dart/src/model/try_grade_dto.dart';
import 'package:api_client_dart/src/model/try_result_dto.dart';
import 'package:api_client_dart/src/model/try_row_dto.dart';
import 'package:api_client_dart/src/model/updated_cell_dto.dart';
import 'package:api_client_dart/src/model/versioned_definition_input.dart';
import 'package:api_client_dart/src/model/withdraw_input.dart';
import 'package:api_client_dart/src/model/year_pending_summary_dto.dart';
import 'package:api_client_dart/src/model/years_dto.dart';
import 'package:api_client_dart/src/model/years_input.dart';
import 'package:api_client_dart/src/model/years_page.dart';

final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

ReturnType deserialize<ReturnType, BaseType>(
  dynamic value,
  String targetType, {
  bool growable = true,
}) {
  switch (targetType) {
    case 'String':
      return '$value' as ReturnType;
    case 'int':
      return (value is int ? value : int.parse('$value')) as ReturnType;
    case 'bool':
      if (value is bool) {
        return value as ReturnType;
      }
      final valueString = '$value'.toLowerCase();
      return (valueString == 'true' || valueString == '1') as ReturnType;
    case 'double':
      return (value is double ? value : double.parse('$value')) as ReturnType;
    case 'AccountDto':
      return AccountDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AccountInput':
      return AccountInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AccountUpdate':
      return AccountUpdate.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AccountsDto':
      return AccountsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AccountsImportInput':
      return AccountsImportInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AccountsImportResult':
      return AccountsImportResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ActivateClassificationPolicyInput':
      return ActivateClassificationPolicyInput.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'AdjustmentChangeInput':
      return AdjustmentChangeInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentDto':
      return AdjustmentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentInput':
      return AdjustmentInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentLineDto':
      return AdjustmentLineDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentListDto':
      return AdjustmentListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentPageDto':
      return AdjustmentPageDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentPersonDto':
      return AdjustmentPersonDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentRejectInput':
      return AdjustmentRejectInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdjustmentVersionInput':
      return AdjustmentVersionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminGradeDistributionDto':
      return AdminGradeDistributionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminGradeLevelProgressDto':
      return AdminGradeLevelProgressDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminKpiDto':
      return AdminKpiDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'AdminOcrAccuracyDto':
      return AdminOcrAccuracyDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminOverviewDto':
      return AdminOverviewDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AdminRecentActivityDto':
      return AdminRecentActivityDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AffectedGradebookDto':
      return AffectedGradebookDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AnalyzeResultDto':
      return AnalyzeResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AnalyzedColumnDto':
      return AnalyzedColumnDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssignmentsDto':
      return AssignmentsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssignmentsInput':
      return AssignmentsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'AssignmentsPage':
      return AssignmentsPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BatchUpdateInput':
      return BatchUpdateInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'BatchUpdateResultDto':
      return BatchUpdateResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CalculateFinalResultsDto':
      return CalculateFinalResultsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CalculateFinalResultsInput':
      return CalculateFinalResultsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CalculationHistoryDto':
      return CalculationHistoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CalculationHistoryListDto':
      return CalculationHistoryListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CancelBatchInput':
      return CancelBatchInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CancelTicketInput':
      return CancelTicketInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CellsResponseDto':
      return CellsResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClassesDto':
      return ClassesDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClassesInput':
      return ClassesInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClassesPage':
      return ClassesPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClassificationCriterionDto':
      return ClassificationCriterionDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClassificationPolicyDto':
      return ClassificationPolicyDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComponentsDto':
      return ComponentsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComponentsInput':
      return ComponentsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ComponentsPage':
      return ComponentsPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateGradebookInput':
      return CreateGradebookInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'CreateTimetableItemInput':
      return CreateTimetableItemInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'DistributionItemDto':
      return DistributionItemDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrollmentDto':
      return EnrollmentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrollmentListDto':
      return EnrollmentListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'EnrollmentResultDto':
      return EnrollmentResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ErrorDto':
      return ErrorDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ExemptedStudentDto':
      return ExemptedStudentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExemptionChangeInput':
      return ExemptionChangeInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExemptionsInput':
      return ExemptionsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExemptionsResultDto':
      return ExemptionsResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ExpectedVersionInput':
      return ExpectedVersionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'FinalResultDto':
      return FinalResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'FinalResultListDto':
      return FinalResultListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeCellDto':
      return GradeCellDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GradeChangeInput':
      return GradeChangeInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeDeadlineInput':
      return GradeDeadlineInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeHistoryDto':
      return GradeHistoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeHistoryEntryDto':
      return GradeHistoryEntryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradebookDto':
      return GradebookDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GradebookHistoryDto':
      return GradebookHistoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradebookHistoryEntryDto':
      return GradebookHistoryEntryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradebookListDto':
      return GradebookListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradebookSummaryDto':
      return GradebookSummaryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthDto':
      return HealthDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'InitializeGradebooksResultDto':
      return InitializeGradebooksResultDto.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'InitializedGradebookDto':
      return InitializedGradebookDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LateStudentInput':
      return LateStudentInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LateStudentResultDto':
      return LateStudentResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'LockInput':
      return LockInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LoginInput':
      return LoginInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MappingDto':
      return MappingDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'MappingItemDto':
      return MappingItemDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MissingComponentDto':
      return MissingComponentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MissingStudentDto':
      return MissingStudentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'MissingStudentsDto':
      return MissingStudentsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PasswordInput':
      return PasswordInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProfileDto':
      return ProfileDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PromotionClassDto':
      return PromotionClassDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionInput':
      return PromotionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionItemInput':
      return PromotionItemInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionPreviewDto':
      return PromotionPreviewDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionPreviewItemDto':
      return PromotionPreviewItemDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionResultDto':
      return PromotionResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionSourceClassDto':
      return PromotionSourceClassDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PromotionTargetYearDto':
      return PromotionTargetYearDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublishIssueDto':
      return PublishIssueDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'PublishReadinessDto':
      return PublishReadinessDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionBatchDto':
      return RecognitionBatchDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionBatchPageDto':
      return RecognitionBatchPageDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionBatchReceiptDto':
      return RecognitionBatchReceiptDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionBatchTicketDto':
      return RecognitionBatchTicketDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionBatchTicketReceiptDto':
      return RecognitionBatchTicketReceiptDto.fromJson(
            value as Map<String, dynamic>,
          )
          as ReturnType;
    case 'RecognitionEvidenceRowDto':
      return RecognitionEvidenceRowDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionReceiptDto':
      return RecognitionReceiptDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionTicketDetailDto':
      return RecognitionTicketDetailDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'RecognitionTicketDto':
      return RecognitionTicketDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReenrollInput':
      return ReenrollInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReviewApprovalInput':
      return ReviewApprovalInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReviewApprovalResultDto':
      return ReviewApprovalResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ReviewDecisionInput':
      return ReviewDecisionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterDeadlineDto':
      return SemesterDeadlineDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterDeadlineInput':
      return SemesterDeadlineInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterDeadlinesDto':
      return SemesterDeadlinesDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterWeightsDto':
      return SemesterWeightsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterWeightsInput':
      return SemesterWeightsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemesterWeightsPage':
      return SemesterWeightsPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemestersDto':
      return SemestersDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SemestersInput':
      return SemestersInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SemestersPage':
      return SemestersPage.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SessionDto':
      return SessionDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SkippedGradebookDto':
      return SkippedGradebookDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SkippedStudentDto':
      return SkippedStudentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentApprovedComponentDto':
      return StudentApprovedComponentDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentResultSummaryDto':
      return StudentResultSummaryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentResultsDto':
      return StudentResultsDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentSubjectResultDto':
      return StudentSubjectResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentYearDto':
      return StudentYearDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentsDto':
      return StudentsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'StudentsImportInput':
      return StudentsImportInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentsImportResult':
      return StudentsImportResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentsInput':
      return StudentsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'StudentsPage':
      return StudentsPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SubjectsDto':
      return SubjectsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'SubjectsInput':
      return SubjectsInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'SubjectsPage':
      return SubjectsPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TeachersDto':
      return TeachersDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TeachersImportInput':
      return TeachersImportInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TeachersImportResult':
      return TeachersImportResult.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TeachersInput':
      return TeachersInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TeachersPage':
      return TeachersPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TemplateColumnDto':
      return TemplateColumnDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TemplateDetailDto':
      return TemplateDetailDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TemplatePageDto':
      return TemplatePageDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TemplateSummaryDto':
      return TemplateSummaryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TimetableItemDto':
      return TimetableItemDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TimetableListDto':
      return TimetableListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TransferInput':
      return TransferInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TransferResultDto':
      return TransferResultDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TryGradeDto':
      return TryGradeDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TryResultDto':
      return TryResultDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'TryRowDto':
      return TryRowDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UpdatedCellDto':
      return UpdatedCellDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'VersionedDefinitionInput':
      return VersionedDefinitionInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'WithdrawInput':
      return WithdrawInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'YearPendingSummaryDto':
      return YearPendingSummaryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'YearsDto':
      return YearsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'YearsInput':
      return YearsInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'YearsPage':
      return YearsPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    default:
      RegExpMatch? match;

      if (value is List && (match = _regList.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toList(growable: growable)
            as ReturnType;
      }
      if (value is Set && (match = _regSet.firstMatch(targetType)) != null) {
        targetType = match![1]!; // ignore: parameter_assignments
        return value
                .map<BaseType>(
                  (dynamic v) => deserialize<BaseType, BaseType>(
                    v,
                    targetType,
                    growable: growable,
                  ),
                )
                .toSet()
            as ReturnType;
      }
      if (value is Map && (match = _regMap.firstMatch(targetType)) != null) {
        targetType = match![1]!.trim(); // ignore: parameter_assignments
        return Map<String, BaseType>.fromIterables(
              value.keys as Iterable<String>,
              value.values.map(
                (dynamic v) => deserialize<BaseType, BaseType>(
                  v,
                  targetType,
                  growable: growable,
                ),
              ),
            )
            as ReturnType;
      }
      break;
  }
  throw Exception('Cannot deserialize');
}
