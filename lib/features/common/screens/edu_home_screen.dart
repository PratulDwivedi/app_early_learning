import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/theme_provider.dart';
import '../widgets/app_sidebar_drawer.dart';
import '../widgets/gradient_header.dart';
import '../../auth/screens/students_list_screen.dart';

class EduHomeScreen extends ConsumerWidget {
  const EduHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      color: colors.bgColor,
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
                          // Students list (embedded)
                          const StudentsListView(),
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
