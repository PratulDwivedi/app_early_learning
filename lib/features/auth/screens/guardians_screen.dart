import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../common/providers/student_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);
    final guardiansAsync = ref.watch(getGuardiansProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
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
                  return fullName.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (filteredGuardians.isEmpty && _searchQuery.isNotEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
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

                return ListView.builder(
                  itemCount: filteredGuardians.length,
                  itemBuilder: (context, index) {
                    final guardian = filteredGuardians[index];
                    final firstName = guardian.fullName.isNotEmpty
                        ? guardian.fullName.split(' ').first
                        : 'G';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
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
                                    firstName[0].toUpperCase(),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      guardian.fullName,
                                      style: TextStyle(
                                        color: colors.textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
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
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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
