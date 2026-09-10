import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../authentication/session.dart';

typedef Json = Map<String, dynamic>;

class CatalogPageData {
  const CatalogPageData(this.items, this.nextCursor);
  final List<Json> items;
  final String? nextCursor;
}

final catalogRepositoryProvider = Provider(
  (ref) => CatalogRepository(ref.read(apiProvider)),
);

class CatalogRepository {
  CatalogRepository(this.api);
  final ApiClientDart api;
  Future<CatalogPageData> list(
    String resource, {
    String? cursor,
    String? q,
  }) async {
    switch (resource) {
      case 'years':
        final result = (await api.getYearsApi().yearsList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'semesters':
        final result = (await api.getSemestersApi().semestersList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'classes':
        final result = (await api.getClassesApi().classesList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'students':
        final result = (await api.getStudentsApi().studentsList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'subjects':
        final result = (await api.getSubjectsApi().subjectsList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'components':
        final result = (await api.getComponentsApi().componentsList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'teachers':
        final result = (await api.getTeachersApi().teachersList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'assignments':
        final result = (await api.getAssignmentsApi().assignmentsList(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      case 'accounts':
        final result = (await api.getIdentityApi().identityAccounts(
          q: q,
          cursor: cursor,
        )).data!;
        return CatalogPageData(
          result.items.map((row) => row.toJson()).toList(),
          result.nextCursor,
        );
      default:
        throw ArgumentError.value(resource);
    }
  }

  Future<void> save(String resource, Json input, {num? id}) async {
    switch (resource) {
      case 'years':
        final body = YearsInput.fromJson(input);
        if (id == null) {
          await api.getYearsApi().yearsCreate(yearsInput: body);
        } else {
          await api.getYearsApi().yearsUpdate(id: id, yearsInput: body);
        }
        return;
      case 'semesters':
        final body = SemestersInput.fromJson(input);
        if (id == null) {
          await api.getSemestersApi().semestersCreate(semestersInput: body);
        } else {
          await api.getSemestersApi().semestersUpdate(
            id: id,
            semestersInput: body,
          );
        }
        return;
      case 'classes':
        final body = ClassesInput.fromJson(input);
        if (id == null) {
          await api.getClassesApi().classesCreate(classesInput: body);
        } else {
          await api.getClassesApi().classesUpdate(id: id, classesInput: body);
        }
        return;
      case 'students':
        final body = StudentsInput.fromJson(input);
        if (id == null) {
          await api.getStudentsApi().studentsCreate(studentsInput: body);
        } else {
          await api.getStudentsApi().studentsUpdate(
            id: id,
            studentsInput: body,
          );
        }
        return;
      case 'subjects':
        final body = SubjectsInput.fromJson(input);
        if (id == null) {
          await api.getSubjectsApi().subjectsCreate(subjectsInput: body);
        } else {
          await api.getSubjectsApi().subjectsUpdate(
            id: id,
            subjectsInput: body,
          );
        }
        return;
      case 'components':
        final body = ComponentsInput.fromJson(input);
        if (id == null) {
          await api.getComponentsApi().componentsCreate(componentsInput: body);
        } else {
          await api.getComponentsApi().componentsUpdate(
            id: id,
            componentsInput: body,
          );
        }
        return;
      case 'teachers':
        final body = TeachersInput.fromJson(input);
        if (id == null) {
          await api.getTeachersApi().teachersCreate(teachersInput: body);
        } else {
          await api.getTeachersApi().teachersUpdate(
            id: id,
            teachersInput: body,
          );
        }
        return;
      case 'assignments':
        final body = AssignmentsInput.fromJson(input);
        if (id == null) {
          await api.getAssignmentsApi().assignmentsCreate(
            assignmentsInput: body,
          );
        } else {
          await api.getAssignmentsApi().assignmentsUpdate(
            id: id,
            assignmentsInput: body,
          );
        }
        return;
      case 'accounts':
        if (id == null) {
          await api.getIdentityApi().identityCreateAccount(
            accountInput: AccountInput.fromJson(input),
          );
        } else {
          await api.getIdentityApi().identityUpdateAccount(
            id: id,
            accountUpdate: AccountUpdate.fromJson(input),
          );
        }
        return;
      default:
        throw ArgumentError.value(resource);
    }
  }

  Future<void> remove(String resource, num id) async {
    switch (resource) {
      case 'years':
        await api.getYearsApi().yearsRemove(id: id);
        return;
      case 'semesters':
        await api.getSemestersApi().semestersRemove(id: id);
        return;
      case 'classes':
        await api.getClassesApi().classesRemove(id: id);
        return;
      case 'students':
        await api.getStudentsApi().studentsRemove(id: id);
        return;
      case 'subjects':
        await api.getSubjectsApi().subjectsRemove(id: id);
        return;
      case 'components':
        await api.getComponentsApi().componentsRemove(id: id);
        return;
      case 'teachers':
        await api.getTeachersApi().teachersRemove(id: id);
        return;
      case 'assignments':
        await api.getAssignmentsApi().assignmentsRemove(id: id);
        return;
      default:
        throw ArgumentError.value(resource);
    }
  }
}
