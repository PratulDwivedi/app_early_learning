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
  late final TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                searchController: _searchController,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StudentsListView(searchQuery: _searchQuery),
                      ],
                    ),
                  ),
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
