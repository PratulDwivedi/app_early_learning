import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../../config/app_constants.dart';
import '../models/screen_args_model.dart';
import '../services/navigation_service.dart';
import '../../auth/providers/auth_service_provider.dart';
import '../../auth/providers/theme_provider.dart';
import 'custom_button.dart';

class AppSidebarDrawer extends ConsumerWidget {
  const AppSidebarDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    final colors = ref.watch(themeColorsProvider);

    return Drawer(
      child: Container(
        color: colors.bgColor,
        child: Column(
          children: [
            // Header with gradient
            Container(
              width: double.infinity,
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
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: currentUser == null
                      ? const SizedBox(
                          height: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // User Avatar
                            Builder(
                              builder: (context) {
                                final pic = currentUser.data.profilePic ?? '';
                                final profilePic = pic.isNotEmpty
                                    ? '${appConfig.storageUrl}/$pic'
                                    : '';

                                return CircleAvatar(
                                  radius: 40,
                                  backgroundColor: Colors.white,
                                  backgroundImage: profilePic.isNotEmpty
                                      ? NetworkImage(profilePic)
                                      : null,
                                  child: profilePic.isEmpty
                                      ? Text(
                                          (currentUser.fullName.isNotEmpty
                                                  ? currentUser.fullName[0]
                                                  : 'U')
                                              .toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: primaryColor,
                                          ),
                                        )
                                      : null,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // User Name
                            Text(
                              currentUser.fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // User Email
                            Text(
                              currentUser.email,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
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
                    icon: Icons.volume_up_rounded,
                    iconColor: const Color(0xFF4CAF50),
                    title: 'Speech Settings',
                    onTap: () {
                      Navigator.pop(context);
                      NavigationService.navigateTo(AppPageRoute.speechSettings);
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.password,
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Change Password',
                    onTap: () {
                      Navigator.pop(context);
                      ScreenArgsModel screenArgsModel = ScreenArgsModel(
                        routeName: AppPageRoute.changePassword,
                        name: "Change Password",
                      );

                      NavigationService.navigateTo(
                        screenArgsModel.routeName,
                        arguments: screenArgsModel,
                      );
                    },
                  ),

                  Divider(height: 32, thickness: 1, color: colors.hintColor),
                  _DrawerMenuItem(
                    icon: Icons.logout,
                    iconColor: const Color(0xFF9C27B0),
                    title: 'Logout',
                    onTap: () {
                      _showLogoutDialog(context, ref, colors, primaryColor);
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

  void _showLogoutDialog(
    BuildContext context,
    WidgetRef ref,
    var colors,
    Color primaryColor,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Logout', style: TextStyle(color: colors.textColor)),
        content: Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: colors.textColor),
        ),
        actions: [
          CustomTextButton(
            label: 'Cancel',
            onPressed: () => Navigator.pop(context),
            textColor: primaryColor,
          ),
          SizedBox(
            width: 120,
            height: 40,
            child: CustomPrimaryButton(
              label: 'Logout',
              onPressed: () async {
                Navigator.pop(context);
                Navigator.pop(context); // Close drawer
                // Perform logout
                final authService = ref.read(authServiceProvider);
                await authService.signOut();
                NavigationService.clearAndNavigate('login');
              },
              primaryColor: primaryColor,
              height: 40,
              width: 120,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DRAWER MENU ITEM ====================

class _DrawerMenuItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

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
        style: TextStyle(
          fontSize: 14,
          //fontWeight: FontWeight.w500,
          color: colors.textColor,
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
