import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_constants.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/student_provider.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../models/guardian_model.dart';
import '../models/theme_colors.dart';
import '../providers/theme_provider.dart';

class GuardiansScreen extends ConsumerStatefulWidget {
  const GuardiansScreen({super.key});

  @override
  ConsumerState<GuardiansScreen> createState() => _GuardiansScreenState();
}

class _GuardiansScreenState extends ConsumerState<GuardiansScreen> {
  int _refreshSignal = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Guardians',
            onRefresh: () {
              setState(() {
                _refreshSignal++;
              });
            },
          ),
          Expanded(
            child: GuardiansList(refreshSignal: _refreshSignal),
          ),
        ],
      ),
    );
  }
}

class GuardiansList extends ConsumerStatefulWidget {
  final int refreshSignal;

  const GuardiansList({
    super.key,
    this.refreshSignal = 0,
  });

  @override
  ConsumerState<GuardiansList> createState() => _GuardiansListState();
}

class _GuardiansListState extends ConsumerState<GuardiansList> {
  static const int _firstPageIndex = 1;
  static const int _defaultPageSize = 4;
  static const double _nextPageTriggerOffset = 220;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  bool _isInitialLoading = true;
  bool _isLoadingMore = false;
  String? _loadError;
  String _searchQuery = '';

  int _currentPageIndex = 0;
  int _pageSize = 0;
  int _totalRecords = 0;

  final List<Guardian> _guardians = <Guardian>[];

