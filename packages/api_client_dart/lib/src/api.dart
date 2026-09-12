//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

import 'package:dio/dio.dart';
import 'package:api_client_dart/src/auth/api_key_auth.dart';
import 'package:api_client_dart/src/auth/basic_auth.dart';
import 'package:api_client_dart/src/auth/bearer_auth.dart';
import 'package:api_client_dart/src/auth/oauth.dart';
import 'package:api_client_dart/src/api/assignments_api.dart';
import 'package:api_client_dart/src/api/classes_api.dart';
import 'package:api_client_dart/src/api/components_api.dart';
import 'package:api_client_dart/src/api/gradebooks_api.dart';
import 'package:api_client_dart/src/api/health_api.dart';
import 'package:api_client_dart/src/api/identity_api.dart';
import 'package:api_client_dart/src/api/recognition_api.dart';
import 'package:api_client_dart/src/api/review_api.dart';
import 'package:api_client_dart/src/api/semesters_api.dart';
import 'package:api_client_dart/src/api/students_api.dart';
import 'package:api_client_dart/src/api/subjects_api.dart';
import 'package:api_client_dart/src/api/teachers_api.dart';
import 'package:api_client_dart/src/api/years_api.dart';

class ApiClientDart {
  static const String basePath = r'http://localhost';

  final Dio dio;
  ApiClientDart({
    Dio? dio,
    String? basePathOverride,
    List<Interceptor>? interceptors,
  }) : this.dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: basePathOverride ?? basePath,
               connectTimeout: const Duration(milliseconds: 5000),
               receiveTimeout: const Duration(milliseconds: 3000),
             ),
           ) {
    if (interceptors == null) {
      this.dio.interceptors.addAll([
        OAuthInterceptor(),
        BasicAuthInterceptor(),
        BearerAuthInterceptor(),
        ApiKeyAuthInterceptor(),
      ]);
    } else {
      this.dio.interceptors.addAll(interceptors);
    }
  }

  void setOAuthToken(String name, String token) {
    if (this.dio.interceptors.any((i) => i is OAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is OAuthInterceptor)
                  as OAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBearerAuth(String name, String token) {
    if (this.dio.interceptors.any((i) => i is BearerAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BearerAuthInterceptor)
                  as BearerAuthInterceptor)
              .tokens[name] =
          token;
    }
  }

  void setBasicAuth(String name, String username, String password) {
    if (this.dio.interceptors.any((i) => i is BasicAuthInterceptor)) {
      (this.dio.interceptors.firstWhere((i) => i is BasicAuthInterceptor)
              as BasicAuthInterceptor)
          .authInfo[name] = BasicAuthInfo(
        username,
        password,
      );
    }
  }

  void setApiKey(String name, String apiKey) {
    if (this.dio.interceptors.any((i) => i is ApiKeyAuthInterceptor)) {
      (this.dio.interceptors.firstWhere(
                    (element) => element is ApiKeyAuthInterceptor,
                  )
                  as ApiKeyAuthInterceptor)
              .apiKeys[name] =
          apiKey;
    }
  }

  /// Get AssignmentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  AssignmentsApi getAssignmentsApi() {
    return AssignmentsApi(dio);
  }

  /// Get ClassesApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ClassesApi getClassesApi() {
    return ClassesApi(dio);
  }

  /// Get ComponentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ComponentsApi getComponentsApi() {
    return ComponentsApi(dio);
  }

  /// Get GradebooksApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  GradebooksApi getGradebooksApi() {
    return GradebooksApi(dio);
  }

  /// Get HealthApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  HealthApi getHealthApi() {
    return HealthApi(dio);
  }

  /// Get IdentityApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  IdentityApi getIdentityApi() {
    return IdentityApi(dio);
  }

  /// Get RecognitionApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  RecognitionApi getRecognitionApi() {
    return RecognitionApi(dio);
  }

  /// Get ReviewApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  ReviewApi getReviewApi() {
    return ReviewApi(dio);
  }

  /// Get SemestersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SemestersApi getSemestersApi() {
    return SemestersApi(dio);
  }

  /// Get StudentsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  StudentsApi getStudentsApi() {
    return StudentsApi(dio);
  }

  /// Get SubjectsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  SubjectsApi getSubjectsApi() {
    return SubjectsApi(dio);
  }

  /// Get TeachersApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  TeachersApi getTeachersApi() {
    return TeachersApi(dio);
  }

  /// Get YearsApi instance, base route and serializer can be overridden by a given but be careful,
  /// by doing that all interceptors will not be executed
  YearsApi getYearsApi() {
    return YearsApi(dio);
  }
}
