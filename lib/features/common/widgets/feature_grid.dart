import 'package:flutter/material.dart';
import '../../../config/app_constants.dart';
import '../models/screen_args_model.dart';
import '../services/navigation_service.dart';

class FeatureGrid extends StatelessWidget {
  const FeatureGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Program Card
        StudentCard(
          icon: getPageIcon('speaker'),
          title: 'Student 1',
          subtitle: 'Grade 1',
          gradientColors: const [Color(0xFF06B6D4), Color(0xFF2563EB)],
          onTap: () {
            ScreenArgsModel screenArgsModel = ScreenArgsModel(
              routeName: AppPageRoute.profile,
              name: "Program",
            );

            NavigationService.navigateTo(
              screenArgsModel.routeName,
              arguments: screenArgsModel,
            );
          },
        ),

        // Speakers Card
        StudentCard(
          icon: getPageIcon('speaker'),
          title: 'Student 2',
          subtitle: 'Grade 2',
          gradientColors: const [Color(0xFF9333EA), Color(0xFFEC4899)],
          onTap: () {
            ScreenArgsModel screenArgsModel = ScreenArgsModel(
              routeName: AppPageRoute.profile,
              name: "Speakers",
              data: {},
            );
            NavigationService.navigateTo(
              screenArgsModel.routeName,
              arguments: screenArgsModel,
            );
          },
        ),
      ],
    );
  }
}

class StudentCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const StudentCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 32),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
