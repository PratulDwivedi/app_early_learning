import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../common/models/response_message_model.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/student_provider.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/widgets/data_export_download_button.dart';
import '../models/theme_colors.dart';
import '../providers/auth_service_provider.dart';
import '../providers/theme_provider.dart';

class StudentsListScreen extends ConsumerStatefulWidget {
  const StudentsListScreen({super.key});

  @override
  ConsumerState<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends ConsumerState<StudentsListScreen> {
  int _refreshSignal = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'My Students',
            onRefresh: () {
              setState(() {
                _refreshSignal++;
              });
            },
          ),
          Expanded(child: StudentsListView(refreshSignal: _refreshSignal)),
        ],
      ),
    );
  }
}

// Reusable students list view (can be embedded in home screen)
class StudentsListView extends ConsumerStatefulWidget {
  final int refreshSignal;

  const StudentsListView({super.key, this.refreshSignal = 0});

  @override
  ConsumerState<StudentsListView> createState() => _StudentsListViewState();
}

class _StudentsListViewState extends ConsumerState<StudentsListView> {
  static const int _firstPageIndex = 1;
  static const double _nextPageTriggerOffset = 220;
  static const Duration _searchDebounceDuration = Duration(milliseconds: 450);

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  bool _isHandlingJwtExpiry = false;
  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  String _searchQuery = '';

  int _currentPageIndex = 0;
  int _totalRecords = 0;

  final List<Map<String, dynamic>> _students = <Map<String, dynamic>>[];

  bool get _hasMorePages =>
      _totalRecords > 0 && _students.length < _totalRecords;

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
        _refreshStudents();
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
      _refreshStudents();
    });
  }

  @override
  void didUpdateWidget(covariant StudentsListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _refreshStudents();
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

  bool _isJwtExpiredResponse(ResponseMessageModel response) {
    final message = response.message.toLowerCase();
    return response.statusCode == 401 ||
        message.contains('jwt expired') ||
        message.contains('token expired') ||
        message.contains('invalid jwt');
  }

  void _handleJwtExpired() {
    if (_isHandlingJwtExpiry || !mounted) return;
    _isHandlingJwtExpiry = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (!mounted) return;
      NavigationService.clearAndNavigate('login');
    });
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

  Future<void> _refreshStudents() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _currentPageIndex = 0;
      _totalRecords = 0;
      _students.clear();
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
      final params = StudentsPagingParams(
        pageIndex: pageIndex,
        searchText: _searchQuery,
      );

      final response = reset
          ? await ref.refresh(getStudentsProvider(params).future)
          : await ref.read(getStudentsProvider(params).future);

      if (!mounted) return;

      if (_isJwtExpiredResponse(response)) {
        _handleJwtExpired();
        setState(() {
          _isInitialLoading = false;
          _isLoadingMore = false;
        });
        return;
      }

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
          _students.clear();
        }

        final seenIds = _students
            .map((student) => student['id'])
            .where((id) => id != null)
            .toSet();

        for (final student in nextRecords) {
          final id = student['id'];
          if (id != null && seenIds.contains(id)) {
            continue;
          }
          _students.add(student);
          if (id != null) {
            seenIds.add(id);
          }
        }

        _currentPageIndex = paging?.pageIndex ?? pageIndex;
        _totalRecords = paging?.totalRecords ?? _students.length;
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

  Future<List<Map<String, dynamic>>> _loadStudentExportRows() async {
    final response = await ref.read(eduServiceProvider).getStudents(
          pageIndex: 0,
          searchText: _searchQuery,
        );

    if (_isJwtExpiredResponse(response)) {
      _handleJwtExpired();
      throw Exception('Session expired. Please login again.');
    }

    if (!response.isSuccess) {
      throw Exception(response.message);
    }

    return response.data
        .map((student) => Map<String, dynamic>.from(student))
        .toList();
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final isAdminUser = ref.watch(authProvider)?.data.isAdmin == true;

    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_loadError != null && _students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.error_outline,
          title: 'Error loading students',
          subtitle: _loadError,
          isError: true,
        ),
      );
    }

    if (_students.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.person_search,
          title: 'No students found',
          subtitle: _searchQuery.isEmpty
              ? 'Add your first student to get started'
              : 'No students match "$_searchQuery"',
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
            delegate: _PinnedSearchHeaderDelegate(
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
                            hintText: 'Search Kid...',
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
                            loadData: _loadStudentExportRows,
                            fileNamePrefix: 'students',
                            columns: const <ExportColumn>[
                              ExportColumn(key: 'first_name', header: 'First Name'),
                              ExportColumn(key: 'last_name', header: 'Last Name'),
                              ExportColumn(key: 'grade', header: 'Grade'),
                              ExportColumn(
                                key: 'school_name',
                                header: 'School Name',
                              ),
                              ExportColumn(key: 'full_name', header: 'Guardian Name'),
                              ExportColumn(key: 'email', header: 'Guardian Email'),
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
                  children: _students.map((student) {
                    final firstName = student['first_name'] ?? 'Unknown';
                    final lastName = student['last_name'] ?? '';
                    final grade = student['grade'] ?? '-';
                    final email = student['email'] ?? '';
                    final avatarLetter = firstName.toString().isNotEmpty
                        ? firstName.toString()[0].toUpperCase()
                        : 'S';

                    return SizedBox(
                      width: itemWidth,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            final args = ScreenArgsModel(
                              routeName: AppPageRoute.evaluation,
                              name: 'Evaluation',
                              data: student,
                            );
                            NavigationService.navigateTo(
                              args.routeName,
                              arguments: args,
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colors.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: primaryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        primaryColor.withOpacity(0.8),
                                        primaryColor,
                                      ],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      avatarLetter,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$firstName $lastName',
                                        style: TextStyle(
                                          color: colors.textColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (isAdminUser)
                                        Text(
                                          email.toString(),
                                          style: TextStyle(
                                            color: colors.hintColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.school_outlined,
                                            size: 13,
                                            color: colors.hintColor,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            'Grade: $grade',
                                            style: TextStyle(
                                              color: colors.hintColor,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () async {
                                        final args = ScreenArgsModel(
                                          routeName: AppPageRoute.addstudent,
                                          name: 'Edit Kid',
                                          data: student,
                                        );
                                        final updated =
                                            await NavigationService.navigateTo(
                                          args.routeName,
                                          arguments: args,
                                        );
                                        if (updated == true) {
                                          _refreshStudents();
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          size: 25,
                                          color: colors.hintColor,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        final screenArgsModel = ScreenArgsModel(
                                          routeName: AppPageRoute.reports,
                                          name:
                                              '$firstName $lastName - Report Card',
                                          data: student,
                                        );
                                        NavigationService.navigateTo(
                                          screenArgsModel.routeName,
                                          arguments: screenArgsModel,
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.add_chart_rounded,
                                          size: 25,
                                          color: colors.hintColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  if (!_isLoadingMore &&
                      _loadError != null &&
                      _students.isNotEmpty)
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

class _PinnedSearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _PinnedSearchHeaderDelegate({
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
  bool shouldRebuild(covariant _PinnedSearchHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
