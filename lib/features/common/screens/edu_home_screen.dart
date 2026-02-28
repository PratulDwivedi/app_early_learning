import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/theme_provider.dart';
import '../widgets/app_sidebar_drawer.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/gradient_header.dart';
import '../../auth/screens/students_list_screen.dart';

class EduHomeScreen extends ConsumerStatefulWidget {
  const EduHomeScreen({super.key});

  @override
  ConsumerState<EduHomeScreen> createState() => _EduHomeScreenState();
}

class _EduHomeScreenState extends ConsumerState<EduHomeScreen> {
  int _refreshSignal = 0;

  @override
  Widget build(BuildContext context) {
    final colors = ref.watch(themeColorsProvider);

    return Container(
      color: colors.bgColor,
      child: Scaffold(
        drawer: const AppSidebarDrawer(),
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              GradientHeader(
                onRefresh: () {
                  setState(() {
                    _refreshSignal++;
                  });
                },
              ),
              Expanded(
                child: StudentsListView(
                  refreshSignal: _refreshSignal,
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
