import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_constants.dart';
import '../models/screen_args_model.dart';
import '../services/navigation_service.dart';
import '../../auth/providers/theme_provider.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    
    return Container(
      decoration: BoxDecoration(
        color: colors.cardColor,
        border: Border(top: BorderSide(color: colors.hintColor.withOpacity(0.2))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.report,
                label: 'Reports',
                isActive: false,
                onTap: () {
                  ScreenArgsModel screenArgsModel = ScreenArgsModel(
                    routeName: AppPageRoute.reports,
                    name: "Reports",
                    data: {},
                  );
                  NavigationService.navigateTo(
                    screenArgsModel.routeName,
                    arguments: screenArgsModel,
                  );
                },
              ),
               _NavItem(
                icon: Icons.home,
                label: 'Home',
                isActive: true,
                onTap: () {
                  ScreenArgsModel screenArgsModel = ScreenArgsModel(
                    routeName: AppPageRoute.profile,
                    name: "Home",
                    data: {},
                  );
                  NavigationService.navigateTo(
                    screenArgsModel.routeName,
                    arguments: screenArgsModel,
                  );
                },
              ),
              _NavItem(
                icon: Icons.people_sharp,
                label: 'Guardians',
                isActive: false,
                onTap: () {
                  ScreenArgsModel screenArgsModel = ScreenArgsModel(
                    routeName: AppPageRoute.guardians,
                    name: "Guardians",
                    data: {},
                  );
                  NavigationService.navigateTo(
                    screenArgsModel.routeName,
                    arguments: screenArgsModel,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);
    final primaryColor = ref.watch(primaryColorProvider);
    
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? primaryColor : colors.hintColor,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? primaryColor : colors.hintColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
