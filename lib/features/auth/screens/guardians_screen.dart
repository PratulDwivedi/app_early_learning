import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_constants.dart';
import '../../common/models/screen_args_model.dart';
import '../../common/providers/student_provider.dart';
import '../../common/services/navigation_service.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../providers/theme_provider.dart';

class GuardiansScreen extends ConsumerWidget {
  const GuardiansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Column(
        children: [
          CommonGradientHeader(
            title: 'Guardians',
            onRefresh: () {
              ref.invalidate(getGuardiansProvider);
            },
          ),
          const Expanded(
            child: GuardiansList(),
          ),
        ],
      ),
    );
  }
}

class GuardiansList extends ConsumerStatefulWidget {
  const GuardiansList({super.key});

  @override
  ConsumerState<GuardiansList> createState() => _GuardiansListState();
}

class _GuardiansListState extends ConsumerState<GuardiansList> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final guardiansAsync = ref.watch(getGuardiansProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        children: [
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search guardians...',
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
          const SizedBox(height: 8),
          Expanded(
            child: guardiansAsync.when(
              data: (guardians) {
                if (guardians.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: colors.hintColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Guardians Found',
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final filteredGuardians = guardians.where((guardian) {
                  final fullName = guardian.fullName.toLowerCase();
                  final email = guardian.email.toLowerCase();
                  final studentNames = guardian.students
                      .map(
                        (student) =>
                            '${student.firstName} ${student.lastName}'
                                .toLowerCase()
                                .trim(),
                      )
                      .join(' ');
                  return fullName.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      studentNames.contains(_searchQuery);
                }).toList();

                if (filteredGuardians.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_search,
                            size: 64,
                            color: colors.hintColor.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Guardians Match',
                            style: TextStyle(
                              fontSize: 16,
                              color: colors.hintColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.hintColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final crossAxisCount = _gridCrossAxisCount(context);
                return LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 12.0;
                    final itemWidth = crossAxisCount == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth -
                                (crossAxisCount - 1) * spacing) /
                            crossAxisCount;

                    return SingleChildScrollView(
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: filteredGuardians.map((guardian) {
                          final firstName = guardian.fullName.isNotEmpty
                              ? guardian.fullName.split(' ').first
                              : 'G';
                          final avatarLetter = firstName.isNotEmpty
                              ? firstName[0].toUpperCase()
                              : 'G';

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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                              color: colors.hintColor
                                                  .withOpacity(0.25),
                                            ),
                                            const SizedBox(height: 8),
                                            ...List.generate(
                                              guardian.students.length,
                                              (studentIndex) {
                                                final student = guardian
                                                    .students[studentIndex];
                                                final fullName =
                                                    '${student.firstName} ${student.lastName}'
                                                        .trim();
                                                final studentName =
                                                    fullName.isEmpty
                                                        ? 'Unknown Student'
                                                        : fullName;
                                                return Padding(
                                                  padding: EdgeInsets.only(
                                                    bottom: studentIndex ==
                                                            guardian.students
                                                                    .length -
                                                                1
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
                                                            color:
                                                                colors.hintColor,
                                                            fontSize: 12,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons
                                                              .add_chart_rounded,
                                                          size: 18,
                                                          color: primaryColor,
                                                        ),
                                                        tooltip: 'View report',
                                                        onPressed:
                                                            student.id > 0
                                                                ? () {
                                                                    final args =
                                                                        ScreenArgsModel(
                                                                      routeName:
                                                                          AppPageRoute
                                                                              .reports,
                                                                      name:
                                                                          '$studentName - Report Card',
                                                                      data: {
                                                                        'id': student
                                                                            .id,
                                                                        'first_name':
                                                                            student.firstName,
                                                                        'last_name':
                                                                            student.lastName,
                                                                        'grade':
                                                                            student.grade,
                                                                      },
                                                                    );
                                                                    NavigationService
                                                                        .navigateTo(
                                                                      args
                                                                          .routeName,
                                                                      arguments:
                                                                          args,
                                                                    );
                                                                  }
                                                                : null,
                                                        constraints:
                                                            const BoxConstraints
                                                                .tightFor(
                                                          width: 30,
                                                          height: 30,
                                                        ),
                                                        padding:
                                                            EdgeInsets.zero,
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
              loading: () => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
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
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red.withOpacity(0.7),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Guardians',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colors.textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(fontSize: 12, color: colors.hintColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
