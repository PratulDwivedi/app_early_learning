import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/app_sidebar_drawer.dart';
import '../widgets/feature_grid.dart';
import '../widgets/gradient_header.dart';

class EduHomeScreen extends ConsumerWidget {
  const EduHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: Color(0xFF4CAF50), // Dark background
      child: Scaffold(
        drawer: const AppSidebarDrawer(),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              const GradientHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        const FeatureGrid(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        //bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
