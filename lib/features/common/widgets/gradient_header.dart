import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../auth/providers/theme_provider.dart';
import 'theme_selector.dart';

class GradientHeader extends ConsumerWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final primaryColor = ref.watch(primaryColorProvider);

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
                      Text(
                        currentUser.tenantName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // 🏷 User Name
                      Text(
                        currentUser.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Add Student Button
                      ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to add student screen
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Add Student'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.9),
                          foregroundColor: primaryColor,
                        ),
                      ),
                      // Question Paper Button
                      currentUser.data.isAdmin == true
                          ? ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to question paper screen
                              },
                              icon: const Icon(Icons.description),
                              label: const Text('Question Paper'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: primaryColor,
                              ),
                            )
                          : const SizedBox(),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