  bool get _hasMorePages =>
      _totalRecords > 0 && _guardians.length < _totalRecords;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGuardians();
    });
  }

  @override
  void didUpdateWidget(covariant GuardiansList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      _refreshGuardians();
    }
  }

  @override
  void dispose() {
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
    if (!_scrollController.hasClients || _isLoadingMore || _isInitialLoading) {
      return;
    }

    final remaining = _scrollController.position.extentAfter;
    if (remaining <= _nextPageTriggerOffset && _hasMorePages) {
      _loadNextPage();
    }
  }

  Future<void> _refreshGuardians() async {
    if (!mounted) return;

    setState(() {
      _isInitialLoading = true;
      _isLoadingMore = false;
      _loadError = null;
      _currentPageIndex = 0;
      _pageSize = _defaultPageSize;
      _totalRecords = 0;
      _guardians.clear();
    });

    await _loadPage(pageIndex: _firstPageIndex, reset: true);
  }

  Future<void> _loadNextPage() async {
    if (_isInitialLoading || _isLoadingMore || !_hasMorePages) return;
    final nextPage = _currentPageIndex + 1;
    await _loadPage(pageIndex: nextPage);
  }

  Future<void> _loadPage({
    required int pageIndex,
    bool reset = false,
  }) async {
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
      final effectivePageSize = _pageSize > 0 ? _pageSize : _defaultPageSize;
      final params = GuardiansPagingParams(
        pageIndex: pageIndex,
        pageSize: effectivePageSize,
      );

      final response = reset
          ? await ref.refresh(getGuardiansProvider(params).future)
          : await ref.read(getGuardiansProvider(params).future);

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
      final nextRecords = response.data
          .map((item) => Guardian.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        if (reset) {
          _guardians.clear();
        }

        final seenEmails = _guardians.map((g) => g.email).toSet();
        for (final guardian in nextRecords) {
          if (seenEmails.contains(guardian.email)) {
            continue;
          }
          _guardians.add(guardian);
          seenEmails.add(guardian.email);
        }

        _currentPageIndex = paging?.pageIndex ?? pageIndex;
        _pageSize = paging?.pageSize ?? effectivePageSize;
        _totalRecords = paging?.totalRecords ?? _guardians.length;
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

  Widget _buildGuardianCard(
    BuildContext context,
    Guardian guardian,
    ThemeColors colors,
    Color primaryColor,
    double itemWidth,
  ) {
    final firstName =
        guardian.fullName.isNotEmpty ? guardian.fullName.split(' ').first : 'G';
    final avatarLetter = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'G';

    return SizedBox(
      width: itemWidth,
      child: Container(
        decoration: BoxDecoration(
          color: colors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: primaryColor.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
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
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guardian.fullName,
                      style: TextStyle(
                        color: colors.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guardian.email,
                      style: TextStyle(
                        color: colors.hintColor,
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (guardian.students.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colors.hintColor.withOpacity(0.25),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(guardian.students.length, (studentIndex) {
                        final student = guardian.students[studentIndex];
                        final fullName =
                            '${student.firstName} ${student.lastName}'.trim();
                        final studentName =
                            fullName.isEmpty ? 'Unknown Student' : fullName;

                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                studentIndex == guardian.students.length - 1
                                    ? 0
                                    : 4,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 14,
                                color: colors.hintColor,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$studentName • Grade ${student.grade ?? '-'}',
                                  style: TextStyle(
                                    color: colors.hintColor,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.add_chart_rounded,
                                  size: 18,
                                  color: primaryColor,
                                ),
                                tooltip: 'View report',
                                onPressed: student.id > 0
                                    ? () {
                                        final args = ScreenArgsModel(
                                          routeName: AppPageRoute.reports,
                                          name: '$studentName - Report Card',
                                          data: {
                                            'id': student.id,
                                            'first_name': student.firstName,
                                            'last_name': student.lastName,
                                            'grade': student.grade,
                                          },
                                        );
                                        NavigationService.navigateTo(
                                          args.routeName,
                                          arguments: args,
                                        );
                                      }
                                    : null,
                                constraints: const BoxConstraints.tightFor(
                                  width: 30,
                                  height: 30,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    if (_isInitialLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primaryColor),
              const SizedBox(height: 16),
              Text(
                'Loading Guardians...',
                style: TextStyle(fontSize: 14, color: colors.hintColor),
              ),
            ],
          ),
        ),
      );
    }

    if (_loadError != null && _guardians.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.error_outline,
          title: 'Error Loading Guardians',
          subtitle: _loadError,
          isError: true,
        ),
      );
    }

    if (_guardians.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(10),
        child: _messageCard(
          iconColor: primaryColor,
          colors: colors,
          icon: Icons.people_outline,
          title: 'No Guardians Found',
          subtitle: 'No guardians available for this tenant',
        ),
      );
    }

    final filteredGuardians = _guardians.where((guardian) {
      final fullName = guardian.fullName.toLowerCase();
      final email = guardian.email.toLowerCase();
      final studentNames = guardian.students
          .map(
            (student) =>
                '${student.firstName} ${student.lastName}'.toLowerCase().trim(),
          )
          .join(' ');
      return fullName.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          studentNames.contains(_searchQuery);
    }).toList();

    final crossAxisCount = _gridCrossAxisCount(context);
    final pagingText =
        'Page: $_currentPageIndex | Size: ${_pageSize > 0 ? _pageSize : '-'} | Total: $_totalRecords';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _PinnedGuardiansHeaderDelegate(
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
                            hintText: 'Search guardians...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _searchQuery.isNotEmpty
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
          if (filteredGuardians.isEmpty && _searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _messageCard(
                  iconColor: primaryColor,
                  colors: colors,
                  icon: Icons.person_search,
                  title: 'No Guardians Match',
                  subtitle: 'Try a different search term',
                ),
              ),
            )
          else
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
                    children: filteredGuardians
                        .map(
                          (guardian) => _buildGuardianCard(
                            context,
                            guardian,
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
                  if (!_isLoadingMore && _loadError != null && _guardians.isNotEmpty)
                    Text(
                      _loadError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedGuardiansHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const _PinnedGuardiansHeaderDelegate({
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
  bool shouldRebuild(covariant _PinnedGuardiansHeaderDelegate oldDelegate) {
    return minHeight != oldDelegate.minHeight ||
        maxHeight != oldDelegate.maxHeight ||
        child != oldDelegate.child;
  }
}
