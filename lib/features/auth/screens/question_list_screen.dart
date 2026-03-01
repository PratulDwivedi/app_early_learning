import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/question_provider.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/data_export_download_button.dart';
import '../models/theme_colors.dart';
import '../providers/theme_provider.dart';

class QuestionListScreen extends ConsumerStatefulWidget {
  const QuestionListScreen({super.key});

  @override
  ConsumerState<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends ConsumerState<QuestionListScreen> {
  int _refreshSignal = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Questions',
            onRefresh: () {
              setState(() {
                _refreshSignal++;
              });
            },
          ),
          Expanded(child: QuestionsListView(refreshSignal: _refreshSignal)),
        ],
      ),
    );
  }
}

class QuestionsListView extends ConsumerStatefulWidget {
  final int refreshSignal;

  const QuestionsListView({
    super.key,
    this.refreshSignal = 0,
  });

  @override
  ConsumerState<QuestionsListView> createState() => _QuestionsListViewState();
}

class _QuestionsListViewState extends ConsumerState<QuestionsListView> {
  static const int _firstPageIndex = 1;
  static const double _nextPageTriggerOffset = 220;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 450);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  String _searchQuery = '';

  int _currentPageIndex = 0;
  int _totalRecords = 0;

  final List<Map<String, dynamic>> _questions = <Map<String, dynamic>>[];

  bool get _hasMorePages =>
      _totalRecords > 0 && _questions.length < _totalRecords;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      final nextQuery = _searchController.text.trim();
      if (!mounted) return;
      setState(() {});
      if (nextQuery == _searchQuery) return;

      _searchDebounce?.cancel();
      _searchDebounce = Timer(_searchDebounceDuration, () {
        if (!mounted) return;
        setState(() {
          _searchQuery = nextQuery;
        });
        _refreshQuestions();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _refreshQuestions();
    });
  }

  @override
  void didUpdateWidget(covariant QuestionsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _refreshQuestions();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  bool _shouldUseMultiColumnLayout(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isTablet = mediaQuery.size.shortestSide >= 600;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    return kIsWeb || isTablet || isLandscape;
  }

  int _gridCrossAxisCount(BuildContext context) {
    if (!_shouldUseMultiColumnLayout(context)) return 1;
    final width = MediaQuery.of(context).size.width;
    if (width >= 1400) return 4;
    if (width >= 1000) return 3;
    return 2;
  }

  void _onScroll() {
    if (kIsWeb) return;
    if (!_scrollController.hasClients || _isLoadingMore || _isInitialLoading) {
      return;
    }

    final remaining = _scrollController.position.extentAfter;
    if (remaining <= _nextPageTriggerOffset && _hasMorePages) {
      _loadNextPage();
    }
  }

  Future<void> _refreshQuestions() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _currentPageIndex = 0;
      _totalRecords = 0;
      _questions.clear();
    });

    await _loadPage(pageIndex: _firstPageIndex, reset: true);
  }

  Future<void> _loadNextPage() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMorePages) return;
    final nextPage = _currentPageIndex + 1;
    await _loadPage(pageIndex: nextPage);
  }

  Future<void> _loadPage({required int pageIndex, bool reset = false}) async {
    if (!mounted) return;

    setState(() {
      if (reset) {
        _isInitialLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _loadError = null;
    });

    try {
      final params = QuestionsPagingParams(
        pageIndex: pageIndex,
        searchText: _searchQuery,
      );

      final response = reset
          ? await ref.refresh(getQuestionsProvider(params).future)
          : await ref.read(getQuestionsProvider(params).future);

      if (!mounted) return;

      if (!response.isSuccess) {
        setState(() {
          _loadError = response.message;
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

      final paging = response.paging;
      final nextRecords = response.data;

      setState(() {
        if (reset) {
          _questions.clear();
        }

        final seenIds = _questions
            .map((question) => question['id'])
            .where((id) => id != null)
            .toSet();

        for (final question in nextRecords) {
          final id = question['id'];
          if (id != null && seenIds.contains(id)) {
            continue;
          }
          _questions.add(question);
          if (id != null) {
            seenIds.add(id);
          }
        }

        _currentPageIndex = paging?.pageIndex ?? pageIndex;
        _totalRecords = paging?.totalRecords ?? _questions.length;
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuestionExportRows() async {
    final response = await ref.read(eduServiceProvider).getQuestions(
          pageIndex: 0,
          searchText: _searchQuery,
        );

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    return response.data.map((item) {
      final questionType = item['question_type'];
      final typeName =
          ((questionType is Map ? questionType['name'] : null) ?? '')
              .toString();
      return {
        'question_type': typeName,
        'name': (item['name'] ?? '').toString(),
        'options': (item['options'] ?? '').toString(),
        'correct_answer': (item['correct_answer'] ?? '').toString(),
        'hint': (item['hint'] ?? '').toString(),
        'sort_order': (item['sort_order'] ?? '').toString(),
      };
    }).toList();
  }

  String _questionTypeName(Map<String, dynamic> question) {
    final questionType = question['question_type'];
    return ((questionType is Map ? questionType['name'] : null) ??
            'Unknown Type')
        .toString();
  }

  Widget _messageCard({
    required Color iconColor,
    required ThemeColors colors,
    required IconData icon,
    required String title,
    String? subtitle,
    bool isError = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isError ? Border.all(color: Colors.red, width: 1) : null,
      ),
      child: Column(
        children: [
          Icon(icon, color: isError ? Colors.red : iconColor, size: 40),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: colors.textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(color: colors.hintColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    BuildContext context,
    Map<String, dynamic> question,
    ThemeColors colors,
    Color primaryColor,
    double itemWidth,
  ) {
    final name = (question['name'] ?? '').toString();
    final options = (question['options'] ?? '').toString();
    final correctAnswer = (question['correct_answer'] ?? '').toString();
    final questionType = _questionTypeName(question);

    return SizedBox(
      width: itemWidth,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    questionType,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: TextStyle(
                      color: colors.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Options: $options',
                    style: TextStyle(
                      color: colors.hintColor,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct: $correctAnswer',
                    style: TextStyle(
                      color: colors.hintColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.edit, color: primaryColor),
              tooltip: 'Edit',
              onPressed: () async {
                final args = ScreenArgsModel(
                  routeName: AppPageRoute.addquestion,
                  name: 'Edit Question',
                  data: {'id': question['id']},
                );
                final updated = await NavigationService.navigateTo(
                  args.routeName,
                  arguments: args,
                );
                if (updated == true) {
                  _refreshQuestions();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);

    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.error_outline,
          title: 'Error loading questions',
          subtitle: _loadError,
          isError: true,
        ),
      );
    }

    if (_questions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.quiz_outlined,
          title: 'No questions found',
          subtitle: _searchQuery.isEmpty
              ? 'No questions available.'
              : 'No questions match "$_searchQuery"',
        ),
      );
    }

    final crossAxisCount = _gridCrossAxisCount(context);
    final pagingText = 'Page: $_currentPageIndex | Total: $_totalRecords';

    return Padding(
      padding: const EdgeInsets.all(10),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedQuestionsHeaderDelegate(
              minHeight: 58,
              maxHeight: 58,
              child: Container(
                color: colors.bgColor,
                padding: const EdgeInsets.only(bottom: 8),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 44,
                        child: TextFormField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search questions...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
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
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          if (_isLoadingMore)
                            const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          if (_isLoadingMore) const SizedBox(width: 6),
                          DataExportDownloadButton(
                            loadData: _loadQuestionExportRows,
                            fileNamePrefix: 'questions',
                            columns: const <ExportColumn>[
                              ExportColumn(
                                key: 'question_type',
                                header: 'Question Type',
                              ),
                              ExportColumn(key: 'name', header: 'Question'),
                              ExportColumn(key: 'options', header: 'Options'),
                              ExportColumn(
                                key: 'correct_answer',
                                header: 'Correct Answer',
                              ),
                              ExportColumn(key: 'hint', header: 'Hint'),
                              ExportColumn(
                                key: 'sort_order',
                                header: 'Sort Order',
                              ),
                            ],
                          ),
                          Expanded(
                            child: Text(
                              pagingText,
                              style: TextStyle(
                                color: colors.hintColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 12.0;
                final itemWidth = crossAxisCount == 1
                    ? constraints.maxWidth
                    : (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
                        crossAxisCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: _questions
                      .map(
                        (question) => _buildQuestionCard(
                          context,
                          question,
                          colors,
                          primaryColor,
                          itemWidth,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  if (!_isLoadingMore && _loadError != null && _questions.isNotEmpty)
                    Text(
                      _loadError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  if (kIsWeb && _hasMorePages) ...[
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      onPressed: _isLoadingMore ? null : _loadNextPage,
                      icon: const Icon(Icons.navigate_next),
                      label: Text(_isLoadingMore ? 'Loading...' : 'Next'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedQuestionsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _PinnedQuestionsHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _PinnedQuestionsHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
