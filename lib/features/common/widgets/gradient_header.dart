import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../auth/providers/theme_provider.dart';
import '../../../config/app_constants.dart';
import '../services/navigation_service.dart';
import 'app_logo_badge.dart';
import 'theme_selector.dart';

class GradientHeader extends ConsumerWidget {
  final TextEditingController? searchController;

  const GradientHeader({
    super.key,
    this.searchController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryColor.withOpacity(0.6),
            primaryColor,
            primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated Background Orbs
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Menu Button - Opens Drawer
                    IconButton(
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                      icon: const Icon(Icons.menu, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    if (currentUser?.data.isAdmin == true) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: TextFormField(
                            controller: searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Kid...',
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
                      ),
                    ],
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () async {
                            // Refresh user data from server
                            await ref
                                .read(authProvider.notifier)
                                .refreshUserFromServer();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              builder: (context) => const ThemeSelector(),
                            );
                          },
                          icon: const Icon(
                            Icons.color_lens,
                            color: Colors.white,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                if (currentUser == null)
                  const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                else
                  Column(
                    children: [
                      AppLogoBadge(backgroundColor: colors.cardColor),
                      const SizedBox(height: 20),
                      Text(
                        currentUser.tenantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 🏷 User Name
                      Text(
                        currentUser.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      Text(
                        currentUser.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                if (currentUser != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (currentUser.data.isAdmin != true)
                        ElevatedButton.icon(
                          onPressed: () {
                            NavigationService.navigateTo(AppPageRoute.addstudent);
                          },
                          icon: const Icon(Icons.person_add),
                          label: const Text('Add Kid'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: primaryColor,
                          ),
                        ),
                      if (currentUser.data.isAdmin == true)
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                NavigationService.navigateTo(
                                  AppPageRoute.addquestion,
                                );
                              },
                              icon: const Icon(Icons.add_circle_outline),
                              label: const Text('Add Question'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                NavigationService.navigateTo(
                                  AppPageRoute.questions,
                                );
                              },
                              icon: const Icon(Icons.list_alt_rounded),
                              label: const Text('Questions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: primaryColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
