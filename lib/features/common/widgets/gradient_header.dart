import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../providers/event_service_provider.dart';

class GradientHeader extends ConsumerWidget {
  const GradientHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(summaryCountProvider);
    final currentUser = ref.watch(authProvider);

    // Extract notification count from summary data
    int notificationCount = 0;
    if (summaryAsync.hasValue && summaryAsync.value!.isSuccess) {
      final stats = summaryAsync.value!.firstOrNull ?? {};
      notificationCount = (stats['notifications'] as int?) ?? 0;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8BC34A), // Light Green
            Color(0xFF4CAF50), // Main Green
            Color(0xFF2E7D32), // Deep Green
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
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {
                                // Navigate to notifications
                              },
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            if (notificationCount > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$notificationCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () {
                            ref.invalidate(summaryCountProvider);
                          },
                          icon: const Icon(Icons.refresh, color: Colors.white),
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
                      const SizedBox(height: 20),

                      // 🏷 User Name
                      Text(
                        currentUser.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        currentUser.email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                summaryAsync.when(
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),

                  error: (err, _) => SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        err.toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),

                  data: (response) {
                    // ❌ API returned failure
                    if (!response.isSuccess) {
                      return SizedBox(
                        height: 120,
                        child: Center(
                          child: Text(
                            response.message,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }

                    // ✅ Safe extraction
                    final stats =
                        response.firstOrNull ??
                        {'delegates': 0, 'speakers': 0, 'exhibitors': 0};

                    final eventName = stats['event_name']?.toString() ?? '';

                    return Column(
                      children: [
                        const SizedBox(height: 20),

                        // 🏷 Event Name
                        Text(
                          eventName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
