import 'package:api_client_dart/src/model/account_dto.dart';
import 'package:api_client_dart/src/model/account_input.dart';
import 'package:api_client_dart/src/model/account_update.dart';
import 'package:api_client_dart/src/model/accounts_dto.dart';
import 'package:api_client_dart/src/model/assignments_dto.dart';
import 'package:api_client_dart/src/model/assignments_input.dart';
import 'package:api_client_dart/src/model/assignments_page.dart';
import 'package:api_client_dart/src/model/batch_update_input.dart';
import 'package:api_client_dart/src/model/batch_update_result_dto.dart';
import 'package:api_client_dart/src/model/cells_response_dto.dart';
import 'package:api_client_dart/src/model/classes_dto.dart';
import 'package:api_client_dart/src/model/classes_input.dart';
import 'package:api_client_dart/src/model/classes_page.dart';
import 'package:api_client_dart/src/model/components_dto.dart';
import 'package:api_client_dart/src/model/components_input.dart';
import 'package:api_client_dart/src/model/components_page.dart';
import 'package:api_client_dart/src/model/create_gradebook_input.dart';
import 'package:api_client_dart/src/model/error_dto.dart';
import 'package:api_client_dart/src/model/grade_cell_dto.dart';
import 'package:api_client_dart/src/model/grade_change_input.dart';
import 'package:api_client_dart/src/model/grade_history_dto.dart';
import 'package:api_client_dart/src/model/grade_history_entry_dto.dart';
import 'package:api_client_dart/src/model/gradebook_dto.dart';
import 'package:api_client_dart/src/model/gradebook_list_dto.dart';
import 'package:api_client_dart/src/model/health_dto.dart';
import 'package:api_client_dart/src/model/lock_input.dart';
import 'package:api_client_dart/src/model/login_input.dart';
import 'package:api_client_dart/src/model/password_input.dart';
import 'package:api_client_dart/src/model/profile_dto.dart';
import 'package:api_client_dart/src/model/semesters_dto.dart';
import 'package:api_client_dart/src/model/semesters_input.dart';
import 'package:api_client_dart/src/model/semesters_page.dart';
import 'package:api_client_dart/src/model/session_dto.dart';
import 'package:api_client_dart/src/model/students_dto.dart';
import 'package:api_client_dart/src/model/students_input.dart';
import 'package:api_client_dart/src/model/students_page.dart';
import 'package:api_client_dart/src/model/subjects_dto.dart';
import 'package:api_client_dart/src/model/subjects_input.dart';
import 'package:api_client_dart/src/model/subjects_page.dart';
import 'package:api_client_dart/src/model/teachers_dto.dart';
import 'package:api_client_dart/src/model/teachers_input.dart';
import 'package:api_client_dart/src/model/teachers_page.dart';
import 'package:api_client_dart/src/model/updated_cell_dto.dart';
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
    case 'CellsResponseDto':
      return CellsResponseDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ClassesDto':
      return ClassesDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClassesInput':
      return ClassesInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'ClassesPage':
      return ClassesPage.fromJson(value as Map<String, dynamic>) as ReturnType;
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
    case 'ErrorDto':
      return ErrorDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GradeCellDto':
      return GradeCellDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GradeChangeInput':
      return GradeChangeInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeHistoryDto':
      return GradeHistoryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradeHistoryEntryDto':
      return GradeHistoryEntryDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'GradebookDto':
      return GradebookDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'GradebookListDto':
      return GradebookListDto.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'HealthDto':
      return HealthDto.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LockInput':
      return LockInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'LoginInput':
      return LoginInput.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'PasswordInput':
      return PasswordInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'ProfileDto':
      return ProfileDto.fromJson(value as Map<String, dynamic>) as ReturnType;
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
    case 'StudentsDto':
      return StudentsDto.fromJson(value as Map<String, dynamic>) as ReturnType;
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
    case 'TeachersInput':
      return TeachersInput.fromJson(value as Map<String, dynamic>)
          as ReturnType;
    case 'TeachersPage':
      return TeachersPage.fromJson(value as Map<String, dynamic>) as ReturnType;
    case 'UpdatedCellDto':
      return UpdatedCellDto.fromJson(value as Map<String, dynamic>)
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
