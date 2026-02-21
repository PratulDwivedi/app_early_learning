import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/widgets/common_gradient_header_widget.dart';
import '../../common/services/navigation_service.dart';
import '../../common/models/screen_args_model.dart';
import '../providers/theme_provider.dart';
import '../../common/providers/student_provider.dart';
import '../../../config/app_constants.dart';

class StudentsListScreen extends ConsumerWidget {
  const StudentsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonGradientHeader(
              title: 'My Students',
              onRefresh: () {
                ref.invalidate(getStudentsProvider);
              },
            ),
            const StudentsListView(),
          ],
        ),
      ),
    );
  }
}

// Reusable students list view (can be embedded in home screen)
class StudentsListView extends ConsumerStatefulWidget {
  const StudentsListView({super.key});

  @override
  ConsumerState<StudentsListView> createState() => _StudentsListViewState();
}

class _StudentsListViewState extends ConsumerState<StudentsListView> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final studentsAsync = ref.watch(getStudentsProvider);

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // search textbox with full width
          TextFormField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search students...',
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

          const SizedBox(height: 24),
          studentsAsync.when(
            loading: () => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red, width: 1),
              ),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    'Error loading students',
                    style: TextStyle(
                      color: colors.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: TextStyle(color: colors.hintColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            data: (response) {
              if (!response.isSuccess || response.data.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_search, color: primaryColor, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No Students Found',
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first student to get started',
                        style: TextStyle(color: colors.hintColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              // Filter students based on search query
              final filteredStudents = response.data.where((student) {
                final firstName = (student['first_name'] ?? '').toLowerCase();
                final lastName = (student['last_name'] ?? '').toLowerCase();
                final email = (student['email'] ?? '').toLowerCase();
                return firstName.contains(_searchQuery) ||
                    lastName.contains(_searchQuery) ||
                    email.contains(_searchQuery);
              }).toList();

              // Show no results message if search has results but all filtered out
              if (filteredStudents.isEmpty && _searchQuery.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.person_search, color: primaryColor, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'No Students Match',
                        style: TextStyle(
                          color: colors.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try a different search term',
                        style: TextStyle(color: colors.hintColor, fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final firstName = student['first_name'] ?? 'Unknown';
                      final lastName = student['last_name'] ?? '';
                      final grade = student['grade'] ?? '-';
                      final email = student['email'];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
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
                                  firstName[0],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$firstName $lastName',
                                    style: TextStyle(
                                      color: colors.textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  Text(
                                    email,
                                    style: TextStyle(
                                      color: colors.hintColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        size: 14,
                                        color: colors.hintColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Grade: $grade',
                                        style: TextStyle(
                                          color: colors.hintColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton(
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('View / Edit'),
                                    ],
                                  ),
                                  onTap: () {
                                    // TODO: Implement edit student
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.question_answer),
                                      SizedBox(width: 8),
                                      Text('Evaluate'),
                                    ],
                                  ),
                                  onTap: () {
                                    NavigationService.navigateTo(
                                      AppPageRoute.evaluation,
                                    );
                                  },
                                ),
                                PopupMenuItem(
                                  child: const Row(
                                    children: [
                                      Icon(Icons.add_chart_rounded),
                                      SizedBox(width: 8),
                                      Text('Report Card'),
                                    ],
                                  ),
                                  onTap: () {
                                    ScreenArgsModel screenArgsModel = ScreenArgsModel(
                                      routeName: AppPageRoute.reports,
                                      name: '$firstName $lastName - Report Card',
                                      data: student,
                                    );
                                    NavigationService.navigateTo(
                                      screenArgsModel.routeName,
                                      arguments: screenArgsModel,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
