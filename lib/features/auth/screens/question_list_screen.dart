import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/question_provider.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';
import '../../../config/app_constants.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final questionsAsync = ref.watch(getQuestionsProvider);

    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Questions',
            onRefresh: () {
              ref.invalidate(getQuestionsProvider);
            },
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextFormField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search questions...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colors.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
              ),
            ),
          ),
          Expanded(
            child: questionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load questions: $error',
                    style: TextStyle(color: colors.textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (response) {
                if (!response.isSuccess) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        response.message,
                        style: TextStyle(color: colors.textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final filtered = response.data.where((q) {
                  final name = (q['name'] ?? '').toString().toLowerCase();
                  final options = (q['options'] ?? '').toString().toLowerCase();
                  final correct = (q['correct_answer'] ?? '')
                      .toString()
                      .toLowerCase();
                  final typeName =
                      ((q['question_type'] as Map?)?['name'] ?? '')
                          .toString()
                          .toLowerCase();
                  return name.contains(_searchQuery) ||
                      options.contains(_searchQuery) ||
                      correct.contains(_searchQuery) ||
                      typeName.contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No questions found.'
                            : 'No questions match your search.',
                        style: TextStyle(color: colors.textColor),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final q in filtered) {
                  final rawTypeMap = q['question_type'];
                  final typeMap = rawTypeMap is Map
                      ? Map<String, dynamic>.from(rawTypeMap)
                      : null;
                  final typeName =
                      (typeMap?['name'] ?? 'Unknown Type').toString();
                  grouped.putIfAbsent(typeName, () => []).add(q);
                }

                final entries = grouped.entries.toList()
                  ..sort((a, b) => a.key.compareTo(b.key));

                return ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: 16,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final questions = entry.value
                      ..sort(
                        (a, b) => _toInt(a['sort_order']).compareTo(
                          _toInt(b['sort_order']),
                        ),
                      );
                    return Card(
                      color: colors.cardColor,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ExpansionTile(
                        title: Text(
                          '${entry.key} (${questions.length})',
                          style: TextStyle(
                            color: colors.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: questions.map((q) {
                          final name = (q['name'] ?? '').toString();
                          final options = (q['options'] ?? '').toString();
                          final correct = (q['correct_answer'] ?? '').toString();

                          return ListTile(
                            title: Text(
                              name,
                              style: TextStyle(color: colors.textColor),
                            ),
                            subtitle: Text(
                              'Options: $options\nCorrect: $correct',
                              style: TextStyle(
                                color: colors.hintColor,
                                fontSize: 12,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.edit, color: primaryColor),
                              tooltip: 'Edit',
                              onPressed: () async {
                                final args = ScreenArgsModel(
                                  routeName: AppPageRoute.addquestion,
                                  name: 'Edit Question',
                                  data: {'id': q['id']},
                                );
                                final updated = await NavigationService
                                    .navigateTo(
                                  args.routeName,
                                  arguments: args,
                                );
                                if (updated == true) {
                                  ref.invalidate(getQuestionsProvider);
                                }
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
