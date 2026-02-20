import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../../config/app_constants.dart';
import '../models/screen_args_model.dart';
import '../services/navigation_service.dart';
import '../../auth/providers/auth_service_provider.dart';

class AppSidebarDrawer extends ConsumerWidget {
  const AppSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);


    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: profileAsync.when(
                    loading: () => const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                    error: (err, _) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: Text(
                          'Profile Error',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    data: (response) {
                      if (!response.isSuccess) {
                        return const SizedBox(
                          height: 120,
                          child: Center(
                            child: Text(
                              'Profile Not Available',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      }

                      final profileData = response.firstOrNull ?? {};
                      final fullName =
                          profileData['full_name']?.toString() ?? 'User';
                      final email = profileData['e_mail_id']?.toString() ?? '';

                      final profilePic =
                          '${appConfig.storageUrl}/${profileData['profile_pic']?.toString()}';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Avatar
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(profilePic),
                          ),
                          const SizedBox(height: 16),
                          // User Name
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // User Email
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _DrawerMenuItem(
                    icon: getPageIcon('profile'),
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Profile',
                    onTap: () {
                      Navigator.pop(context);
                      ScreenArgsModel screenArgsModel = ScreenArgsModel(
                        routeName: AppPageRoute.profile,
                        name: "Profile",
                      );

                      NavigationService.navigateTo(
                        screenArgsModel.routeName,
                        arguments: screenArgsModel,
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: getPageIcon('helpline'),
                    iconColor: const Color(0xFFFFC107),
                    title: 'Help',
                    onTap: () {
                      Navigator.pop(context);
                      ScreenArgsModel screenArgsModel = ScreenArgsModel(
                        routeName: "webview",
                        name: "Helpline",
                        data: {"page_id": AppPageIds.helpLine},
                      );

                      NavigationService.navigateTo(
                        screenArgsModel.routeName,
                        arguments: screenArgsModel,
                      );
                    },
                  ),
                  _DrawerMenuItem(
                    icon: getPageIcon('faq'),
                    iconColor: const Color(0xFFFFA726),
                    title: 'Feedback',
                    onTap: () {
                      Navigator.pop(context);
                      ScreenArgsModel screenArgsModel = ScreenArgsModel(
                        routeName: "webview",
                        name: "Feedback",
                        data: {"page_id": AppPageIds.faqs},
                      );

                      NavigationService.navigateTo(
                        screenArgsModel.routeName,
                        arguments: screenArgsModel,
                      );
                    },
                  ),
                  const Divider(height: 32, thickness: 1),
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    iconColor: const Color(0xFF9C27B0),
                    title: 'Logout',
                    onTap: () {
                      _showLogoutDialog(context, ref);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context); // Close drawer
              // Perform logout
              final authService = ref.read(authServiceProvider);
              await authService.signOut();
              NavigationService.navigateTo(
                'login',
                arguments: {'isHome': false},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ==================== DRAWER MENU ITEM ====================

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          //fontWeight: FontWeight.w500,
          color: Color(0xFF333333),
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      horizontalTitleGap: 16,
    );
  }
}

// ==================== ALTERNATIVE: CUSTOM ANIMATED DRAWER ====================

class CustomAnimatedDrawer extends StatelessWidget {
  final Widget child;

  const CustomAnimatedDrawer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          child,
          // Custom Drawer Overlay
          const _DrawerOverlay(),
        ],
      ),
    );
  }
}

class _DrawerOverlay extends ConsumerWidget {
  const _DrawerOverlay();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(drawerStateProvider);

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      left: isOpen ? 0 : -280,
      top: 0,
      bottom: 0,
      width: 280,
      child: const AppSidebarDrawer(),
    );
  }
}

final drawerStateProvider = StateProvider<bool>((ref) => false);

// ==================== DRAWER WITH BLUR EFFECT ====================

class BlurredDrawer extends StatelessWidget {
  const BlurredDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: const AppSidebarDrawer(),
    );
  }
}
