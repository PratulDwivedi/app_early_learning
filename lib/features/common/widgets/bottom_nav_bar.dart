import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_constants.dart';
import '../models/screen_args_model.dart';
import '../services/navigation_service.dart';

class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111827),
        //color:  Color(0xFF4CAF50) ,
        border: Border(top: BorderSide(color: Color(0xFF1F2937))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: getPageIcon('program'),
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
                icon: getPageIcon('faq'),
                label: 'Help',
                isActive: false,
                onTap: () {
                  ScreenArgsModel screenArgsModel = ScreenArgsModel(
                    routeName: AppPageRoute.helpline,
                    name: "Help",
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

class _NavItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF6B7280),
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
