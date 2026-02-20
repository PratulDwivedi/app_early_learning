import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/response_message_model.dart';
import '../services/edu_service.dart';
final eventServiceProvider = Provider<EduService>((ref) {
  return EduService.instance;
});

// HTML Content Provider (for a specific page)
final htmlContentProvider = FutureProvider.family<ResponseMessageModel, int>((
  ref,
  pageId,
) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getHtmlContent(pageId);
});

final summaryCountProvider = FutureProvider<ResponseMessageModel>((ref) async {
  final service = ref.watch(eventServiceProvider);
  return await service.getSummaryCount();
});

final selectedTabProvider = StateProvider<int>((ref) => 0);
