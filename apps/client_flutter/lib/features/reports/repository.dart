import 'dart:typed_data';

import 'package:api_client_dart/api_client_dart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../authentication/session.dart';

final reportsRepositoryProvider = Provider(
  (ref) => ReportsRepository(ref.read(apiProvider)),
);

class ReportsRepository {
  ReportsRepository(this.api);

  final ApiClientDart api;

  Future<GradebookSummaryDto> summary(num gradebookId) async =>
      (await api.getReportsApi().reportsSummary(
        gradebookId: gradebookId,
      )).data!;

  Future<Uint8List> export(num gradebookId) async =>
      (await api.getReportsApi().reportsExport(gradebookId: gradebookId)).data!;
}
