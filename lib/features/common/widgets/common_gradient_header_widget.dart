// lib/widgets/common_gradient_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/theme_provider.dart';

class CommonGradientHeader extends ConsumerWidget {
  final String title;
  final VoidCallback? onRefresh;
  final Widget? actionButton;
  
  const CommonGradientHeader({
    super.key,
    required this.title,
    this.onRefresh,
    this.actionButton,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.watch(primaryColorProvider);

    return Container(
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
      child: Stack(
        children: [
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
            bottom: -50,
            right: -100,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          if (actionButton != null) actionButton!,
                          if (onRefresh != null)
                            IconButton(
                              onPressed: onRefresh,
                              icon: const Icon(Icons.refresh, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.2),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
